# We have to setup COSMICDB_USER and COSMICDB_PASS environment variables

#GENE_NAME = "ERBB2"
#GENE_NAME = "EGFR"

# TODO define arguments and help. req: GENE_NAME, TISSUE_NAME, NPROCS
# TODO add Uniprot -> Atlas gene name conversion
# TODO add support for FEB matrix integration
import os
import time
import base64
import sys
import requests
import csv
from mpi4py import MPI
import numpy as np
import csv_splitter

t0 = time.time()
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

def getGeneExpressions(GENE_NAME, TOKEN_NUMBER):
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
        print e
        print ('Unsuccessful download of CSV expression file for gene %s' % GENE_NAME)

def getTissueSampleFeatures(TISSUE_NAME, TOKEN_NUMBER):
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
        GENE_NAME = sys.argv[1]
    except:
        print "Missing gene name argument"
        sys.exit()
    
    try:
        TISSUE_NAME = sys.argv[2]
    except:
        print "Missing tissue name argument"
        sys.exit()

    try:
        nprocs = sys.argv[3]
    except:
        print "Missing number of procs argument"
        sys.exit()

    try:
        cosmicdb_user = os.environ.get('COSMICDB_USER')
        cosmicdb_pass = os.environ.get('COSMICDB_PASS')
    except:
        print "No environment variables COSMICDB_USER and/or COSMICDB_PASS"
    
    # Your first request needs to supply your registered email address and COSMIC password. 
    # CosmicDB uses HTTP Basic Auth to check your credentials, 
    # which requires you to combine your email address and password and then Base64 encode them.
    credentials = base64.b64encode(cosmicdb_user + ':' + cosmicdb_pass)
    print ('credentials: ', credentials)

    # Make a request to https://cancer.sanger.ac.uk/cosmic/file_download/ with authentication string (credentials)
    # this token has to be manually obtained from https://cancer.sanger.ac.uk/cosmic/download
    TOKEN_NUMBER = "93210280369111638364141311106994957"

    # get CSV with gene expressions from CosmicDB
    getGeneExpressions(GENE_NAME, credentials, TOKEN_NUMBER)
    # get CSV with tissue samples from CosmicDB
    getTissueSampleFeatures(TISSUE_NAME, credentials, TOKEN_NUMBER)
    # split CSV into N files (N number of CPU cores)
    splitGeneExpressionCSV(GENE_NAME, nprocs)
    # filter gene expressions from CSV for only selected tissue samples on N cores
    ##filterGeneExpressionFile(WORKING_DIR, GENE_NAME, TISSUE_NAME)
    # calculateGeneExpressionAverage(GENE_NAME + "_expressions.csv")
    

if __name__ == "__main__":
    main(sys.argv[1:])
    print('calculated in {:.3f} sec'.format(time.time() - t0))