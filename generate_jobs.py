#!/usr/bin/env python3
import os

# -----------------------------
# Load environment
# -----------------------------
vini_dir = os.environ.get("vini_dir")
workdir = os.environ.get("WORKDIR", os.getcwd())

if not vini_dir:
    raise ValueError("Please export 'vini_dir' in the environment.")

globals_file = os.path.join(vini_dir, "globals")
matrix_file = os.path.join(workdir, "VINI_matrix.txt")
jobs_dir = os.path.join(workdir, "slurm_jobs")

os.makedirs(jobs_dir, exist_ok=True)

# -----------------------------
# Read globals
# -----------------------------
globals_dict = {}
with open(globals_file) as f:
    for line in f:
        if line.startswith("export "):
            key, val = line.strip().replace("export ", "").split("=", 1)
            globals_dict[key] = val

partition = globals_dict.get("partition", "cpu")
walltime = globals_dict.get("walltime", "2-00:00:00")
account = globals_dict.get("ACCOUNT", "")
SCTYPE = globals_dict.get("SCTYPE", "SLURM")

# -----------------------------
# Load matrix
# -----------------------------
matrix = []
with open(matrix_file) as f:
    for line in f:
        matrix.append(line.strip().split())

nrows = len(matrix)

# -----------------------------
# Generate SLURM scripts
# -----------------------------
for i in range(nrows):
    for j in range(i+1, nrows):  # scan upper triangle
        element = matrix[i][j]
        if element == "0":
            continue
        # parse element
        # expected format: NAME1,NAME2,TYPE,EXPR
        parts = element.split(",")
        if len(parts) < 4:
            continue
        name1, name2, interaction_type, expr = parts
        job_name = f"job_{i}_{j}.sh"
        job_path = os.path.join(jobs_dir, job_name)

        with open(job_path, "w") as f:
            f.write("#!/bin/bash\n")
            f.write(f"#SBATCH --job-name=job_{i}_{j}\n")
            f.write(f"#SBATCH --partition={partition}\n")
            f.write(f"#SBATCH --time={walltime}\n")
            f.write(f"#SBATCH --account={account}\n")
            f.write(f"#SBATCH --output={jobs_dir}/job_{i}_{j}.out\n")
            f.write(f"#SBATCH --error={jobs_dir}/job_{i}_{j}.err\n")
            if partition.lower() == "gpu":
                f.write("#SBATCH --gres=gpu:1\n")
            f.write("\n")
            f.write(f"echo 'Running {interaction_type} docking for {name1} and {name2}'\n")
            if interaction_type.upper() == "PP":
                f.write(f"hex -batch {name1}.pdb {name2}.pdb < docking.mac\n")
                f.write(f"# pmemd and GBMMSA commands here, using {expr} for weighting\n")
            else:  # PC
                f.write(f"vina --cpu 1 --size_x 40 --size_y 40 --size_z 40 "
                        f"--receptor {name1}.pdbqt --ligand {name2}.pdbqt --out ligand.pdbqt "
                        f"> log\n")

        print(f"Generated SLURM script: {job_path}")

