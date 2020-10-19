from __future__ import print_function
import numpy as np
import argparse

parse = argparse.ArgumentParser()
parse.add_argument("-s")
parse.add_argument("-t")
args = parse.parse_args()

temp_buf = open(args.s)
K = np.loadtxt(temp_buf)
#K = np.loadtxt(temp_buf, dtype=object)
temp_buf.close()

E=np.linalg.eigvals(K) #compute eigenvalues
E_sorted=sorted(E)     #sort eigenvalues

log = open(args.t, "w")       
print(E_sorted, file = log)
log.close()
