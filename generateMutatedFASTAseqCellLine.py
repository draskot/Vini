import os
import time
import sys
import getopt
import pandas as pd
import cosmicTools

t0 = time.time()
WORKING_DIR_MUTATIONS = os.path.join(os.path.realpath('.'), 'genes', 'mutations')
WORKING_DIR_SEQUENCES = os.path.join(os.path.realpath('.'), 'genes', 'sequences')

def filterMutationsForGeneList(filename, genes_list):
    genes_list_cosmicIDs = [cosmicTools.mapUniprotIDtoCosmicID(gene) for gene in genes_list]
    # mutations_samples_file = os.path.join(WORKING_DIR_MUTATIONS, GENE_NAME + "_mutations.csv")
    mutation_samples_file = os.path.join(WORKING_DIR_MUTATIONS, filename)
    df = pd.read_csv(mutation_samples_file, sep=',', header=0, usecols=['GENE_NAME', ' MUTATION_CDS', ' MUTATION_DESCRIPTION'])
    # cleaning data
    df = df[df[' MUTATION_CDS'] != 'c.?']
    df = df[df[' MUTATION_DESCRIPTION'] != 'Unknown']
    df = df[~df['GENE_NAME'].str.contains('_ENS', regex=False)]

    df = df[df['GENE_NAME'].isin({'GENE_NAME':genes_list})]
    df1 = pd.DataFrame({'GENE_NAME': genes_list_cosmicIDs})
    #df = df[df['GENE_NAME'].isin(df1['GENE_NAME'])]


    # TODO add uvjet da izbacuje duplikate istog GENE_NAME i MUTATION_CDS
    df = df.drop_duplicates()
    print('df sorted: \n{}'.format(df))
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

    # there should be only single file in working dir if working with cell lines
    for mutation_file in os.listdir(WORKING_DIR_MUTATIONS):
        #try:
        CELL_LINE_NAME = mutation_file.split('.')[0].split('_')[0]
        mutations = filterMutationsForGeneList(mutation_file, genes_list)
        new_sequence = cosmicTools.applyMutationsToFASTA(mutations, os.path.join(WORKING_DIR_SEQUENCES, GENE_NAME + '_sequence.csv'))
        cosmicTools.saveSequenceToFASTA(GENE_NAME, new_sequence, WORKING_DIR_SEQUENCES)
        #except ValueError as e:
         #   print "Unsuccessful applying of FASTA mutations for file %s" % mutation_file


if __name__ == "__main__":
    main(sys.argv[1:])
