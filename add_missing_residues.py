## USAGE example: Chimera --nogui --script "add_missing_residues.py ${accession_code}"

import chimera
from DockPrep import prep
import Midas
import os

# Get the list of files in the current directory
files_in_directory = os.listdir('.')

# Find the PDB file in the current directory
PDB_file = next((file for file in files_in_directory if file.endswith(".pdb")), None)

if PDB_file is None:
    print("Error: No PDB file found in the current directory.")
    exit()

# Open the PDB file
protein = chimera.openModels.open(PDB_file)

# Prepare the protein (add missing residues and hydrogens)
prep(protein, addHFunc=None, addCharges=False)

# Write the modified protein structure to a new PDB file in the current directory
output_filename = os.path.splitext(PDB_file)[0] + "_res.pdb"
Midas.write(protein, None, output_filename)
