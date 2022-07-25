import os
import time
import sys
import getopt
import pandas as pd
import cosmicTools
import csv

t0 = time.time()
WORKING_DIR_MUTATIONS = os.path.join(os.path.realpath('.'), 'genes', 'mutations')
WORKING_DIR_SEQUENCES = os.path.join(os.path.realpath('.'), 'genes', 'sequences')

def filterMutations(filename, genes_list):
    gene_list_cosmic_uniprot_dict = dict((cosmicTools.mapUniprotIDToCosmicID(gene), gene) for gene in genes_list)
    mutation_samples_file = os.path.join(WORKING_DIR_MUTATIONS, filename)
    df = pd.read_csv(mutation_samples_file, sep=',', header=0, usecols=['GENE_NAME', ' ACCESSION_NUMBER',
                                                                        ' MUTATION_CDS', ' MUTATION_DESCRIPTION'])
    # cleaning data
    df = df[df[' MUTATION_CDS'] != 'c.?']
    df = df[df[' MUTATION_DESCRIPTION'] != 'Unknown']
    df = df[~df['GENE_NAME'].str.contains('_ENS', regex=False)]
    df = df[df['GENE_NAME'].isin(gene_list_cosmic_uniprot_dict.keys())]
    # TODO add uvjet da izbacuje duplikate istog GENE_NAME i MUTATION_CDS, tj. po  ACCESSION_NUMBER
    df = df.drop_duplicates()
    # mapping list of gene UNIPROT IDs to Cosmic IDs
    df['GENE_NAME'] = df['GENE_NAME'].apply(lambda name: gene_list_cosmic_uniprot_dict[name])
    #print('df sorted: \n{}'.format(df))
    return df


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
            # this can be single gene name or path to file with list of genes
            GENE_NAME = arg
        elif opt in ("-o", "--output"):
            OUTPUT_FILE = arg

    genes_list = cosmicTools.makeGeneListFromInput(GENE_NAME)

    mutation_file = os.listdir(WORKING_DIR_MUTATIONS)[0] # there should be only single file in working dir if working with cell lines
    mutations_df = filterMutations(mutation_file, genes_list)
    print mutations_df
    for gene in genes_list:
        mutations = mutations_df[mutations_df['GENE_NAME'] == gene]
        if not mutations.empty:
            sequence_filename = os.path.join(WORKING_DIR_SEQUENCES, gene + '_sequence.csv')
            new_sequence = cosmicTools.applyMutationsToFASTA(mutations=mutations, FASTAfile=os.path.join(WORKING_DIR_SEQUENCES,sequence_filename))
            cosmicTools.saveSequenceToFASTA(gene, new_sequence, WORKING_DIR_SEQUENCES)



if __name__ == "__main__":
    main(sys.argv[1:]) 
