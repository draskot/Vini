import os
import sys
import numpy as np

def create_energy_binding(target_dir):
    # Fixed input/output names inside target_dir
    matrix_filename = "Intermediate_matrix"
    vector_filename = "vec"
    output_filename = "EB_matrix"

    # Construct the full paths
    matrix_path = os.path.join(target_dir, matrix_filename)
    vector_path = os.path.join(target_dir, vector_filename)
    output_path = os.path.join(target_dir, output_filename)
    
    # 1. Load the files
    try:
        matrix = np.loadtxt(matrix_path)
        vector = np.loadtxt(vector_path)
    except Exception as e:
        print(f"Error loading files from {target_dir}: {e}")
        sys.exit(1)

    # 2. Validate dimensions
    if matrix.ndim != 2 or matrix.shape[0] != matrix.shape[1]:
        print(f"Error: Matrix must be square (NxN). Found shape: {matrix.shape}")
        sys.exit(1)
        
    N = matrix.shape[0]
    if vector.size != N:
        print(f"Error: Vector size ({vector.size}) does not match matrix dimensions ({N}x{N}).")
        sys.exit(1)

    # 3. Substitute the main diagonal elements
    matrix[np.diag_indices_from(matrix)] = vector.flatten()

    # 4. Save the resulting EB_matrix
    np.savetxt(output_path, matrix, fmt='%.6f')
    print(f"Successfully created and saved {output_filename} in {target_dir}")

if __name__ == "__main__":
    # Ensure the user passed the target directory argument
    if len(sys.argv) < 2:
        print("Error: Missing target directory argument.")
        print("Usage: python create_energy_binding_matrix.py <target_dir>")
        sys.exit(1)
        
    # Get the target directory from the first command-line argument
    given_dir = sys.argv[1]
    create_energy_binding(given_dir)
