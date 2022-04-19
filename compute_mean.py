
#input param: vec
#output param: descending sort of eigenvalue magnitudes

from __future__ import print_function
import numpy
import argparse

parse = argparse.ArgumentParser()
parse.add_argument("-s")
parse.add_argument("-t")
args = parse.parse_args()

temp_buf = open(args.s)
vec = numpy.loadtxt(temp_buf)
temp_buf.close()

E=numpy.mean(vec)                        #compute mean value

log = open(args.t, "w")       
print(E, file = log)
log.close()


#An example of matrix with complex eigenvalues

# 1 -1
# 1  1
