from rdkit import Chem
import sys

# Input SDF file
sdf_file = sys.argv[1]

# Load molecules
suppl = Chem.SDMolSupplier(sdf_file, removeHs=False)
has_hydrogens = False

for mol in suppl:
    if mol is None:
        continue
    for atom in mol.GetAtoms():
        if atom.GetAtomicNum() == 1:  # Hydrogen
            has_hydrogens = True
            break
    if has_hydrogens:
        break

if has_hydrogens:
    print("yes")
else:
    print("no")
