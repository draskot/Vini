# We have to setup COSMICDB_USER and COSMICDB_PASS environment variables

#GENE_NAME = "ERBB2"
#GENE_NAME = "EGFR"

# TODO define arguments and help. req: GENE_NAME, TISSUE_NAME, NPROCS
# TODO add Uniprot -> Atlas gene name conversion
# TODO add support for FEB matrix integration
import os
import time
import sys
import requests
import getopt
import csv_splitter

t0 = time.time()
# this token has to be manually obtained from https://cancer.sanger.ac.uk/cosmic/download
TOKEN_NUMBER = "93210280369111638364141311106994957"
WORKING_DIR = os.path.join(os.path.realpath('.'), 'genes', 'expressions')


def getGeneFileName(GENE_NAME):
    return os.path.join(WORKING_DIR, GENE_NAME + '_expressions.csv')

def getTissueFileName(TISSUE_NAME):
    return os.path.join(WORKING_DIR, TISSUE_NAME + '_samples.csv')

def countLinesCSV(filename):
    num_rows = 0
    for row in open(filename, 'rb'):
        num_rows += 1
    return num_rows

def getGeneExpressions(GENE_NAME):
    try:
        download_url = ("https://cancer.sanger.ac.uk/cosmic-download/download/index?" +
                    "table=V92_37_COMPLETEGENEEXPRESSION" + "&"
                    "genename=" + GENE_NAME + "&"
                    "token=" + TOKEN_NUMBER)
        r = requests.get(download_url)
            
        if r.text:
            filename = getGeneFileName(GENE_NAME)
            with open(filename, 'wb') as f:
                f.write(r.content)
            return filename
    except:
        print ('Unsuccessful download of CSV expression file for gene %s' % GENE_NAME)

def getTissueSampleFeatures(TISSUE_NAME):
    try:
        download_url = ("https://cancer.sanger.ac.uk/cosmic-download/download/index?" +
                    "table=V92_37_SAMPLE" + "&"
                    "primarysite=" + TISSUE_NAME + "&"
                    "token=" + TOKEN_NUMBER)
        r = requests.get(download_url)
            
        if r.text:
            filename = getTissueFileName(TISSUE_NAME)
            with open(filename, 'wb') as f:
                f.write(r.content)
    except:
        print ('Unsuccessful download of CSV sample features file for tissue %s' % TISSUE_NAME)

def splitGeneExpressionCSV(GENE_NAME, nprocs):
    filename = getGeneFileName(GENE_NAME)
    ave, res = divmod(countLinesCSV(filename), int(nprocs))
    csv_splitter.split(filehandler=open(filename), output_path=WORKING_DIR, row_limit=ave)


def main(argv):
    try:
        opts, args = getopt.getopt(argv, "hg:t:n:", ["gene", "tissue=", "nproc="])
    except getopt.GetoptError:
        print '-g <gene name> -t <tissue name> -n <number of cores>'
        sys.exit()
    for opt, arg in opts:
        if opt == '-h':
            print '-g <gene name> -t <tissue name>'
            sys.exit()
        elif opt in ("-g", "--gene"):
            GENE_NAME = arg
        elif opt in ("-t", "--tissue"):
            TISSUE_NAME = arg
        elif opt in ("-n", "--nproc"):
            nprocs = arg

    try:
        cosmicdb_user = os.environ.get('COSMICDB_USER')
        cosmicdb_pass = os.environ.get('COSMICDB_PASS')
    except:
        print "No environment variables COSMICDB_USER and/or COSMICDB_PASS"
    
    # get CSV with gene expressions from CosmicDB
    getGeneExpressions(GENE_NAME)
    # get CSV with tissue samples from CosmicDB
    getTissueSampleFeatures(TISSUE_NAME)
    # split CSV into N files (N number of CPU cores)
    splitGeneExpressionCSV(GENE_NAME, nprocs)


if __name__ == "__main__":
    main(sys.argv[1:])
    print('calculated in {:.3f} sec'.format(time.time() - t0))