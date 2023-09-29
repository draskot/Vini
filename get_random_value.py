import random

# Read the dataset from the "vec" file and compute min and max values
with open('vec', 'r') as input_file:
    lines = input_file.readlines()
    dataset = [float(line.strip()) if line.strip() != 'ERROR' else None for line in lines]

# Find the minimum and maximum values in the dataset
min_value = min(value for value in dataset if value is not None)
max_value = max(value for value in dataset if value is not None)

# Generate a random value within the computed range
random_value = random.uniform(min_value, max_value)

# Replace missing values (None) with the random value
dataset = [random_value if value is None else value for value in dataset]

# Write the updated dataset to the "vec" file
with open('vec', 'w') as output_file:
    for value in dataset:
        if value is not None:
            output_file.write(str(value) + '\n')
        else:
            output_file.write('ERROR\n')

print(f"Random value within the range ({min_value}, {max_value}): {random_value}")

