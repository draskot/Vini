import sys

# Check if the correct number of command-line arguments is provided
if len(sys.argv) != 2:
    print("Usage: python script.py <file_path>")
    sys.exit(1)

# Get the file path from the command-line arguments
file_path = sys.argv[1]

# Read the lines from the specified text file
try:
    with open(file_path, 'r') as file:
        lines = file.readlines()
except FileNotFoundError:
    print(f"File not found: {file_path}")
    sys.exit(1)

# Split each line into drug combinations and the numeric value
data = [line.strip().split() for line in lines]

# Sort the data based on the last numeric value in each line
sorted_data = sorted(data, key=lambda x: float(x[-1]), reverse=True)

# Find the maximum lengths of drug combinations and numeric values
max_len_combinations = max(len('.'.join(line[:-1])) for line in sorted_data)
max_len_numeric = max(len(line[-1]) for line in sorted_data)

# Print the sorted data with fixed-width formatting
for line in sorted_data:
    combination_str = '.'.join(line[:-1]).ljust(max_len_combinations)
    numeric_str = line[-1].rjust(max_len_numeric)
    print(f"{combination_str} {numeric_str}")

