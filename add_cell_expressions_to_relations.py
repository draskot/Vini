#!/usr/bin/env python3
import os
import sys
import math

# -----------------------------
# Load environment variables
# -----------------------------
vini_dir = os.environ.get("vini_dir")
cell_line = os.environ.get("cell_line")

if not vini_dir or not cell_line:
    raise ValueError("Globals not found: please make sure 'vini_dir' and 'cell_line' are exported in the environment.")

# -----------------------------
# File paths
# -----------------------------
workdir = os.environ.get("WORKDIR", os.getcwd())
receptors_file = os.path.join(workdir, "receptors_contracted")
relations_file = os.path.join(workdir, "relations")
relations_output_file = os.path.join(workdir, "relations")

ccle_expression_file = os.path.join(
    vini_dir, "database", "cell_lines", cell_line, "expressions",
    f"{cell_line}_expression.txt"
)

# -----------------------------
# Load CCLE expressions
# -----------------------------
expr_dict = {}
expr_values = []

with open(ccle_expression_file) as f:
    for line in f:
        parts = line.strip().split()
        if len(parts) != 2:
            continue

        gene, expr_raw = parts
        expr_raw = float(expr_raw)

        expr_log2 = 0.0 if expr_raw < 0 else math.log2(expr_raw + 1)

        expr_dict[gene] = expr_log2
        expr_values.append(expr_log2)

mean_expr = sum(expr_values) / len(expr_values) if expr_values else 1.0

# -----------------------------
# Load receptors → map KEGG index to UniProt/PubChem + expression
# -----------------------------
receptors = {}
kegg_compounds = set()

with open(receptors_file) as f:
    for line in f:
        parts = line.strip().split()
        if len(parts) < 6:
            continue

        entry_id = parts[0]     # KEGG index
        uniprot = parts[2]      # UniProt or pubchem:XXXX
        expr_log = float(parts[4])

        receptors[entry_id] = {
            "uniprot": uniprot,
            "expr_log": expr_log
        }

        if uniprot.startswith("C") or uniprot.startswith("pubchem"):
            kegg_compounds.add(entry_id)

# -----------------------------
# Update relations with new UniProt column
# -----------------------------
relations_new = []

with open(relations_file) as f:
    for line in f:
        parts = line.strip().split()
        if len(parts) < 3:
            continue

        src_id, tgt_id, rel_type = parts[:3]

        # ---- UniProt/PubChem lookup ----
        src_uniprot = receptors.get(src_id, {}).get("uniprot", "NA")
        tgt_uniprot = receptors.get(tgt_id, {}).get("uniprot", "NA")

        # ---- Expression lookup ----
        src_expr = receptors.get(src_id, {}).get("expr_log", mean_expr)
        tgt_expr = receptors.get(tgt_id, {}).get("expr_log", mean_expr)

        if src_id in kegg_compounds:
            src_expr = 1.0
        if tgt_id in kegg_compounds:
            tgt_expr = 1.0

        combined_expr = min(src_expr, tgt_expr)

        relations_new.append(
            f"{src_id} {tgt_id} {src_uniprot} {tgt_uniprot} "
            f"{rel_type} {src_expr:.9f} {tgt_expr:.9f} {combined_expr:.9f}"
        )

# -----------------------------
# Write updated file
# -----------------------------
with open(relations_output_file, "w") as f:
    for line in relations_new:
        f.write(line + "\n")

print(f"Updated relations written to {relations_output_file}")

