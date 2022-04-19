import random
import sys
import argparse
import numpy


lower_bound = float(sys.argv[1])
upper_bound = float(sys.argv[2])
random_affinity = numpy.random.normal(lower_bound, upper_bound)


log = open("random_normal", "w")
log.write("%5.7f\n" % (random_affinity))
log.close()
