#!/usr/bin/env python3
import os

# -----------------------------
# Get environment variables
# -----------------------------
workdir = os.environ.get("WORKDIR", os.getcwd())
relations_file = os.path.join(workdir, "relations")
receptors_file = os.path.join(workdir, "receptors_contracted")
cancer_type = os.environ.get("cancer_type")  # <- add this
cell_line = os.environ.get("cell_line")

output_dir = os.path.join(workdir, f"{cancer_type}_data", cell_line)
output_file = os.path.join(output_dir, "VINI_matrix.txt")
os.makedirs(output_dir, exist_ok=True)

# -----------------------------
# Load receptors_contracted
# -----------------------------
# Map KEGG ID to list of line numbers (1-based)
kegg_to_lines = {}
receptors_list = []

with open(receptors_file) as f:
    for line_num, line in enumerate(f, start=1):
        parts = line.strip().split()
        if len(parts) < 3:
            continue
        kegg_id = parts[2]
        receptors_list.append(kegg_id)
        if kegg_id not in kegg_to_lines:
            kegg_to_lines[kegg_id] = []
        kegg_to_lines[kegg_id].append(line_num)

matrix_size = len(receptors_list)

# Initialize matrix with zeros
matrix = [["0" for _ in range(matrix_size)] for _ in range(matrix_size)]

# -----------------------------
# Fill matrix based on relations
# -----------------------------
with open(relations_file) as f:
    for line in f:
        parts = line.strip().split()
        if len(parts) < 8:
            continue
        src_kegg, tgt_kegg, interaction_type, expr_value = parts[2], parts[3], parts[4], parts[7]

        if src_kegg not in kegg_to_lines or tgt_kegg not in kegg_to_lines:
            continue  # skip if KEGG ID missing in receptors_contracted

        # Fill all combinations for duplicates
        for i in kegg_to_lines[src_kegg]:
            for j in kegg_to_lines[tgt_kegg]:
                i0 = i - 1
                j0 = j - 1
                element = f"{src_kegg},{tgt_kegg},{interaction_type},{expr_value}"
                matrix[i0][j0] = element
                matrix[j0][i0] = element  # symmetric

# -----------------------------
# Write matrix to file
# -----------------------------
with open(output_file, "w") as f:
    for row in matrix:
        f.write("\t".join(row) + "\n")

print(f"VINI initial matrix written to: {output_file}")

