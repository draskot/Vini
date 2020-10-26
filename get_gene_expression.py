# We have to setup COSMICDB_USER and COSMICDB_PASS environment variables

#GENE_NAME = "ERBB2"
#GENE_NAME = "EGFR"

# Your first request needs to supply your registered email address and COSMIC password. 
# CosmicDB uses HTTP Basic Auth to check your credentials, 
# which requires you to combine your email address and password and then Base64 encode them.

import os
import base64
import sys
print ("User: " + os.environ.get('COSMICDB_USER'))

GENE_NAME = sys.argv[1]

cosmicdb_user = os.environ.get('COSMICDB_USER')
cosmicdb_pass = os.environ.get('COSMICDB_PASS')
credentials = base64.b64encode(cosmicdb_user + ':' + cosmicdb_pass)
print ('credentials: ', credentials)

# Make a request to https://cancer.sanger.ac.uk/cosmic/file_download/ with authentication string (credentials)
import requests

#this token has to be manually obtained from https://cancer.sanger.ac.uk/cosmic/download
TOKEN_NUMBER = "93210280369111638364141311106994957"

###############################
# USING REQUESTS
###############################
try:
    download_url = ("https://cancer.sanger.ac.uk/cosmic-download/download/index?" +
                "table=V92_37_COMPLETEGENEEXPRESSION" + "&"
                "genename=" + GENE_NAME + "&"
                "token=" + TOKEN_NUMBER)
    r = requests.get(download_url)
      
    if r.text:
        dirname = os.path.dirname(__file__)
        filename = GENE_NAME + '_expressions.csv'
        with open(filename, 'wb') as f:
            f.write(r.content)
except:
    print ('Unsuccesful download of CSV expression file for gene %s' % GENE_NAME)

""" THIS IS IN CASE WE WANT TO DOWNLOAD WHOLE GENE EXPRESSION TABLE (~1.9GB)
# this downloads whole CSV file with all gene expressions
url = "https://cancer.sanger.ac.uk/cosmic/file_download/GRCh37/cosmic/v92/CosmicCompleteGeneExpression.tsv.gz"


payload = {}
headers = {"Content-type": "application/json",
           "Authorization": "Basic " + credentials}
response = requests.request("GET", url, headers=headers, data = payload)

# Request will return a snippet of JSON containing the link that we need to use to download your file.
try:
    download_url = response.json()['url']
    print (download_url)
except:
    print ("JSON couldn't be parsed")
try:
    # Downloading CSV file with expressions and saving it to GENE_NAME_expressions.csv file
    import wget
    dirname = os.path.dirname(__file__)
    filename = GENE_NAME + '_expressions.csv'
    wget.download(download_url, out = os.path.join(dirname, filename))
except:
    print ("Couldn't download CSV file")
"""

# Filter CSV file and get expression average(for now)
import csv
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

