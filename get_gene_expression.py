# We have to setup COSMICDB_USER and COSMICDB_PASS environment variables

#GENE_NAME = "ERBB2"
#GENE_NAME = "EGFR"

import os
import base64
import sys
import requests
import csv

def getGeneExpressions(GENE_NAME, credentials, TOKEN_NUMBER, WORKING_DIR):
    try:
        download_url = ("https://cancer.sanger.ac.uk/cosmic-download/download/index?" +
                    "table=V92_37_COMPLETEGENEEXPRESSION" + "&"
                    "genename=" + GENE_NAME + "&"
                    "token=" + TOKEN_NUMBER)
        r = requests.get(download_url)
            
        if r.text:
            dirname = os.path.realpath('.')
            filename = os.path.join(dirname, WORKING_DIR, GENE_NAME + '_expressions.csv')    
            with open(filename, 'wb') as f:
                f.write(r.content)
    except ValueError as e:
        print e
        print ('Unsuccessful download of CSV expression file for gene %s' % GENE_NAME)


def getTissueSampleFeatures(TISSUE_NAME, credentials, TOKEN_NUMBER, WORKING_DIR):
    try:
        download_url = ("https://cancer.sanger.ac.uk/cosmic-download/download/index?" +
                    "table=V92_37_SAMPLE" + "&"
                    "primarysite=" + TISSUE_NAME + "&"
                    "token=" + TOKEN_NUMBER)
        r = requests.get(download_url)
            
        if r.text:
            dirname = os.path.realpath('.')
            filename = os.path.join(dirname, WORKING_DIR, TISSUE_NAME + '_samples.csv')    
            with open(filename, 'wb') as f:
                f.write(r.content)
    except:
        print ('Unsuccessful download of CSV sample features file for tissue %s' % TISSUE_NAME)


def filterGeneExpressionFile(WORKING_DIR, GENE_NAME, TISSUE_NAME):
    gene_expressions_file = os.path.join(WORKING_DIR, GENE_NAME + "_expressions.csv")
    tissue_samples_file = os.path.join(WORKING_DIR, TISSUE_NAME + "_samples.csv")
    gene_expression_filtered_file = GENE_NAME + "_expressions_filtered.csv"
#    try:
    count = 0
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
    WORKING_DIR = os.path.join('genes', 'expressions')

    getGeneExpressions(GENE_NAME, credentials, TOKEN_NUMBER, WORKING_DIR)
    getTissueSampleFeatures(TISSUE_NAME, credentials, TOKEN_NUMBER, WORKING_DIR)
    filterGeneExpressionFile(WORKING_DIR, GENE_NAME, TISSUE_NAME)
    # calculateGeneExpressionAverage(GENE_NAME + "_expressions.csv")
    

if __name__ == "__main__":
   main(sys.argv[1:])