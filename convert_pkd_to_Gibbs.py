import math
import os

working_directory = os.getcwd()

full_path_name = working_directory + '/tmp'


R=1.98720425864083         #gas constant [calories / Kelvin*mol]
T=298                      #temperature [Kelvin]

log = open(full_path_name, "r")
pkd = log.read()
log.close()

DG = ( -math.log(10 ** float(pkd)) * R * T) / 1000.0 #binding energy Vina [kcal / mol]


log = open(full_path_name, "w")


log.write("%5.9f\n" % (DG))
log.close()
