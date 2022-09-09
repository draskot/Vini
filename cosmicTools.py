import os
import csv_splitter
import requests
import time
import csv
from time import sleep

TOKEN_NUMBER = "386905211228622145060114729181006819"
WORKING_DIR = os.path.join(os.path.realpath('.'), 'genes')

def mapUniprotIDToCosmicID(UNIPROT_ID):
    dict_path = os.path.join(WORKING_DIR, 'cosmic_ids.csv')
    if not os.path.exists(dict_path):
        with open(dict_path, 'a+') as dict_csv:
            writer = csv.writer(dict_csv)
            writer.writerow(["UNIPROT_ID", "COSMIC_ID"])


    with open(dict_path, "a+") as f:
        csv_reader = csv.reader(f)
        # Iterate over each row in the csv using reader object
        next(f)  # Skip the header
        reader = csv.reader(f, skipinitialspace=True)
        id_dict = dict(reader)
        #try:
        url_submit_job = "https://rest.uniprot.org/idmapping/run?from=UniProtKB_AC-ID&to=Gene_Name&ids=%s" % (UNIPROT_ID)
        response = requests.request("POST", url_submit_job, headers={}, data={})
        response = response.json()
        job_id = response["jobId"]
        def check_status(job_id):
            url_fetch_status = "https://rest.uniprot.org/idmapping/status/%s" % (job_id)
            response = requests.request("GET", url_fetch_status, headers={}, data={})
            return response
        response = check_status(job_id)
        response_payload = response.json()
        while "jobStatus" in response_payload.keys():
            sleep (0.5)
            print "Checking ID mapping job status for ", UNIPROT_ID
            response = check_status(job_id)
            response_payload = response.json()

        if response.status_code == 200:
            COSMIC_ID =  response_payload["results"][0]["to"]
            print "Mapped UniprotID %s to CosmicID: % s" % (UNIPROT_ID, COSMIC_ID)
            writer = csv.writer(f)
            writer.writerow([UNIPROT_ID, COSMIC_ID])
            return COSMIC_ID
        #except:
        #    print ('Error while contacting Uniprot mapping service')
        #    return False

def mapCosmicIDToUniprotID(COSMIC_ID):
    dict_path = os.path.join(WORKING_DIR, 'cosmic_ids.csv')
    if not os.path.exists(dict_path):
        with open(dict_path, 'a+') as dict_csv:
            writer = csv.writer(dict_csv)
            writer.writerow(["COSMIC_ID", "UNIPROT_ID"])


    with open(dict_path, "a+") as f:
        csv_reader = csv.reader(f)
        # Iterate over each row in the csv using reader object
        next(f)  # Skip the header
        reader = csv.reader(f, skipinitialspace=True)
        id_dict = dict(reader)
        try:
            url_submit_job = "https://rest.uniprot.org/idmapping/run?from=UniProtKB_AC-ID&to=Gene_Name&ids=%s" % (COSMIC_ID)
            response = requests.request("POST", url_submit_job, headers={}, data={})
            response = response.json()
            job_id = response["jobId"]
            def check_status(job_id):
                url_fetch_status = "https://rest.uniprot.org/idmapping/status/%s" % (job_id)
                response = requests.request("GET", url_fetch_status, headers={}, data={})
                return response
            response = check_status(job_id)
            response_payload = response.json()
            while "jobStatus" in response_payload.keys():
                sleep (0.5)
                print "Checking ID mapping job status for ", COSMIC_ID
                response = check_status(job_id)
                response_payload = response.json()

            if response.status_code == 200:
                UNIPROT_ID =  response_payload["results"][0]["to"]
                print "Mapped Uniprot ID %s to Cosmic ID: % s" % (COSMIC_ID, UNIPROT_ID)
                writer = csv.writer(f)
                writer.writerow([COSMIC_ID, UNIPROT_ID])
                return UNIPROT_ID
        except:
            print ('Error while contacting Uniprot mapping service')
            return False


def getMutationFileName(GENE_NAME, WORKING_DIR):
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
        print "Can't open file with list of genes."
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
        file_path = os.path.join(WORKING_DIR, GENE_NAME + '_mutated.fasta')
        print file_path
        with open(file_path, 'w') as fasta_file:
            fasta_file.write(sequence)
            print "Mutated sequence saved to %s" %file_path
            return True
    except:
        print "Unsuccessful saving of FASTA file for gene %s" % GENE_NAME
        return False


def applyMutationsToFASTA(mutations, FASTAfile):
    # mutations are expected as pandas dataframe output
    try:
        print "FASTAfile: ", FASTAfile
        with open(FASTAfile) as csvfile:
            reader = csv.reader(csvfile, delimiter='\n')
            header = next(reader)
            sequence = list(next(reader)[0])
    except:
        print "Can't open file with FASTA sequence"
        return False
    # saving deletions for last
    deletions = []
    # iterate through mutations and apply it to FASTA sequence
    for mutation in mutations[' MUTATION_CDS']:
        mutation = mutation.split('.')[1]
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
                print "Mutation applied: %s" % mutation
            else:
                print "No nucleotide match on given index. Expected %s but received %s" \
                      % (nucleotide_before, sequence[nucleotide_index])
    for mutation in deletions:
        try:
            range = mutation.split("_")
            start = range[0]
            finish = range[0] if len(range) == 1 else range[1]
            del sequence[int(start):int(finish)+1]
            print "Mutation applied: %s" % mutation
        except:
            # mutation format is probably not as expected
            pass
    return ''.join(sequence)
