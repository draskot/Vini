import sys
import re

def extract_docked_ligand_coordinates(log_file_name, ligand_pdbqt_file_name):
    # Read the Autodock4 log file
    with open(log_file_name, 'r') as log_file:
        lines = log_file.readlines()

    # Extract energy values and corresponding line numbers
    energy_lines = [line.strip() for line in lines if "Estimated Free Energy of Binding" in line]
    energy_values = [float(re.search(r'=\s+(-?\d+\.\d+)\s+kcal/mol', line).group(1)) for line in energy_lines]

    # Find the minimum energy value
    min_energy = min(energy_values, default=None)

    # Print some debugging information
    print("Lines containing 'Energy':")
    for i, line in enumerate(energy_lines):
        print(f"{i}: {line}")

    print(f"Energy values: {energy_values}")
    print(f"Min Energy: {min_energy}")

    # Extract the ligand coordinates from the corresponding pose
    if min_energy is not None:
        # Find the line number containing the lowest binding energy
        min_energy_index = energy_values.index(min_energy)
        min_energy_line = re.escape(energy_lines[min_energy_index])

        # Extract the ligand coordinates from the corresponding pose
        pattern = re.compile(f"{min_energy_line}.*?TER", re.DOTALL)
        match = pattern.search(''.join(lines))

        if match:
            docked_ligand_lines = match.group(0).split('\n')
            docked_ligand_lines = [line + '\n' for line in docked_ligand_lines if line.strip()]

            # Write the extracted ligand coordinates to a new PDBQT file
            output_pdbqt_file_name = "{}_docked.pdbqt".format(ligand_pdbqt_file_name.split('.')[0])
            with open(output_pdbqt_file_name, 'w') as output_file:
                output_file.writelines(docked_ligand_lines)

            print(f"Docked ligand coordinates extracted and saved to {output_pdbqt_file_name}")
        else:
            print("Error: Could not find the line with the lowest energy in the log file.")
    else:
        print("Error: Could not find the line with the lowest energy in the log file.")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py log_file_name ligand_pdbqt_file_name")
        sys.exit(1)

    log_file_name = sys.argv[1]
    ligand_pdbqt_file_name = sys.argv[2]

    extract_docked_ligand_coordinates(log_file_name, ligand_pdbqt_file_name)
