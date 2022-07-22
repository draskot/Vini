import os
import time
import sys
import getopt
import pandas as pd
import csv
import cosmicTools
import requests

t0 = time.time()
# this token has to be manually obtained from https://cancer.sanger.ac.uk/cosmic/download

TOKEN_NUMBER = "319418856489730369567850320964831609"
WORKING_DIR_MUTATIONS = os.path.join(os.path.realpath('.'), 'genes', 'mutations')
WORKING_DIR_SEQUENCES = os.path.join(os.path.realpath('.'), 'genes', 'sequences')

if not os.path.exists(WORKING_DIR_MUTATIONS):
    os.makedirs(WORKING_DIR_MUTATIONS)
if not os.path.exists(WORKING_DIR_SEQUENCES):
    os.makedirs(WORKING_DIR_SEQUENCES)

failed_downloads = []


def getCellLineMutations(CELL_LINE):
    try:
        # print ('Connecting to CosmicDB')
        download_url = ("https://cancer.sanger.ac.uk/cosmic-download/download/index?" +
                        "table=V92_38_MUTANT" + "&samplename=" + CELL_LINE + "&token=" + TOKEN_NUMBER)
        number_of_attempts = 10
        current_attempt = 0
        print ('Downloading gene mutations for cell line %s' % CELL_LINE)
        while current_attempt < number_of_attempts:
            current_attempt += 1
            #print ("Attempt %s/%s" % (current_attempt, number_of_attempts))
            r = requests.get(download_url)
            if r.text != "No data available." and r.status_code == 200:
                filename = cosmicTools.getMutationFileName(CELL_LINE, WORKING_DIR_MUTATIONS)
                print filename
                with open(filename, 'wb') as f:
                    f.write(r.content)
                return filename
            elif r.status_code == 401:
                # trying again, Cosmic sometimes randomly responds with 401 Unauthorized
                #print "Unsuccessful download of mutations from CosmicDB for cell line % s" % CELL_LINE
                time.sleep(3)
            else:
                print ("No mutation for cell line under such name in CosmicDB: %s" % CELL_LINE)
                global failed_downloads
                failed_downloads.append("%s" % CELL_LINE)
                return False
        print "Unsuccessful download of mutations for cell line %s" % CELL_LINE
    except:
        return False


def getFASTAseq(GENE_NAME, COSMIC_GENE_ID):
    try:
        # print ('Connecting to CosmicDB')
        download_url = ("https://cancer.sanger.ac.uk/cosmic-download/download/index?" +
                        "table=V92_38_ALLGENES" + "&" + "genename=" + COSMIC_GENE_ID + "&" + "token=" + TOKEN_NUMBER)
        number_of_attempts = 10
        current_attempt = 0
        print ('Downloading FASTA sequence from CosmicDB for gene %s' % GENE_NAME)
        while current_attempt < number_of_attempts:
            current_attempt += 1
            #print ("Attempt %s/%s" % (current_attempt, number_of_attempts))
            r = requests.get(download_url)
            #print ('Cosmic response: %s', (r.status_code))
            if r.text != "No data available." and r.status_code == 200:
                filename = cosmicTools.getSequenceFileName(GENE_NAME, WORKING_DIR_SEQUENCES)
                with open(filename, 'wb') as f:
                    f.write(r.content)
                return filename
            elif r.status_code == 401:
                # trying again, Cosmic sometimes randomly responds with 401 Unauthorized
                #print "Unsuccessful download of FASTA sequence from CosmicDB for gene % s" % GENE_NAME
                time.sleep(3)
            else:
                print ("No FASTA for gene under such name in CosmicDB: %s" % GENE_NAME)
                global failed_downloads
                failed_downloads.append("%s-%s" % (GENE_NAME, COSMIC_GENE_ID))
                return False
        print "Unsuccessful download of FASTA sequence from CosmicDB for gene % s" % GENE_NAME
    except:
        return False

def main(argv):
    try:
        opts, args = getopt.getopt(argv, "hg:t:c:", ["gene", "tissue=",'cellline'])
    except getopt.GetoptError:
        print 'Usage: -g <gene Uniprot ID or file path> -c <cell line>'
        sys.exit()

    for opt, arg in opts:
        if opt == '-h':
            print '-g <gene Uniprot ID or file path> -t <tissue name>'
            print '-g <gene Uniprot ID or file path>'
            sys.exit()
        elif opt in ("-g", "--gene"):
            GENE_INPUT = arg
        elif opt in ("-t", "--tissue"):
            TISSUE_NAME = arg
        elif opt in ("-c", "--cellline"):
            CELL_LINE = arg

    # checking for Cosmic credentials
    cosmicTools.checkCosmicEnvironment()
    gene_list = cosmicTools.makeGeneListFromInput(GENE_INPUT)
    try:
        mutationsFile = getCellLineMutations(CELL_LINE)
        if mutationsFile:
            print 'Gene mutations saved in file: %s' % mutationsFile
    except:
        print "Unable to download gene mutations for %s cell line."

    # get CSV with wild type FASTA sequence from CosmicDB
    num_successful_downloads = 0
    for GENE_NAME in gene_list:
        try:
            COSMIC_GENE_ID = cosmicTools.mapUniprotIDtoCosmicID(GENE_NAME)
            fastaSeq = getFASTAseq(GENE_NAME, COSMIC_GENE_ID)
            if fastaSeq:
                num_successful_downloads += 1
                print 'FASTA sequence saved in file: %s' % fastaSeq
        except:
            pass
    print ("Downloaded %s of %s FASTA sequences from list." % (num_successful_downloads, len(gene_list)))
    if failed_downloads:
        print ("These genes/cell-lines were not downloaded: %s" % ','.join(failed_downloads))


if __name__ == "__main__":
    main(sys.argv[1:])
    print('calculated in {:.3f} sec'.format(time.time() - t0))
