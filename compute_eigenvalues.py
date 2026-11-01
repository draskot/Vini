import numpy as np
import argparse

def compute_and_sort_eigenvalues(matrix_file, eigenvalues_file):
    # Load matrix from file
    matrix = np.loadtxt(matrix_file)

    # Compute eigenvalues
    eigenvalues = np.linalg.eigvals(matrix)

    # Sort eigenvalues in descending order
    eigenvalues = np.sort(eigenvalues)[::-1]

    # Save eigenvalues to file without scientific notation
    np.savetxt(eigenvalues_file, eigenvalues, fmt='%.18f')

if __name__ == "__main__":
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="Compute and sort eigenvalues of a square matrix.")
    parser.add_argument("-s", "--matrix-file", help="Path to the matrix file", required=True)
    parser.add_argument("-t", "--eigenvalues-file", help="Path to the eigenvalues file", required=True)
    args = parser.parse_args()

    # Compute and sort eigenvalues
    compute_and_sort_eigenvalues(args.matrix_file, args.eigenvalues_file)

