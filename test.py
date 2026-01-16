python3.9 - << 'EOF'
from rdkit import Chem
mol = Chem.MolFromSmiles("CCO")
print(mol.GetNumAtoms())
EOF

