import sys
import MDAnalysis as mda

def transfer_coordinates(ref_pdb_path, docked_pdbqt_path, output_pdb_path):
    # Load the original fully-protonated reference and the docked Vina pose
    u_ref = mda.Universe(ref_pdb_path)
    u_docked = mda.Universe(docked_pdbqt_path)
    
    # Select only heavy atoms (non-hydrogens) from both
    ref_heavy = u_ref.select_atoms("not element H")
    docked_heavy = u_docked.select_atoms("not element H")
    
    if len(ref_heavy) != len(docked_heavy):
        print(f"Error: Heavy atom count mismatch! Reference: {len(ref_heavy)}, Docked: {len(docked_heavy)}")
        sys.exit(1)
        
    # Sort atoms to ensure perfect alignment regardless of PDBQT shuffling
    ref_sorted = sorted(ref_heavy, key=lambda a: (a.resname, a.resid, a.name, a.element))
    docked_sorted = sorted(docked_heavy, key=lambda a: (a.resname, a.resid, a.name, a.element))
    
    # Transfer the 3D coordinates from the docked pose to the original protonated template
    for r_atom, d_atom in zip(ref_sorted, docked_sorted):
        if r_atom.element != d_atom.element:
            print(f"Critical Error: Atom mismatch during mapping ({r_atom.name} vs {d_atom.name})")
            sys.exit(1)
        r_atom.position = d_atom.position
        
    # Write out the updated reference universe containing Vina coordinates and all correct hydrogens
    u_ref.atoms.write(output_pdb_path)
    print(f"Success: Transferred Vina coordinates to protonated template -> {output_pdb_path}")

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: python coordinate_transfer.py <original_protonated.pdb> <best_pose.pdbqt> <output.pdb>")
        sys.exit(1)
    transfer_coordinates(sys.argv[1], sys.argv[2], sys.argv[3])
