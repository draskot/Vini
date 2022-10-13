import os, time, sys
import pandas as pd
import numpy as np

t0 = time.time()

def main(argv):
    try:
        WORKDIR = os.environ['WORKDIR']
    except KeyError:
        print("WORKDIR environmental variable is not set")
        exit()

    try:
        with open(os.path.join(WORKDIR, 'target_dir'), 'r') as f:
            target_dir = f.read()
            TARGETDIR = os.path.join(target_dir.strip("\n"))
    except:
        print("Can't open file with target directory")
        exit()

    with open(os.path.join(WORKDIR, 'complexes'), 'r') as f:
        dim = f.read().strip("\n")

    with open(os.path.join(WORKDIR, 'therapy_level'), 'r') as f:
        therapy_level = f.read().strip("\n")

    try:
        os.remove(os.path.join(WORKDIR, 'temp_buf'))
    except OSError:
        print("No temp_buf to remove")

    # Loading files into DataFrames
    receptors_contracted_df = pd.read_csv(os.path.join(WORKDIR, 'receptors_contracted'), sep=' ', header=None)
    relations_df = pd.read_csv(os.path.join(WORKDIR, 'relations'), sep=' ', header=None)
    affinity_values = pd.read_csv(os.path.join(TARGETDIR, 'vec'), header=None)

    # Initializing energy binding matrix (dim x dim)
    main.EB_matrix = pd.DataFrame(np.zeros((int(dim), int(dim)), dtype=object))

    # Filling EB matrix diagonal with affinity values
    np.fill_diagonal(main.EB_matrix.values, affinity_values)

    if therapy_level == "1":
        # Adding expression values for off-diagonal elements
        result = [applyToEB(relation, receptors_contracted_df)
                  for relation in relations_df.iloc[:, :].to_numpy()]
    print(os.path.join(TARGETDIR, 'EB_matrix'))
    main.EB_matrix.to_csv(os.path.join(TARGETDIR, 'EB_matrix'), sep=" ", header=False, index=False)


def applyToEB(relation, receptors_contracted_df):
    source_id = relation[0]
    target_id = relation[1]
    genex = relation[3]
    #global EB_matrix
    rc = receptors_contracted_df
    source_positions = rc[rc.iloc[:, 0] == source_id].index.to_numpy()
    target_positions = rc[rc.iloc[:, 0] == target_id].index.to_numpy()
    # sve kombinacije elemenata iz jednog i drugog skupa
    for sp in source_positions:
        for tp in target_positions:
            main.EB_matrix.iloc[sp, tp] = genex

if __name__ == "__main__":
    main(sys.argv[1:])
    print('calculated in {:.3f} sec'.format(time.time() - t0))
