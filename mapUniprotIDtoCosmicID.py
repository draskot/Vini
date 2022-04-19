import os
import sys
import requests

def mapUniprotIDtoCosmicID(Uniprot_ID):
    try:
        download_url = ("https://www.uniprot.org/uploadlists/?from=ACC+ID&to=GENENAME&format=tab&query=" + Uniprot_ID)
        r = requests.get(download_url)
        if r.status_code == 200:
            gene_name = r.content.split('\n')[1].split('\t')[1]
            print gene_name
    except:
        print ('Error')

Uniprot_ID = str(sys.argv[1])

gene_name = mapUniprotIDtoCosmicID(Uniprot_ID)
