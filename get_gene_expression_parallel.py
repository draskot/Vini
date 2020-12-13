# We have to setup COSMICDB_USER and COSMICDB_PASS environment variables
# TODO add support gene list in file
# TODO output file za expression average
# TODO kakve logove treba ispisivati? debug mode?

# TODO add Uniprot -> Atlas gene name conversion - napraviti u uredu, tamo je Postman request
# TODO add support for FEB matrix integration


import os
import time
import sys
import requests
import getopt
import csv_splitter
import mapUniprotIDtoCosmic

t0 = time.time()
# this token has to be manually obtained from https://cancer.sanger.ac.uk/cosmic/download
TOKEN_NUMBER = "98330950869072126039566353130973932"
WORKING_DIR = os.path.join(os.path.realpath('.'), 'genes', 'expressions')

def mapUniprotIDtoCosmicID(UNIPROT_ID):
    try:
        print ("Mapping UniprotID to CosmicID")
        download_url = ("https://www.uniprot.org/uploadlists/?from=ACC+ID&to=GENENAME&format=tab&query=" +
                        UNIPROT_ID)
        r = requests.get(download_url)
        if r.status_code == 200:
            gene_name = r.content.split('\n')[1].split('\t')[1]
            print ("r.text: ", r.text)
            print ("CosmicID: ", gene_name)
            return gene_name
    except:
        print ('Error while contacting Uniprot service')

def getGeneFileName(GENE_NAME):
    return os.path.join(WORKING_DIR, GENE_NAME + '_expressions.csv')


def getTissueFileName(TISSUE_NAME):
    return os.path.join(WORKING_DIR, TISSUE_NAME + '_samples.csv')


def countLinesCSV(filename):
    num_rows = 0
    for row in open(filename, 'rb'):
        num_rows += 1
    return num_rows


def getGeneExpressions(GENE_NAME, COSMIC_GENE_ID):
    try:
        print ('Connecting to CosmicDB')
        download_url = ("https://cancer.sanger.ac.uk/cosmic-download/download/index?" +
                        "table=V92_37_COMPLETEGENEEXPRESSION" + "&"
                                                                "genename=" + COSMIC_GENE_ID + "&"
                                                                                          "token=" + TOKEN_NUMBER)
        print ('Downloading gene expressions from CosmicDB')
        r = requests.get(download_url)
        print ('Cosmic response: %s', (r.status_code))
        if r.text and r.status_code == 200:
            filename = getGeneFileName(GENE_NAME)
            with open(filename, 'wb') as f:
                f.write(r.content)
            return filename
    except:
        print ('Unsuccessful download of CSV expression file for gene %s' % GENE_NAME)


def getTissueSampleFeatures(TISSUE_NAME):
    try:
        print ('Connecting to CosmicDB')
        download_url = ("https://cancer.sanger.ac.uk/cosmic-download/download/index?" +
                        "table=V92_37_SAMPLE" + "&"
                                                "primarysite=" + TISSUE_NAME + "&"
                                                                               "token=" + TOKEN_NUMBER)
        print ('Downloading tissue samples from CosmicDB')
        r = requests.get(download_url)

        if r.text and r.status_code == 200:
            filename = getTissueFileName(TISSUE_NAME)
            with open(filename, 'wb') as f:
                f.write(r.content)
            return filename
    except:
        print ('Unsuccessful download of CSV sample features file for tissue %s' % TISSUE_NAME)


def splitGeneExpressionCSV(GENE_NAME, nprocs):
    filename = getGeneFileName(GENE_NAME)
    ave, res = divmod(countLinesCSV(filename), int(nprocs))
    csv_splitter.split(filehandler=open(filename), output_name_template=GENE_NAME + '_part_%s.csv',
                       output_path=WORKING_DIR, row_limit=ave)


def main(argv):
    try:
        opts, args = getopt.getopt(argv, "hg:t:n:", ["gene", "tissue=", "nproc="])
    except getopt.GetoptError:
        print '-g <gene Uniprot ID> -t <tissue name> -n <number of cores>'
        sys.exit()

    for opt, arg in opts:
        if opt == '-h':
            print '-g <gene Uniprot ID> -t <tissue name>'
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

    try:
        COSMIC_GENE_ID = mapUniprotIDtoCosmicID(GENE_NAME)
    except:
        print ("Unsuccessful mapping of UniprotID->CosmicID ")


    # get CSV with gene expressions from CosmicDB
    geneFile = getGeneExpressions(GENE_NAME, COSMIC_GENE_ID)
    if geneFile:
        print 'Gene expressions saved in file: %s' % geneFile
    # get CSV with tissue samples from CosmicDB
    tissueFile = getTissueSampleFeatures(TISSUE_NAME)
    if tissueFile:
        print 'All expressions for tissue saved in file: %s' % tissueFile
    # split CSV into N files (N number of CPU cores)
    splitGeneExpressionCSV(GENE_NAME, nprocs)


if __name__ == "__main__":
    main(sys.argv[1:])
    print('calculated in {:.3f} sec'.format(time.time() - t0))
