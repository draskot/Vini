# THIS IS IN CASE WE WANT TO DOWNLOAD WHOLE GENE EXPRESSION TABLE (~1.9GB)
# this downloads whole CSV file with all gene expressions
import requests
import os
url = "https://cancer.sanger.ac.uk/cosmic/file_download/GRCh37/cosmic/v92/CosmicCompleteGeneExpression.tsv.gz"
cosmicdb_user = os.environ.get('COSMICDB_USER')
cosmicdb_pass = os.environ.get('COSMICDB_PASS')
credentials = base64.b64encode(cosmicdb_user + ':' + cosmicdb_pass)
print ('credentials: ', credentials)


GENE_NAME = sys.argv[1]

url = "https://cancer.sanger.ac.uk/cosmic/file_download/GRCh38/cosmic/v92/CosmicSample.tsv.gz"
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
