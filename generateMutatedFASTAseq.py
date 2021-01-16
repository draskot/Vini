# TODO - sort expressions by appearance and filter only top 10
# TODO - CSV headers are prefixed with space -> remove that space
import os
import time
import sys
import getopt
import pandas as pd
import csv

t0 = time.time()
WORKING_DIR_MUTATIONS = os.path.join(os.path.realpath('.'), 'genes', 'mutations')
WORKING_DIR_SEQUENCES = os.path.join(os.path.realpath('.'), 'genes', 'sequences')

# this method applies mutations from CSVs to wild type FASTA sequence
def filterMutations(filename):
    # mutations_samples_file = os.path.join(WORKING_DIR_MUTATIONS, GENE_NAME + "_mutations.csv")
    mutation_samples_file = os.path.join(WORKING_DIR_MUTATIONS, filename)
    print mutation_samples_file
    df = pd.read_csv(mutation_samples_file, sep=',', header=0, usecols=[' MUTATION_CDS', ' MUTATION_DESCRIPTION'])
    # cleaning data
    df = df[df[' MUTATION_CDS'] != 'c.?']
    df = df[df[' MUTATION_DESCRIPTION'] != 'Unknown']
    # adding count column with frequency of occurrences
    df['count'] = df.groupby(' MUTATION_CDS')[' MUTATION_CDS'].transform(pd.Series.value_counts)
    # removing duplicates after counting
    df = df.drop_duplicates()
    # sorting it by count column
    df = df.sort_values('count', ascending=False)
    # filtering only top N results
    df = df.head(10)
    #print('df sorted: \n{}'.format(df))
    return df

def applyMutationsToFASTA(mutations, FASTAfile):
    # (later) extract only FASTA sequence from CSV and save it as .FASTA file
    # open .FASTA file and load sequence to memory
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
        range = mutation.split("_")
        start = range[0]
        finish = range[0] if len(range) == 1 else range[1]
        del sequence[int(start):int(finish)+1]
        print mutation
    # save FASTA sequence from memory to .FASTA file
    return ''.join(sequence)

def saveSequenceToFASTA(GENE_NAME, sequence):
    try:
        with open(os.path.join(WORKING_DIR_SEQUENCES, GENE_NAME + '.fasta'), 'w') as fasta_file:
            fasta_file.write(sequence)
    except:
        print "Unsuccessful writing to FASTA file"

def main(argv):
    try:
        opts, args = getopt.getopt(argv, "hg:o:", ["gene"])
    except getopt.GetoptError:
        print ('-g <gene Uniprot ID or file path> -o <output file>')
        sys.exit()
    for opt, arg in opts:
        if opt == '-h':
            print ('-g <gene Uniprot ID or file path> -t <tissue name> -o <output file>')
            sys.exit()
        elif opt in ("-g", "--gene"):
            GENE_NAME = arg
        elif opt in ("-o", "--output"):
            OUTPUT_FILE = arg

    for mutation_file in os.listdir(WORKING_DIR_MUTATIONS):
        try:
            GENE_NAME = mutation_file.split('.')[0].split('_')[0]
            mutations = filterMutations(mutation_file)
            new_sequence = applyMutationsToFASTA(mutations, os.path.join(WORKING_DIR_SEQUENCES, GENE_NAME + '_sequence.csv'))
            saveSequenceToFASTA(GENE_NAME, new_sequence)
        except ValueError as e:
            print "Unsuccessful applying of FASTA mutations for file %s" % mutation_file


if __name__ == "__main__":
    main(sys.argv[1:])
