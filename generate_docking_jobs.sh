#!/usr/bin/env bash

# -----------------------------
# Prepare docking commands from VINI matrix
# -----------------------------
set -e

# Check environment
if [[ -z "$WORKDIR" ]]; then
    echo "WORKDIR is not set. Please export WORKDIR."
    exit 1
fi

# Input files
MATRIX="$WORKDIR/VINI_matrix.txt"
RECEPTORS="$WORKDIR/receptors_contracted"
OUTPUT="$WORKDIR/docking_commands.txt"

# Clear previous output
> "$OUTPUT"

# Get total number of lines in matrix
num_lines=$(wc -l < "$MATRIX")

# Loop over rows
row_index=0
while read -r row; do
    ((row_index++))
    # Split row into elements
    IFS=$'\t' read -r -a elems <<< "$row"

    col_index=0
    for elem in "${elems[@]}"; do
        ((col_index++))
        # Skip empty / zero
        [[ "$elem" == "0" ]] && continue

        # Get corresponding complex files
        complexA=$(printf "%s/%03d_complex.pdb" "$WORKDIR/${cancer_type}_data" "$row_index")
        complexB=$(printf "%s/%03d_complex.pdb" "$WORKDIR/${cancer_type}_data" "$col_index")

        # Decide docking method
        if [[ "$elem" == pubchem* ]]; then
            # protein-ligand
            echo "vina --receptor $complexA --ligand $complexB --out $WORKDIR/docking_results/${row_index}_${col_index}_vina.pdbqt" >> "$OUTPUT"
        else
            # protein-protein
            echo "hex -p1 $complexA -p2 $complexB -o $WORKDIR/docking_results/${row_index}_${col_index}_hex.pdb" >> "$OUTPUT"
        fi
    done
done < "$MATRIX"

echo "Docking commands written to $OUTPUT"

