import os
import time
import sys
import csv
import getopt
from mpi4py import MPI
import pandas as pd


t0 = time.time()
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
nprocs = comm.Get_size()
WORKING_DIR = os.path.join(os.path.realpath('.'), 'genes', 'expressions')

def filterGeneExpressionFile (GENE_NAME, TISSUE_NAME, data):
    tissue_samples_file = os.path.join(WORKING_DIR, TISSUE_NAME + "_samples.csv")
    gene_expression_filtered_file = GENE_NAME + "_expressions_filtered.csv"
    df = pd.read_csv(tissue_samples_file, sep=',', header=0, usecols=['SAMPLE_ID'])

    count = 0
    expressionSum= 0
    for row_gene in data[1:]:  # ignore first line, it is CSV header
        GENE_SAMPLE = int(row_gene[0])
        result = df[df["SAMPLE_ID"] == GENE_SAMPLE]
        if not result.empty:
            #print ("Process {}: ".format(rank), row_gene)
            count += 1
            expressionSum += float(row_gene[4])
    return count, expressionSum


def main(argv):
    try:
        opts, args = getopt.getopt(argv, "hg:t:o:", ["gene", "tissue="])
    except getopt.GetoptError:
        print '-g <gene Uniprot ID or file path> -t <tissue name> -o <output file>'
        sys.exit()
    for opt, arg in opts:
        if opt == '-h':
            print '-g <gene Uniprot ID or file path> -t <tissue name> -o <output file>'
            sys.exit()
        elif opt in ("-g", "--gene"):
            GENE_NAME = arg
        elif opt in ("-t", "--tissue"):
            TISSUE_NAME = arg
        elif opt in ("-o", "--output"):
            OUTPUT_FILE = arg


    # filter gene expressions from CSV parts for only selected tissue samples on N cores
    if rank == 0:
        data = []
        try:
            for i in range(1, nprocs + 1):
                csv_file = os.path.join(WORKING_DIR, GENE_NAME + '_part_{}.csv'.format(i))
                reader = csv.reader(open(csv_file), delimiter=",")
                data.append([row for row in reader])
        except:
            print "Z-score calculation for %s failed." % GENE_NAME
    else:
        data = None

    data = comm.scatter(data, root=0)
    expression_count, zscore_sum = filterGeneExpressionFile(GENE_NAME, TISSUE_NAME, data)
    expression_count= comm.gather(expression_count, root=0)
    zscore_sum = comm.gather(zscore_sum, root=0)

    if rank == 0:
        try:
            average_zscore = sum(zscore_sum)/sum(expression_count)
            print GENE_NAME
            print('count number is {}'.format(sum(expression_count)))
            print('Z-score average is {}'.format(average_zscore))
            print('calculated in {:.3f} sec'.format(time.time() - t0))
            with open(OUTPUT_FILE, 'a+') as output_file:
                writer = csv.writer(output_file, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
                writer.writerow([GENE_NAME, average_zscore])
            return average_zscore
        except:
            print "Error writing expression scores to CSV"
            sys.exit()


if __name__ == "__main__":
    main(sys.argv[1:])