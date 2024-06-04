import sys
import shutil

def process_data(target_dir, workdir):
    with open(f"{target_dir}/vec.tmp", "w") as output_file:
        with open(f"{workdir}/receptors_contracted", "r") as input_file:
            for index, line in enumerate(input_file, start=1):
                genex = line.split()[5]  # Assuming the 6th column (index 5) contains the value you want
                genex = round(float(genex)) if genex else 1  # Set genex to 1 if unset or empty

                with open(f"{target_dir}/vec", "r") as vec_file:
                    affinity = next(line for i, line in enumerate(vec_file, start=1) if i == index)

                affinity = float(affinity.split()[0])  # Assuming the affinity is in the first column

                result = genex * affinity
                output_file.write(f"{result}\n")

    # Copy the result file to vec
    shutil.copyfile(f"{target_dir}/vec.tmp", f"{target_dir}/vec")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <target_dir> <workdir>")
        sys.exit(1)

    target_dir_arg, workdir_arg = sys.argv[1], sys.argv[2]
    process_data(target_dir_arg, workdir_arg)

