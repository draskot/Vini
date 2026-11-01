import re
import os
import sys

def extract_affinity():
    log_file_path = 'log'
    
    # Check if the log file exists
    if not os.path.exists(log_file_path):
        print("Log file does not exist.")
        return "ERROR"

    # Read the log file content
    with open(log_file_path, 'r') as file:
        log_content = file.read()

    # Print the content for debugging purposes
    print("Log file content:")
    print(log_content)

    # Regular expression to match the line containing the affinity for mode 1
    pattern = re.compile(r"^\s*1\s+(-\d+\.\d+)", re.MULTILINE)
    match = pattern.search(log_content)
    
    if match:
        affinity = match.group(1)
        return float(affinity)
    else:
        print("Affinity value for mode 1 not found.")
        return "ERROR"

def write_affinity_to_file(output_file_path):
    affinity = extract_affinity()
    
    # Write the affinity value to the specified output file
    with open(output_file_path, 'w') as output_file:
        output_file.write(str(affinity))

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <output_file_path>")
        sys.exit(1)

    output_file_path = sys.argv[1]
    write_affinity_to_file(output_file_path)
    print(f"Affinity value written to {output_file_path}")

