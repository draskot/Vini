#!/usr/bin/env python3
import os
import sys
from collections import defaultdict

# -----------------------------
# Get environment variables
# -----------------------------
workdir = os.environ.get("WORKDIR", os.getcwd())
relations_file = os.path.join(workdir, "relations")
receptors_file = os.path.join(workdir, "receptors_contracted")

cancer_type = os.environ.get("cancer_type")
cell_line = os.environ.get("cell_line")

if not cancer_type or not cell_line:
    path_parts = workdir.rstrip('/').split('/')
    if len(path_parts) >= 2:
        if path_parts[-1].isdigit():
            cell_line = path_parts[-2] if not cell_line else cell_line
            cancer_type = path_parts[-3].replace("_data", "") if not cancer_type else cancer_type
        else:
            cell_line = path_parts[-1] if not cell_line else cell_line
            cancer_type = path_parts[-2].replace("_data", "") if not cancer_type else cancer_type

if not cancer_type or not cell_line:
    print("Error: Could not determine cancer_type or cell_line.")
    sys.exit(1)

output_dir = os.path.join(workdir, f"{cancer_type}_data", cell_line)
output_file = os.path.join(output_dir, "Initial_matrix")
os.makedirs(output_dir, exist_ok=True)

# -----------------------------
# Load receptors_contracted by strict sequential row appearance order
# -----------------------------
# Maps a single Cluster ID (e.g., "6") to ALL sequential row indices it populates
cluster_to_matrix_indices = defaultdict(list)
idx_to_uniprot = {}

valid_lines_count = 0

with open(receptors_file, "r") as f:
    for line in f:
        line_str = line.strip()
        if not line_str or line_str.startswith("#"):
            continue
        parts = line_str.split()
        if len(parts) < 6: # File has 6 columns
            continue

        # Correct Column Offsets (0-indexed):
        # parts[0] = Index (e.g. 4, 5, 6) -> Cluster ID
        # parts[1] = KEGG ID (e.g. hsa:2064)
        # parts[2] = UniProt ID (e.g. P04626)
        cluster_id = parts[0]        
        uniprot_id = parts[2]           

        # Map this cluster ID to this unique, sequential line position
        cluster_to_matrix_indices[cluster_id].append(valid_lines_count)
        idx_to_uniprot[valid_lines_count] = uniprot_id
        valid_lines_count += 1

matrix_size = valid_lines_count

# Initialize a clean matrix grid
matrix = [["0" for _ in range(matrix_size)] for _ in range(matrix_size)]

# Pre-populate Diagonal with Uniform Structured String Placeholders
for i in range(matrix_size):
    if i in idx_to_uniprot:
        uniprot_id = idx_to_uniprot[i]
        matrix[i][i] = f"{uniprot_id},{uniprot_id},self,0.000"

# -----------------------------
# Fill matrix based on relations using sequential maps
# -----------------------------
with open(relations_file, "r") as f:
    for line in f:
        line_str = line.strip()
        if not line_str or line_str.startswith("#"):
            continue
        parts = line_str.split()
        if len(parts) < 8:
            continue

        # Correct Column Offsets for relations file:
        # parts[0] = Source numeric index (e.g. 51)
        # parts[1] = Target numeric index (e.g. 4)
        # parts[2] = Source ID string (e.g. P00533 or pubchem:8260)
        # parts[3] = Target ID string (e.g. P04626)
        src_cluster = parts[0]
        tgt_cluster = parts[1]
        src_id = parts[2]
        tgt_id = parts[3]
        interaction_type = parts[4]
        expr_value = parts[-1]

        # Check if BOTH cluster IDs exist in our receptor index maps
        if src_cluster in cluster_to_matrix_indices and tgt_cluster in cluster_to_matrix_indices:
            # Loop over every matrix index that belongs to these clusters
            for i0 in cluster_to_matrix_indices[src_cluster]:
                for j0 in cluster_to_matrix_indices[tgt_cluster]:
                    
                    if i0 == j0:
                        continue

                    # Construct the interaction element string
                    element = f"{src_id},{tgt_id},{interaction_type},{expr_value}"
                    matrix[i0][j0] = element
                    matrix[j0][i0] = element

# -----------------------------
# Write matrix to file
# -----------------------------
with open(output_file, "w") as f:
    for row in matrix:
        f.write("\t".join(row) + "\n")

print(f"Initial matrix successfully written to: {output_file} (Strict Size: {matrix_size}x{matrix_size})")
