#!/usr/bin/env python3

from rdkit import Chem
import sys

if len(sys.argv) != 3:
    print("Usage: clean_sdf_for_rosetta.py input.sdf output.sdf")
    sys.exit(1)

in_sdf = sys.argv[1]
out_sdf = sys.argv[2]

suppl = Chem.SDMolSupplier(in_sdf, removeHs=False)
writer = Chem.SDWriter(out_sdf)

dummy_pattern = Chem.MolFromSmarts('[#0]')  # dummy atoms (*)

n_written = 0

for mol in suppl:
    if mol is None:
        continue

    # Remove dummy atoms
    clean = Chem.DeleteSubstructs(mol, dummy_pattern)

    # Keep largest fragment only
    frags = Chem.GetMolFrags(clean, asMols=True, sanitizeFrags=False)
    clean = max(frags, key=lambda m: m.GetNumAtoms())

    try:
        Chem.SanitizeMol(clean)
    except Exception:
        print("WARNING: Sanitization failed, skipping molecule", file=sys.stderr)
        continue

    writer.write(clean)
    n_written += 1

writer.close()

if n_written == 0:
    print("ERROR: No valid molecules written!", file=sys.stderr)
    sys.exit(2)

