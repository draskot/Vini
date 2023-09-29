

import numpy as np
from scipy.stats import kstest, norm

# Read data from the 'vec' file into a NumPy array
with open('vec.tmp', 'r') as file:
    data = np.array([float(line.strip()) for line in file])

# Perform the Kolmogorov-Smirnov test against a normal distribution
ks_statistic, ks_p_value = kstest(data, 'norm')

# Set a significance level (alpha)
alpha = 0.05

# Determine if the data is normally distributed
is_normal = ks_p_value > alpha

# Write the result to the 'dist' file
with open('dist', 'w') as output_file:
    output_file.write('TRUE' if is_normal else 'FALSE')

print('Is the data normally distributed?', 'TRUE' if is_normal else 'FALSE')

