#from __future__ import print_function
import numpy as np
import sys
import os

log = open("temp_buf", "r")
eigenvalue = log.read()
log.close()

i = float(eigenvalue)
a=abs(i) 

log = open("temp_buf", "w")
log.write("%5.2f\n" % (a))
log.close()
