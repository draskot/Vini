def remove_redundant_lines(input_file, output_file):
    unique_lines = set()

    with open(input_file, 'r') as infile:
        with open(output_file, 'w') as outfile:
            for line in infile:
                value = line.split()[-1]
                if value not in unique_lines:
                    outfile.write(line)
                    unique_lines.add(value)

if __name__ == "__main__":
    import sys

    if len(sys.argv) != 3:
        print("Usage: python script.py input_file output_file")
        sys.exit(1)

    input_file_arg, output_file_arg = sys.argv[1], sys.argv[2]
    remove_redundant_lines(input_file_arg, output_file_arg)

