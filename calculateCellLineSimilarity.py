import os
import time
import sys
import csv
import pandas as pd
import cosmicTools
import sklearn.decomposition
import scipy


t0 = time.time()
WORKING_DIR = os.path.join(os.path.realpath('.'), 'genes', 'expressions')
cell_lines = ['MDA-MB-231', 'MDA-MB-436', 'MDA-MB-468']





def loadDF():
    dataframes = []
    for cell_line in cell_lines:
        expressions_file = os.path.join(WORKING_DIR, cell_line + '.csv')
        with open(expressions_file, 'r') as f:
            next(f)
            reader = csv.reader(f, skipinitialspace=True)
            genes_dict = dict((row[2], row[4]) for row in reader)
            #print genes_dict
            df = pd.DataFrame(index=[cell_line], data=genes_dict)
            dataframes.append(df)
            #print df


    all_df = pd.concat(dataframes)
    #print all_df
    return all_df, dataframes




def main(argv):
    cl_df, dataframes = loadDF()
    #cl_df = cl_df.T

    # matrica euklidskih udaljenosti -> trazimo onaj par koji ima NAJVECU euklidsku udaljenost
    ary = scipy.spatial.distance.cdist(cl_df.iloc[:, :], cl_df.iloc[:, :], metric='euclidean')
    dff = pd.DataFrame(ary, index= cell_lines, columns=cell_lines)
    dff.to_csv(os.path.join(WORKING_DIR, 'cell_line_differences.csv'))
    print dff


if __name__ == "__main__":
    main(sys.argv[1:])
    print('calculated in {:.3f} sec'.format(time.time() - t0))