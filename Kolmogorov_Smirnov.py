
#input param: EB_matrix
#output params: statistic, pvalue 

from __future__ import print_function
from scipy.stats import kstest

import numpy as np
import argparse

from numpy.random import seed
from numpy.random import poisson

parse = argparse.ArgumentParser()
parse.add_argument("-s")
parse.add_argument("-t")
args = parse.parse_args()

temp_buf = open(args.s)
K = np.loadtxt(temp_buf)
temp_buf.close()

#E=np.linalg.eigvals(K)                        #compute eigenvalues
#res = list(map(abs, E))
#E_sorted=sorted(res, key=abs, reverse=True)     #sort eigenvalues by magnitude

#perform Kolmogorov-Smirnov test
data = poisson(5, 100)
kstest(data, 'norm')

log = open(args.t, "w")       
#print(E_sorted, file = log)
log.close()


#An example of matrix with complex eigenvalues

# 1 -1
# 1  1
