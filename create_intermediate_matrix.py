#!/usr/bin/env python3
import os
import sys

# -----------------------------------------------------------------------------
# 1. Global Pipeline Environment Configuration
# -----------------------------------------------------------------------------
workdir = os.environ.get("WORKDIR")
cancer_type = os.environ.get("cancer_type")
cell_line = os.environ.get("cell_line")

if not workdir or not cancer_type or not cell_line:
    print("[VINI HARVESTER ERROR] Missing critical environment variables!")
    sys.exit(1)

data_dir = os.path.join(workdir, f"{cancer_type}_data", cell_line)
matrix_file = os.path.join(data_dir, "Initial_matrix")
output_file = os.path.join(data_dir, "Intermediate_matrix")

# -----------------------------------------------------------------------------
# 2. Parsing Core: Direct dG_cross Extractor
# -----------------------------------------------------------------------------
def extract_rosetta_binding_energy(job_dir):
    """
    Directly isolates and extracts the 'dG_cross' column from interface.sc
    """
    score_path = os.path.join(job_dir, "interface.sc")
    if not os.path.exists(score_path):
        return None

    try:
        with open(score_path, "r") as sf:
            lines = [line.strip().split() for line in sf if line.strip()]
            
        header_row = None
        data_row = None
        
        for tokens in lines:
            if not tokens:
                continue
            # Find the header line containing your exact columns
            if tokens[0] == "SCORE:" and "dG_cross" in tokens:
                header_row = tokens
            # Find the line containing the actual numeric values
            elif tokens[0] == "SCORE:" and tokens[1] != "total_score" and header_row is not None:
                data_row = tokens

        if header_row and data_row:
            # Map directly to dG_cross index position
            dg_idx = header_row.index("dG_cross")
            if len(data_row) > dg_idx:
                return float(data_row[dg_idx])
                
    except Exception as e:
        print(f"Warning: Error parsing {score_path}: {e}")
        
    return None

# -----------------------------------------------------------------------------
# 3. Coordinate Update Loop (Strips Strings, Keeps Pure dG_cross Values)
# -----------------------------------------------------------------------------
final_grid = []

with open(matrix_file, "r") as f:
    for row_idx, line in enumerate(f):
        elements = line.strip().split("\t")
        updated_row = []
        
        for col_idx, cell in enumerate(elements):
            cell = cell.strip()
            
            if cell == "0" or not cell:
                updated_row.append("0.000000000")
                continue
                
            parts = cell.split(",")
            if len(parts) < 4:
                updated_row.append("0.000000000")
                continue
                
            rel_type = parts[2]
            
            # Diagonal/self elements are set to 0 for algebraic operations
            if rel_type == "self" or row_idx == col_idx:
                updated_row.append("0.000000000")
                continue
                
            # Locate upper-triangle job directory
            r, c = (row_idx, col_idx) if row_idx < col_idx else (col_idx, row_idx)
            target_job_folder = os.path.join(data_dir, f"job_{r}_{c}")
            
            computed_score = extract_rosetta_binding_energy(target_job_folder)
            
            if computed_score is not None:
                # Harvests your real, positive dG_cross value directly into the grid
                updated_row.append(f"{computed_score:.9f}")
            else:
                # If a job file isn't found, keep it as 0.000000000 to avoid expression noise
                updated_row.append("0.000000000")
                
        final_grid.append(updated_row)

# -----------------------------------------------------------------------------
# 4. Save Numeric Matrix
# -----------------------------------------------------------------------------
with open(output_file, "w") as out:
    for row in final_grid:
        out.write("\t".join(row) + "\n")

print(f"[VINI] Success! Clean numeric Intermediate_matrix generated using dG_cross.")
