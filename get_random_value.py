import random
import sys

def update_values(input_file_path):
    with open(input_file_path, 'r') as input_file:
        lines = input_file.readlines()
        dataset = [float(line.strip()) if line.strip() and line.strip() != 'ERROR' else None for line in lines]

    # Filter out None values before computing min and max
    filtered_dataset = [value for value in dataset if value is not None]

    # Check if the dataset is not empty
    if filtered_dataset:
        # Find the minimum and maximum values in the dataset
        min_value = min(filtered_dataset)
        max_value = max(filtered_dataset)

        # Generate a random value within the computed range
        random_value = random.uniform(min_value, max_value)

        # Replace missing values (None) with the random value
        dataset = [random_value if value is None else value for value in dataset]

        # Write the updated dataset back to the input file
        with open(input_file_path, 'w') as output_file:
            for value in dataset:
                if value is not None:
                    output_file.write(str(value) + '\n')
                else:
                    output_file.write('ERROR\n')

        print(f"Random value within the range ({min_value}, {max_value}): {random_value}")
    else:
        print("Dataset is empty.")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <input_file_path>")
        sys.exit(1)

    input_file_path_arg = sys.argv[1]
    update_values(input_file_path_arg)

