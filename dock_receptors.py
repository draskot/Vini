#!/usr/bin/env python3
import os
import subprocess

# -----------------------------
# Load environment
# -----------------------------
vini_dir = os.environ.get("vini_dir")
WORKDIR = os.environ.get("WORKDIR")
if not vini_dir or not WORKDIR:
    raise ValueError("Please make sure 'vini_dir' and 'WORKDIR' are exported in the environment.")

# Source globals
globals_file = os.path.join(vini_dir, "globals")
with open(globals_file) as f:
    for line in f:
        if line.startswith("export "):
            key_val = line.strip().split("export ")[1].split("=")
            if len(key_val) == 2:
                os.environ[key_val[0]] = key_val[1]

SCTYPE = os.environ.get("SCTYPE", "SLURM")
partition = os.environ.get("partition", "gpu")
walltime = os.environ.get("walltime", "2-00:00:00")
job_submit = os.environ.get("job_submit", "sbatch")
ACCOUNT = os.environ.get("ACCOUNT", "")

# -----------------------------
# Paths
# -----------------------------
matrix_file = os.path.join(WORKDIR, "VINI_matrix.txt")
slurm_dir = os.path.join(WORKDIR, "slurm_jobs")
os.makedirs(slurm_dir, exist_ok=True)

# -----------------------------
# Read matrix
# -----------------------------
matrix = []
with open(matrix_file) as f:
    for line in f:
        row = line.strip().split()
        matrix.append(row)

nrows = len(matrix)
ncols = len(matrix[0]) if nrows > 0 else 0

# -----------------------------
# Generate jobs
# -----------------------------
for i in range(nrows):
    for j in range(i, ncols):  # upper triangle for symmetric matrix
        element = matrix[i][j]
        if element == "0":
            continue

        # Parse element: "P00533,P04626,PP,expr"
        parts = element.split(",")
        if len(parts) < 4:
            continue
        mol1, mol2, rel_type, expr = parts

        # SLURM job script filename
        job_name = f"job_{i}_{j}"
        script_file = os.path.join(slurm_dir, f"{job_name}.sh")

        with open(script_file, "w") as f:
            if SCTYPE == "SLURM":
                f.write(f"#!/bin/bash\n")
                f.write(f"#SBATCH --job-name={job_name}\n")
                f.write(f"#SBATCH --partition={partition}\n")
                f.write(f"#SBATCH --time={walltime}\n")
                f.write(f"#SBATCH --account={ACCOUNT}\n")
                f.write(f"#SBATCH --output={slurm_dir}/{job_name}.out\n")
                f.write(f"#SBATCH --error={slurm_dir}/{job_name}.err\n\n")
            else:  # PBS
                f.write(f"#PBS -N {job_name}\n")
                f.write(f"#PBS -q {partition}\n")
                f.write(f"#PBS -l walltime={walltime}\n")
                f.write(f"#PBS -o {slurm_dir}/{job_name}.out\n")
                f.write(f"#PBS -e {slurm_dir}/{job_name}.err\n\n")

            # Docking command
            if rel_type == "PP":
                f.write(f"echo 'Running Hex docking for {mol1} and {mol2}'\n")
                f.write(f"hex -batch {mol1}.pdb {mol2}.pdb < docking.mac\n")
                f.write(f"echo 'Running Amber pmemd and GBMMSA for {mol1}-{mol2}'\n")
                f.write(f"# pmemd and GBMMSA commands here, using {expr} for weighting\n")
            elif rel_type == "PC":
                f.write(f"echo 'Running Vina docking for {mol1} (protein) and {mol2} (ligand)'\n")
                f.write(f"vina --cpu 1 --size_x 40 --size_y 40 --size_z 40 "
                        f"--config conf_{i}_{j}.txt "
                        f"--receptor {mol1}.pdbqt --ligand {mol2}.pdbqt "
                        f"--out {WORKDIR}/{job_name}_ligand.pdbqt > {WORKDIR}/{job_name}_log\n")

        # Submit job
        try:
            subprocess.run([job_submit, script_file], check=True)
        except subprocess.CalledProcessError as e:
            print(f"Failed to submit job {script_file}: {e}")

print(f"All jobs submitted. Check {slurm_dir} for scripts and logs.")

