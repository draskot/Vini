# calculate_qm_binding_energy.py
import re
import os
import sys

def extract_vini_mopac_energy(mopac_out_path):
    """
    Opens MOPAC .out file and picks the value Final Heat of Formation in kcal/mol.
    """
    pattern = r"FINAL HEAT OF FORMATION\s*=\s*([\d\.-]+)\s*KCAL"
    try:
        with open(mopac_out_path, 'r', encoding='utf-8') as file:
            content = file.read()
            match = re.search(pattern, content)
            if match:
                return float(match.group(1))
            else:
                print(f"⚠️ Warning: VINI was not able to find energy record in {mopac_out_path}!")
                return None
    except FileNotFoundError:
        print(f"❌ Error: MOPAC file {mopac_out_path} does not exist")
        return None

def main():
    # Enforce positional command line arguments
    if len(sys.argv) < 3:
        print("❌ Error: Missing parameters.")
        print("Usage: python calculate_qm_binding_energy.py <lig_index> <comp_index>")
        sys.exit(1)
        
    lig_index = sys.argv[1]
    comp_index = sys.argv[2]
    
    # Target file paths constructed directly from parameters
    lig_file = f"ligand_{lig_index}.out"
    rec_file = f"receptor_{comp_index}.out"
    cpx_file = f"complex_{comp_index}_qm.out"
    
    # Process files
    e_lig = extract_vini_mopac_energy(lig_file)
    e_rec = extract_vini_mopac_energy(rec_file)
    e_cpx = extract_vini_mopac_energy(cpx_file)
    
    if e_lig is None or e_rec is None or e_cpx is None:
        print("❌ Error: Missing energy outputs. Cannot compute binding affinity.")
        sys.exit(1)

    # Compute: Delta G_binding = E_complex – (E_receptor + E_ligand)
    delta_g = e_cpx - (e_rec + e_lig)
    
    # Console Layout
    print(f"--- VINI SQM2.20 Energy Extraction [Lig: {lig_index} | Comp: {comp_index}] ---")
    print(f"Ligand ({lig_file}) Heat   : {e_lig:>12.4f} kcal/mol")
    print(f"Receptor ({rec_file}) Heat : {e_rec:>12.4f} kcal/mol")
    print(f"Complex ({cpx_file}) Heat  : {e_cpx:>12.4f} kcal/mol")
    print("-" * 55)
    print(f"Final Binding Energy (ΔG)  : \033[1;32m{delta_g:>12.4f} kcal/mol\033[0m")
    
    # Append the results directly to the master qm_log file
    with open("qm_log", "a") as log_file:
        log_file.write(f"Ligand: {lig_index} | Complex: {comp_index} | ΔG_binding = {delta_g:.4f} kcal/mol\n")

if __name__ == "__main__":
    main()
