# We have to setup COSMICDB_USER and COSMICDB_PASS environment variables

# TODO add support for FEB matrix integration
# TODO add while loop with number_of_attempts in getGeneExpression method

import os
import time
import sys
import requests
import getopt
import csv_splitter

t0 = time.time()
# this token has to be manually obtained from https://cancer.sanger.ac.uk/cosmic/download

TOKEN_NUMBER = "5255537552779015219645592933740952"
WORKING_DIR = os.path.join(os.path.realpath('.'), 'genes', 'expressions')

def mapUniprotIDtoCosmicID(UNIPROT_ID):
    try:
        print ("Mapping UniprotID to CosmicID")
        download_url = ("https://www.uniprot.org/uploadlists/?from=ACC+ID&to=GENENAME&format=tab&query=" +
                        UNIPROT_ID)
        r = requests.get(download_url)
        if r.status_code == 200:
            gene_name = r.content.split('\n')[1].split('\t')[1]
            print "CosmicID: % s" % gene_name
            return gene_name
    except:
        print ('Error while contacting Uniprot service')

def getGeneFileName(GENE_NAME):
    return os.path.join(WORKING_DIR, GENE_NAME + '_expressions.csv')


def getTissueFileName(TISSUE_NAME):
    return os.path.join(WORKING_DIR, TISSUE_NAME + '_samples.csv')


def countLinesCSV(filename):
    with open(filename) as f:
        row_count = sum(1 for line in f)
    return row_count


def getGeneExpressions(GENE_NAME, COSMIC_GENE_ID):
    try:
        # print ('Connecting to CosmicDB')
        download_url = ("https://cancer.sanger.ac.uk/cosmic-download/download/index?" +
                        "table=V92_37_COMPLETEGENEEXPRESSION" + "&"
                                                                "genename=" + COSMIC_GENE_ID + "&"
                                                                                          "token=" + TOKEN_NUMBER)
        print ('Downloading gene expressions from CosmicDB')
        r = requests.get(download_url)
        if r.text != "No data available." and r.status_code == 200:
            filename = getGeneFileName(GENE_NAME)
            with open(filename, 'wb') as f:
                f.write(r.content)
            return filename
        else:
            print ('Cosmic response: %s', (r.status_code))
            print "Unsuccessful download from CosmicDB for gene % s" % GENE_NAME
    except:
        return False


def getTissueSampleFeatures(TISSUE_NAME):
    try:
        print ('Connecting to CosmicDB')
        download_url = ("https://cancer.sanger.ac.uk/cosmic-download/download/index?" +
                        "table=V92_37_SAMPLE" + "&"
                                                "primarysite=" + TISSUE_NAME + "&"
                                                                               "token=" + TOKEN_NUMBER)
        print ('Downloading tissue samples from CosmicDB')
        r = requests.get(download_url)

        if r.text != "No data available." and r.status_code == 200:
            filename = getTissueFileName(TISSUE_NAME)
            with open(filename, 'wb') as f:
                f.write(r.content)
            return filename
    except:
        return False


def splitGeneExpressionCSV(GENE_NAME, nprocs):
    filename = getGeneFileName(GENE_NAME)
    ave, res = divmod(countLinesCSV(filename), int(nprocs))
    print 'Splitting file %s ' % filename
    csv_splitter.split(filehandler=open(filename), output_name_template=GENE_NAME + '_part_%s.csv',
                       output_path=WORKING_DIR, row_limit=ave)


def main(argv):
    try:
        opts, args = getopt.getopt(argv, "hg:t:n:", ["gene", "tissue=", "nproc="])
    except getopt.GetoptError:
        print 'Usage: -g <gene Uniprot ID or file path> -t <tissue name> -n <number of cores>'
        sys.exit()

    for opt, arg in opts:
        if opt == '-h':
            print '-g <gene Uniprot ID or file path> -t <tissue name>'
            sys.exit()
        elif opt in ("-g", "--gene"):
            GENE_INPUT = arg
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
        gene_list = []
        # checking if GENE_INPUT is list of multiple genes
        with open(GENE_INPUT, 'r') as genes_file:
            for gene_name in genes_file:
                gene_list.append(gene_name.rstrip())
    except:
        # if GENE_INPUT is not a list it must be a single gene name
        gene_list = [GENE_INPUT]

    # get CSV with gene expressions from CosmicDB
    for GENE_NAME in gene_list:
        try:
            COSMIC_GENE_ID = mapUniprotIDtoCosmicID(GENE_NAME)
            geneFile = getGeneExpressions(GENE_NAME, COSMIC_GENE_ID)
            if geneFile:
                print 'Gene expressions saved in file: %s' % geneFile
                # split CSV into N files (N number of CPU cores)
                splitGeneExpressionCSV(GENE_NAME, nprocs)
        except:
            print ("Unsuccessful download of gene %s expressions from CosmicDB." % GENE_NAME)


    # get CSV with tissue samples from CosmicDB
    try:
        tissueFile = getTissueSampleFeatures(TISSUE_NAME)
        if tissueFile:
            print 'All expressions for tissue saved in file: %s' % tissueFile
        else:
            print 'Unsuccessful download of %s tissue samples file.' % TISSUE_NAME
    except:
        print ("Unsuccessful download of tissue samples %s from CosmicDB." % TISSUE_NAME)


if __name__ == "__main__":
    main(sys.argv[1:])
    print('calculated in {:.3f} sec'.format(time.time() - t0))
