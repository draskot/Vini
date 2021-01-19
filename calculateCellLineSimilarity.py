import os
import time
import sys
import csv
import pandas as pd
import get_gene_expression_parallel as ggxp
import generateMutatedFASTAseq as tools


t0 = time.time()

#uniprot_id = ggxp.mapUniprotIDtoCosmicID()
cell_lines = ['MDA-MB-231', 'MDA-MB-436', 'MDA-MB-468']
for cell_line in cell_lines:
    #for gene in cell_line:
    #ggxp.main(['-g', './genes/uniprot_entries_small.txt', '-t', cell_line,'-n', '1'])
    ggxp.getTissueSampleFeatures(cell_line)


#tissue_samples_file = os.path.join(WORKING_DIR, TISSUE_NAME + "_samples.csv")
#df = pd.read_csv(tissue_samples_file, sep=',', header=0, usecols=['SAMPLE_ID'])


print('calculated in {:.3f} sec'.format(time.time() - t0))