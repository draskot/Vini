
#input param: EB_matrix
#output param: descending sort of eigenvalue magnitudes

from __future__ import print_function
import numpy as np
import argparse

parse = argparse.ArgumentParser()
parse.add_argument("-s")
parse.add_argument("-t")
args = parse.parse_args()

temp_buf = open(args.s)
K = np.loadtxt(temp_buf)
temp_buf.close()

E=np.linalg.eigvals(K)                        #compute eigenvalues
res = list(map(abs, E))
E_sorted=sorted(res, key=abs, reverse=True)     #sort eigenvalues by magnitude

log = open(args.t, "w")       
print(E_sorted, file = log)
log.close()


#An example of matrix with complex eigenvalues

# 1 -1
# 1  1
