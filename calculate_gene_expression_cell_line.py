import os
import time
import sys
import csv
import getopt
import pandas as pd
import cosmicTools


t0 = time.time()
WORKING_DIR = os.path.join(os.path.realpath('.'), 'genes', 'expressions')

def filterGeneExpression (WORKING_DIR, cell_line_name, genes_list):
    cosmicTools.mapUniprotIDToCosmicID('P17252')
    print "genes_list: ", genes_list
    gene_list_cosmic_uniprot_dict = dict((cosmicTools.mapCosmicIDToUniprotID(gene), gene) for gene in genes_list)
    # load CSV with expressions
    expressions_file = os.path.join(WORKING_DIR, cell_line_name + '.csv')
    df = pd.read_csv(expressions_file, sep=',', header=0, usecols=[' GENE_NAME', ' Z_SCORE'])
    # filter out rows where '_ENST' in gene name
    #df = df[~df[' GENE_NAME'].str.contains('_ENS', regex=False)]
    df = df[df[' GENE_NAME'].isin(gene_list_cosmic_uniprot_dict.keys())]
    print df[' GENE_NAME']
    #df = df[df[' GENE_NAME'].isin(genes_list)]
    print df
    df = df.drop_duplicates()
    # mapping list of gene UNIPROT IDs to Cosmic IDs
    df[' GENE_NAME'] = df[' GENE_NAME'].apply(lambda name: gene_list_cosmic_uniprot_dict[name])
    print('df sorted: \n{}'.format(df))
    return df




def main(argv):
    try:
        opts, args = getopt.getopt(argv, "hg:t:o:", ["gene", "tissue="])
    except getopt.GetoptError:
        print ('-g <gene Uniprot ID or file path> -t <tissue name> -o <output file>')
        sys.exit()
    for opt, arg in opts:
        if opt == '-h':
            print ('-g <gene Uniprot ID or file path> -t <tissue name> -o <output file>')
            sys.exit()
        elif opt in ("-g", "--gene"):
            GENE_NAME = arg
        elif opt in ("-t", "--tissue"):
            TISSUE_NAME = arg
        elif opt in ("-o", "--output"):
            OUTPUT_FILE = arg

    genes_list = cosmicTools.makeGeneListFromInput(GENE_NAME)
    #cell_lines = ['MDA-MB-231', 'MDA-MB-436', 'MDA-MB-468']
    cell_lines = [TISSUE_NAME]
    for cell_line in cell_lines:
            expressions = filterGeneExpression(WORKING_DIR, cell_line, genes_list)
            expressions.to_csv(os.path.join(WORKING_DIR, 'expression_score_' + cell_line + '.csv'), header = False,
                               columns=[' GENE_NAME', ' Z_SCORE'], index = False)
            """""
            with open(OUTPUT_FILE, 'a+') as output_file:
                writer = csv.writer(output_file, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
                for expression in expressions:
                    #writer.writerow([GENE_NAME, average_zscore])
                    writer.writerow(expression)
            """
if __name__ == "__main__":
    main(sys.argv[1:])
    print('calculated in {:.3f} sec'.format(time.time() - t0))
