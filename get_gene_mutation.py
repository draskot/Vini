# We have to setup COSMICDB_USER and COSMICDB_PASS environment variables

# TODO - TOKEN_NUMBER should be in separate file or env variable so this script and get_gene_expression_parallel.py
#  can both access it from same place
# TODO create working directory if it doesn't exist alread
# TODO enforce input of command line arguments before execution, ATM user is not alerted when tissue or gene arg is omitted

import os
import time
import sys
import requests
import getopt


t0 = time.time()
# this token has to be manually obtained from https://cancer.sanger.ac.uk/cosmic/download

TOKEN_NUMBER = "235665226794822137803070575988673649"
WORKING_DIR_MUTATIONS = os.path.join(os.path.realpath('.'), 'genes', 'mutations')
WORKING_DIR_SEQUENCES = os.path.join(os.path.realpath('.'), 'genes', 'sequences')

failed_downloads = []

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

def getMutationsFileName(GENE_NAME):
    return os.path.join(WORKING_DIR_MUTATIONS, GENE_NAME + '_mutations.csv')

def getSequenceFileName(GENE_NAME):
    return os.path.join(WORKING_DIR_SEQUENCES, GENE_NAME + '_sequence.csv')



def countLinesCSV(filename):
    with open(filename) as f:
        row_count = sum(1 for line in f)
    return row_count


def getGeneMutations(GENE_NAME, COSMIC_GENE_ID, TISSUE_NAME):
    try:
        # print ('Connecting to CosmicDB')
        download_url = ("https://cancer.sanger.ac.uk/cosmic-download/download/index?" +
                        "table=V92_38_MUTANT" + "&" + "primarysite=" + TISSUE_NAME + "&" +
                                                                "genename=" + COSMIC_GENE_ID + "&"
                                                                                          "token=" + TOKEN_NUMBER)
        number_of_attempts = 10
        current_attempt = 0
        while current_attempt < number_of_attempts:
            current_attempt += 1
            print ("Attempt %s/%s" % (current_attempt, number_of_attempts))
            print ('Downloading gene mutations from CosmicDB')
            r = requests.get(download_url)
            print ('Cosmic response: %s', (r.status_code))
            if r.text != "No data available." and r.status_code == 200:
                filename = getMutationsFileName(GENE_NAME)
                with open(filename, 'wb') as f:
                    f.write(r.content)
                return filename
            elif r.status_code == 401:
                # trying again, Cosmic sometimes randomly responds with 401 Unauthorized
                print "Unsuccessful download of mutations from CosmicDB for gene % s" % GENE_NAME
                time.sleep(3)
            else:
                print ("No mutation for gene under such name in CosmicDB: %s" % GENE_NAME)
                global failed_downloads
                failed_downloads.append("%s-%s" % (GENE_NAME, COSMIC_GENE_ID))
                return False

    except:
        return False

def getFASTAseq(GENE_NAME, COSMIC_GENE_ID):
    try:
        # print ('Connecting to CosmicDB')
        download_url = ("https://cancer.sanger.ac.uk/cosmic-download/download/index?" +
                        "table=V92_38_ALLGENES" + "&" + "genename=" + COSMIC_GENE_ID + "&" + "token=" + TOKEN_NUMBER)
        number_of_attempts = 10
        current_attempt = 0
        while current_attempt < number_of_attempts:
            current_attempt += 1
            print ("Attempt %s/%s" % (current_attempt, number_of_attempts))
            print ('Downloading FASTA sequence from CosmicDB')
            r = requests.get(download_url)
            print ('Cosmic response: %s', (r.status_code))
            if r.text != "No data available." and r.status_code == 200:
                filename = getSequenceFileName(GENE_NAME)
                with open(filename, 'wb') as f:
                    f.write(r.content)
                return filename
            elif r.status_code == 401:
                # trying again, Cosmic sometimes randomly responds with 401 Unauthorized
                print "Unsuccessful download of FASTA sequence from CosmicDB for gene % s" % GENE_NAME
                time.sleep(3)
            else:
                print ("No FASTA for gene under such name in CosmicDB: %s" % GENE_NAME)
                global failed_downloads
                failed_downloads.append("%s-%s" % (GENE_NAME, COSMIC_GENE_ID))
                return False

    except:
        return False

def main(argv):
    try:
        opts, args = getopt.getopt(argv, "hg:t:", ["gene", "tissue="])
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

    # get CSV with gene mutations from CosmicDB
    num_successful_downloads = 0
    for GENE_NAME in gene_list:
        try:
            COSMIC_GENE_ID = mapUniprotIDtoCosmicID(GENE_NAME)
            geneFile = getGeneMutations(GENE_NAME, COSMIC_GENE_ID, TISSUE_NAME)
            if geneFile:
                print 'Gene mutations saved in file: %s' % geneFile
                num_successful_downloads += 1
            fastaSeq = getFASTAseq(GENE_NAME, COSMIC_GENE_ID)
            if fastaSeq:
                print 'FASTA sequence saved in file: %s' % fastaSeq
        except:
            pass
    print ("Downloaded %s of %s gene mutations from list." % (num_successful_downloads, len(gene_list)))
    if failed_downloads:
        print ("These genes were not downloaded: %s" % ','.join(failed_downloads))


if __name__ == "__main__":
    main(sys.argv[1:])
    print('calculated in {:.3f} sec'.format(time.time() - t0))
