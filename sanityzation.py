from rdkit import Chem
import sys

in_sdf = "ligand_clean.sdf"
out_sdf = "ligand_sanitized.sdf"

suppl = Chem.SDMolSupplier(in_sdf, removeHs=False)
writer = Chem.SDWriter(out_sdf)

for mol in suppl:
    if mol is None:
        continue
    try:
        Chem.SanitizeMol(mol)
    except Exception as e:
        print(f"WARNING: sanitization failed for molecule: {e}")
        continue
    writer.write(mol)

writer.close()

