import random
import sys
import argparse


lower_bound = float(sys.argv[1])
upper_bound = float(sys.argv[2])
random_affinity = random.uniform(lower_bound, upper_bound)


log = open("random_affinity", "w")
log.write("%5.7f\n" % (random_affinity))
log.close()
