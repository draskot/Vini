import os
import math

working_directory = os.getcwd()

full_path_name = working_directory + '/tmp'

log = open(full_path_name, "r")
value = log.read()
log.close()

i = float(value)
a=abs(i)

log = open(full_path_name, "w")
log.write("%5.9f\n" % (a))
log.close()
