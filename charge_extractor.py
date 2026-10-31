# charge_extractor.py
import subprocess
import math

def get_ligand_charge():
    try:
        # Run obabel report command and capture output
        res = subprocess.run(["obabel", "best_pose.pdb", "-oreport"], 
                             capture_output=True, text=True, check=True)
        lines = res.stdout.splitlines()
        total = 0.0
        in_charge_section = False
        
        for line in lines:
            if "ATOMIC CHARGES" in line:
                in_charge_section = True
                continue
            if in_charge_section:
                parts = line.split()
                if not parts:
                    continue
                # If it's a valid atom line (e.g., C 12 -0.15)
                if len(parts) >= 3 and parts[0].isalpha():
                    try:
                        total += float(parts[2])
                    except ValueError:
                        break
                else:
                    # Stop if we leave the atom listings
                    break
        return total
    except Exception as e:
        print(f"Warning extracting ligand charge: {e}")
        return 0.0

def get_receptor_charge():
    total = 0.0
    try:
        with open("qm_ready_receptor_001.pdb", "r") as f:
            for line in f:
                if line.startswith(("ATOM", "HETATM")):
                    parts = line.split()
                    if len(parts) >= 10:
                        try:
                            # In standard PQR format, the charge is the 2nd to last field
                            total += float(parts[-2])
                        except ValueError:
                            pass
        return total
    except FileNotFoundError:
        print("Error: qm_ready_receptor_001.pdb not found.")
        return 0.0

if __name__ == "__main__":
    lig_exact = get_ligand_charge()
    rec_exact = get_receptor_charge()
    
    # Round to nearest whole integer for MOPAC parameters
    X = round(lig_exact)
    Y = round(rec_exact)
    Z = X + Y
    
    print(f"Calculated System Charges -> Ligand: {X} (exact: {lig_exact:.2f}) | Receptor: {Y} (exact: {rec_exact:.2f}) | Complex: {Z}")
    
    # Save charges to a temporary environment file so your bash loop can use them
    with open("mopac_charges.env", "w") as env_file:
        env_file.write(f"export LIG_CHARGE={X}\n")
        env_file.write(f"export REC_CHARGE={Y}\n")
        env_file.write(f"export CPX_CHARGE={Z}\n")
