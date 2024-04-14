#!/usr/bin/env python
import sys

def update_pdb(last_order_number, infile, outfile):
    with open(infile, "r") as input_file, open(outfile, "w") as output_file:
        for line in input_file:
            if line.startswith("ATOM") or line.startswith("HETATM"):
                atom_data = line[11:30]  # Adjusted to include the correct atom order number column
                x, y, z = line[30:38], line[38:46], line[46:54]
                rest_of_line = line[54:]
                order_number = int(line[6:11]) + last_order_number
                new_line = f"{line[:6]}{order_number:5d}{atom_data}{x:8}{y:8}{z:8}{rest_of_line}"
                output_file.write(new_line)
            else:
                output_file.write(line)

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python update_pdb.py last_order_number infile outfile")
        sys.exit(1)

    last_order_number = int(sys.argv[1])
    infile = sys.argv[2]
    outfile = sys.argv[3]

    update_pdb(last_order_number, infile, outfile)
