# TODO add number of CPU cores as argument
# TODO preimenovati csv_splitter output kako bi moglo vise procesa za razlicite gene raditi ovo isto - npr. erbb2_part1.csv
import os
import time
import sys
import csv
from mpi4py import MPI
from get_gene_expression_parallel import countLinesCSV

t0 = time.time()
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
nprocs = comm.Get_size()
WORKING_DIR = os.path.join(os.path.realpath('.'), 'genes', 'expressions')

def filterGeneExpressionFile (GENE_NAME, TISSUE_NAME, data):
    tissue_samples_file = os.path.join(WORKING_DIR, TISSUE_NAME + "_samples.csv")
    gene_expression_filtered_file = GENE_NAME + "_expressions_filtered.csv"
    count = 0
    for row_gene in data[1:]:  # ignore first line, it is CSV header
        with open(tissue_samples_file, 'rb') as csv_tissue_samples:
            for row_tissue in csv.DictReader(csv_tissue_samples, delimiter=','):
                if row_gene[0] == row_tissue['SAMPLE_ID']:
                    print ("Process {}: ".format(rank), row_gene)
                    count = count + 1
    return count


def calculateGeneExpressionAverage(filename):
    # Filter CSV file and get expression average(for now)
    print ('\n Starting CSV filtering')
    sum = 0
    count = 0
    try:
        with open(filename, 'rb') as csvfile:
            for line in csv.DictReader(csvfile, delimiter=','):
                sum = sum + float(line[' Z_SCORE'])
                count = count + 1

        average_expression = sum / count
        print ("average: ", average_expression)
    except:
        print ('Couldn\'t calculate average expression for gene %s' % GENE_NAME)


def main(argv):
    try:
        GENE_NAME = sys.argv[1]
    except:
        print "Missing gene name argument"
        sys.exit()

    try:
        TISSUE_NAME = sys.argv[2]
    except:
        print "Missing tissue name argument"
        sys.exit()

    # filter gene expressions from CSV parts for only selected tissue samples on N cores
    if rank == 0:
        data = []
        for i in range(1, nprocs + 1):
            f = []
            csv_file = os.path.join(WORKING_DIR, 'output_{}.csv'.format(i))
            reader = csv.reader(open(csv_file), delimiter=",")
            f = []
            for row in reader:
                f.append(row)
            data.append(f)
    else:
        data = None
    data = comm.scatter(data, root=0)
    expression_count = filterGeneExpressionFile(GENE_NAME, TISSUE_NAME, data)
    expression_count = comm.gather(expression_count, root=0)
    # calculateGeneExpressionAverage(GENE_NAME + "_expressions.csv")

    if rank == 0:
        print('count number is {}'.format(sum(expression_count)))
        print('calculated in {:.3f} sec'.format(time.time() - t0))

if __name__ == "__main__":
    main(sys.argv[1:])