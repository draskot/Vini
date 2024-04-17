# replace_chain_id.py
import sys

if len(sys.argv) != 4:
    print("Usage: python replace_chain_id.py <input_file> <output_file> <chain_id>")
    sys.exit(1)

input_file = sys.argv[1]
output_file = sys.argv[2]
chain_id = sys.argv[3]

with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
    for line in infile:
        outfile.write(line[:21] + chain_id + line[22:])

print("Text replacement completed. Output saved to", output_file)
