# We have to setup COSMICDB_USER and COSMICDB_PASS environment variables

#GENE_NAME = "ERBB2"
#GENE_NAME = "EGFR"

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
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
nprocs = comm.Get_size()
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

def getGeneExpressions(GENE_NAME, credentials, TOKEN_NUMBER):
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

def getTissueSampleFeatures(TISSUE_NAME, credentials, TOKEN_NUMBER):
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

def splitGeneExpressionCSV(GENE_NAME):
    filename = getGeneFileName(GENE_NAME)
    ave, res = divmod(countLinesCSV(filename), nprocs)
    csv_splitter.split(filehandler=open(filename), output_path=WORKING_DIR, row_limit=ave)

def filterGeneExpressionFile(WORKING_DIR, GENE_NAME, TISSUE_NAME):
    gene_expressions_file = os.path.join(WORKING_DIR, GENE_NAME + "_expressions.csv")
    tissue_samples_file = os.path.join(WORKING_DIR, TISSUE_NAME + "_samples.csv")
    gene_expression_filtered_file = GENE_NAME + "_expressions_filtered.csv"
#    try:
    count = 0
    #########################
    ##### PARALLELIZING #####
    #########################
    num_rows = countLinesCSV(gene_expressions_file,)

    with open(gene_expressions_file, 'rb') as csv_gene_expressions:
        for row_gene in csv.DictReader(csv_gene_expressions, delimiter=','):
            with open(tissue_samples_file, 'rb') as csv_tissue_samples:
                for row_tissue in csv.DictReader(csv_tissue_samples, delimiter=','):
                    if row_gene['SAMPLE_ID'] == row_tissue['SAMPLE_ID']:
                        count = count + 1
                        print row_gene
    print "Count %s" % count

def calculateGeneExpressionAverage(filename):
    # Filter CSV file and get expression average(for now)
    print ('\n Starting CSV filtering')
    sum = 0
    count = 0
    try:
        with open(filename, 'rb') as csvfile:
            for line in csv.DictReader(csvfile, delimiter=','):
                sum = sum + float(line[' Z_SCORE'])
                count = count + 1

        average_expression = sum / count
        print ("average: ", average_expression)
    except:
        print ('Couldn\'t calculate average expression for gene %s' % GENE_NAME)

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
    # split CSV into N files (N number of CPU cores)
    splitGeneExpressionCSV(GENE_NAME)
    # get CSV with tissue samples from CosmicDB
    getTissueSampleFeatures(TISSUE_NAME, credentials, TOKEN_NUMBER)
    # filter gene expressions from CSV for only selected tissue samples on N cores
    ##filterGeneExpressionFile(WORKING_DIR, GENE_NAME, TISSUE_NAME)
    # calculateGeneExpressionAverage(GENE_NAME + "_expressions.csv")
    

if __name__ == "__main__":
    # TODO add number of CPU cores as argument
    main(sys.argv[1:])
    print('calculated in {:.3f} sec'.format(time.time() - t0))