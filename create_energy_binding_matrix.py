import os
import pandas as pd
import numpy as np

try:
    WORKDIR = os.environ['WORKDIR']
except KeyError:
    print "WORKDIR environmental variable is not set"
    exit()

try:
    with open(os.path.join(WORKDIR, 'target_dir'), 'r') as f:
        target_dir = f.read()
        TARGETDIR = os.path.join(target_dir)
except:
    print "Can't open file with target directory"
    exit()

with open(os.path.join(WORKDIR, 'nr_complexes'), 'r') as f:
    dim = f.read()

with open(os.path.join(WORKDIR, 'therapy_level'), 'r') as f:
    therapy_level = f.read()

try:
    os.remove(os.path.join(WORKDIR, 'temp_buf'))
except OSError:
    print "No temp_buf to remove"


def applyToEB(relation):
    source = relation[0]
    target = relation[1]
    genex = relation[3]
    global EB_matrix
    print relation
    EB_matrix.iloc[[source], [target]] = genex


# Loading files into DataFrames
receptors_contracted_df = pd.read_csv(os.path.join(WORKDIR, 'receptors_contracted'), sep=' ', header=None)
relations_df = pd.read_csv(os.path.join(WORKDIR, 'relations'), sep=' ', header=None)
affinity_values = pd.read_csv(os.path.join(target_dir, 'vec'), header=None)
vec_df = pd.read_csv(os.path.join(WORKDIR, 'vec'), header=None)


#receptor_ids_df = receptors_contracted_df.iloc[:, 1].apply(lambda x: x.strip('hsa:'))
receptor_ids_df = receptors_contracted_df.iloc[:, 0]
# Initializing energy binding matrix (dim x dim)
# EB_matrix = pd.DataFrame(np.zeros((len(affinity_values), len(affinity_values)), float))
print dim
EB_matrix = pd.DataFrame(np.zeros(int(dim), int(dim), float))
# Filling EB matrix diagonal with affinity values
np.fill_diagonal(EB_matrix.values, affinity_values)

if therapy_level == 1:
    relations_df.apply()

result = [applyToEB(row) for row in relations_df.iloc[:,:].to_numpy()]





#print EB_matrix
