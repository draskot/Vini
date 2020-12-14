import os
import time
import sys
import getopt

import subprocess


t0 = time.time()
WORKING_DIR = os.path.join(os.path.realpath('.'), 'genes', 'expressions/')

def main(argv):
    try:
        opts, args = getopt.getopt(argv, "hg:t:o:n:", ["gene", "tissue="])
    except getopt.GetoptError:
        print '-g <gene list file> -t <tissue name> -o <output file path> -c <number of cores>'
        sys.exit()
    for opt, arg in opts:
        if opt == '-h':
            print '-g <gene list file> -t <tissue name> -o <output file path> -c <number of cores>'
            sys.exit()
        elif opt in ("-g", "--gene"):
            GENE_LIST = arg
        elif opt in ("-t", "--tissue"):
            TISSUE_NAME = arg
        elif opt in ("-o", "--output"):
            OUTPUT_FILE = arg
        elif opt in ("-n", "--cores"):
            N_CORES = arg

    with open(GENE_LIST, 'r') as f:
        genes = [gene.rstrip() for gene in f]

    gene_count = 0
    if not os.path.isfile(WORKING_DIR + TISSUE_NAME + '_samples.csv'):
        print "No %s tissue samples file." % TISSUE_NAME
        return False

    for gene in genes:
        if os.path.isfile(WORKING_DIR + gene + '_expressions.csv'):
            t1 = time.time()
            print "Calculating Z-score for gene: %s" % gene
            command = "mpiexec -n " + N_CORES \
                      + " python calculate_gene_expression.py -g " + gene \
                      + " -t " + TISSUE_NAME + " -o " + OUTPUT_FILE
            try:
                process = subprocess.Popen(command.split(), stdout=subprocess.PIPE)
                output, error = process.communicate()
                # print error
                gene_count += 1
                print('calculated in {:.3f} sec'.format(time.time() - t1))
            except ValueError:
                print "Unsuccessful calculation of expression for %s" % gene
                sys.exit()
        else:
            print "No expression data for gene %s" % gene

    print "Calculated %s out of %s genes." % (gene_count, len(genes))
    print('calculated in {:.3f} sec'.format(time.time() - t0))
if __name__ == "__main__":
    main(sys.argv[1:])