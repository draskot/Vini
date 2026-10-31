import sys
import warnings  #Added to suppress noisy logging
import numpy as np
import MDAnalysis as mda
from scipy.spatial.distance import cdist

#Tell Python to ignore MDAnalysis parsing and writing warnings
warnings.filterwarnings("ignore", category=UserWarning, module="MDAnalysis")

def vini_trim_receptor(receptor_pdb, ligand_pdb, output_trimmed_pdb, radius=10.0):
    try:
        # Load both structures into separate Universes
        u_receptor = mda.Universe(receptor_pdb)
        u_ligand = mda.Universe(ligand_pdb)
        
        # Calculate the distance matrix between all receptor and ligand atoms
        distances = cdist(u_receptor.atoms.positions, u_ligand.atoms.positions)
        
        # Find receptor atom indices where the minimum distance to ANY ligand atom is <= radius
        receptor_indices = np.where(np.min(distances, axis=1) <= radius)
        
        if len(receptor_indices[0]) > 0:  # Fixed index array check
            matched_atoms = u_receptor.atoms[receptor_indices]
            # Expand to include full residues (equivalent to "same residue as")
            trimmed_atoms = matched_atoms.residues.atoms
        else:
            trimmed_atoms = u_receptor.select_atoms("none")

        #  METADATA AND DATA INTEGRITY FALLBACK:
        if len(trimmed_atoms) == 0:
            print(f"⚠️ Warning: Zero atoms found within {radius}Å. Forcing full receptor fallback to protect production.", flush=True)
            trimmed_atoms = u_receptor.atoms

        # Write out the coordinates and immediately flush stdout to the SLURM log
        trimmed_atoms.write(output_trimmed_pdb)
        print(f"✅ Receptor successfully excised to {radius}Å -> {output_trimmed_pdb} (Atoms: {len(trimmed_atoms)})", flush=True)

    except Exception as e:
        print(f"❌ Error during receptor excision: {e}", flush=True)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: python vini_trimmer.py <receptor.pdb> <ligand.pdb> <output.pdb> [radius]", flush=True)
        sys.exit(1)

    rad = float(sys.argv[4]) if len(sys.argv) >= 5 else 10.0
    vini_trim_receptor(sys.argv[1], sys.argv[2], sys.argv[3], rad)
