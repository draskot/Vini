import os
import csv_splitter
import requests
import time
import csv

TOKEN_NUMBER = "822239706399298093099245485975646525"

def mapUniprotIDtoCosmicID(UNIPROT_ID):
    try:
        download_url = ("https://www.uniprot.org/uploadlists/?from=ACC+ID&to=GENENAME&format=tab&query=" +
                        UNIPROT_ID)
        r = requests.get(download_url)
        if r.status_code == 200:
            gene_name = r.content.split('\n')[1].split('\t')[1]
            print "Mapped Uniprot ID %s to CosmicID: % s" % (UNIPROT_ID, gene_name)
            return gene_name
    except:
        print ('Error while contacting Uniprot service')


def getMutationsFileName(GENE_NAME, WORKING_DIR):
    return os.path.join(WORKING_DIR, GENE_NAME + '_mutations.csv')

def getSequenceFileName(GENE_NAME, WORKING_DIR):
    return os.path.join(WORKING_DIR, GENE_NAME + '_sequence.csv')


def getGeneExpressionFileName(GENE_NAME, WORKING_DIR):
    return os.path.join(WORKING_DIR, GENE_NAME + '_expressions.csv')


def getTissueExpressionFileName(TISSUE_NAME, WORKING_DIR):
    return os.path.join(WORKING_DIR, TISSUE_NAME + '_samples.csv')

def countLinesCSV(filename):
    with open(filename) as f:
        row_count = sum(1 for line in f)
    return row_count


def splitGeneExpressionCSV(GENE_NAME, nprocs, WORKING_DIR):
    filename = getGeneExpressionFileName(GENE_NAME, WORKING_DIR)
    ave, res = divmod(countLinesCSV(filename), int(nprocs))
    print 'Splitting file %s ' % filename
    csv_splitter.split(filehandler=open(filename), output_name_template=GENE_NAME + '_part_%s.csv',
                       output_path=WORKING_DIR, row_limit=ave)

def checkCosmicEnvironment():
    try:
        cosmicdb_user = os.environ.get('COSMICDB_USER')
        cosmicdb_pass = os.environ.get('COSMICDB_PASS')
        return cosmicdb_user, cosmicdb_pass
    except:
        print "No environment variables COSMICDB_USER and/or COSMICDB_PASS"

def makeGeneListFromInput(GENE_INPUT):
    try:
        gene_list = []
        # checking if GENE_INPUT is list of multiple genes
        with open(GENE_INPUT, 'r') as genes_file:
            for gene_name in genes_file:
                gene_list.append(gene_name.rstrip())
        return gene_list
    except:
        # if GENE_INPUT is not a list it must be a single gene name
        gene_list = [GENE_INPUT]
        return gene_list


# TODO universal method for downloading data from Cosmic
def getDataFromCosmic(GENE_NAME, COSMIC_GENE_ID, URL_TEMPLATE, filename):
    try:
        # print ('Connecting to CosmicDB')
        download_url = ("https://cancer.sanger.ac.uk/cosmic-download/download/index?" +
                        "table=V92_38_ALLGENES" + "&" + "genename=" + COSMIC_GENE_ID + "&" + "token=" + TOKEN_NUMBER)
        number_of_attempts = 10
        current_attempt = 0
        while current_attempt < number_of_attempts:
            current_attempt += 1
            print ("Attempt %s/%s" % (current_attempt, number_of_attempts))
            print ('Downloading data from CosmicDB')
            r = requests.get(download_url)
            print ('Cosmic response: %s', (r.status_code))
            if r.text != "No data available." and r.status_code == 200:
                with open(filename, 'wb') as f:
                    f.write(r.content)
                return filename
            elif r.status_code == 401:
                # trying again, Cosmic sometimes randomly responds with 401 Unauthorized
                print "Unsuccessful download of data from CosmicDB for gene % s" % GENE_NAME
                time.sleep(3)
            else:
                print ("No data for gene under such name in CosmicDB: %s" % GENE_NAME)
                return False
    except:
        return False


def saveSequenceToFASTA(GENE_NAME, sequence, WORKING_DIR):
    try:
        with open(os.path.join(WORKING_DIR, GENE_NAME + '.fasta'), 'w') as fasta_file:
            fasta_file.write(sequence)
            return True
    except:
        print "Unsuccessful saving of FASTA file for gene %" % GENE_NAME
        return False


def applyMutationsToFASTA(mutations, FASTAfile):
    # mutations are expected as pandas dataframe output
    with open(FASTAfile) as csvfile:
        reader = csv.reader(csvfile, delimiter='\n')
        header = next(reader)
        sequence = list(next(reader)[0])
    # saving deletions for last
    deletions = []
    # iterate through mutations and apply it to FASTA sequence
    for mutation in mutations[' MUTATION_CDS']:
        mutation = mutation.split('.')[1]
        # print "mutation %s" % mutation
        if 'dup' in mutation:
            print mutation
        elif 'ins' in mutation:
            print mutation
        elif 'del' in mutation:
            deletions.append(mutation.replace('del', ''))
        else:
            # only covering substitution case here
            nucleotide_index = int(mutation.split('>')[0][0:-1]) - 1
            nucleotide_before = mutation.split('>')[0][-1].lower()
            nucleotide_after = mutation.split('>')[1].lower()
            # applying mutation to sequence
            if sequence[nucleotide_index] == nucleotide_before:
                sequence[nucleotide_index] = nucleotide_after
            else:
                print "No nucleotide match on given index. Expected %s but received %s" \
                      % (nucleotide_before, sequence[nucleotide_index])
    for mutation in deletions:
        try:
            range = mutation.split("_")
            start = range[0]
            finish = range[0] if len(range) == 1 else range[1]
            del sequence[int(start):int(finish)+1]
            print mutation
        except:
            # mutation format is probably not as expected
            pass
    # save FASTA sequence from memory to .FASTA file
    return ''.join(sequence)