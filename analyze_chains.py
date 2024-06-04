import sys
import string

def analyze_chains(pdb_file):
    chains = set()
    with open(pdb_file, 'r') as file:
        for line in file:
            if line.startswith('ATOM') or line.startswith('HETATM'):
                chain_id = line[21]
                chains.add(chain_id)
    chains_str = ' '.join(sorted(chains))
    return chains_str, sorted(chains)

def rename_chains(pdb_file, used_chains):
    new_lines = []
    chain_map = {}
    new_chain_ids = iter(c for c in string.ascii_uppercase if c not in used_chains)

    with open(pdb_file, 'r') as file:
        for line in file:
            if line.startswith('ATOM') or line.startswith('HETATM'):
                chain_id = line[21]
                if chain_id in used_chains:
                    if chain_id not in chain_map:
                        chain_map[chain_id] = next(new_chain_ids)
                    new_chain_id = chain_map[chain_id]
                    new_line = line[:21] + new_chain_id + line[22:]
                    new_lines.append(new_line)
                else:
                    new_lines.append(line)
            else:
                new_lines.append(line)

    with open(pdb_file, 'w') as file:
        file.writelines(new_lines)

    return sorted(chain_map.values())

def generate_flag_global_docking(chain1_str, chain2_str):
    partners = f"{chain1_str}:{chain2_str}"
    with open('flag_global_docking', 'w') as file:
        file.write(f"-docking:partners {partners}\n")
        file.write("-docking:ligand\n")
        file.write("-nstruct 1\n")
        file.write("-out:path:pdb\n")
        file.write("-ignore_unrecognized_res\n")
        file.write("-detect_disulf false\n")
        file.write("-overwrite\n")
        file.write("-spin\n")
        file.write("-randomize\n")
        file.write("-dock_pert 3 8\n")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python analyze_chains.py <comp_index> <lig_index>")
        sys.exit(1)

    comp_index = sys.argv[1]
    lig_index = sys.argv[2]

    pdb_file1 = f"complex_{comp_index}.pdb"
    pdb_file2 = f"ligand_{lig_index}".rstrip('.pdb') + ".pdb"

    chain1_str, chains1 = analyze_chains(pdb_file1)
    chain2_str, chains2 = analyze_chains(pdb_file2)

    if any(chain in chains1 for chain in chains2):
        renamed_chains = rename_chains(pdb_file2, chains1)
        chain2_str = ' '.join(renamed_chains)

    with open('chains', 'w') as f:
        f.write(f"chain1: {chain1_str}\n")
        f.write(f"chain2: {chain2_str}\n")

    generate_flag_global_docking(chain1_str, chain2_str)

    print("Chain information and flag_global_docking file have been generated.")

