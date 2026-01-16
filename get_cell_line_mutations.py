import os
import pandas as pd

# === Step 0: Read cell line name from environment variable ===
cell_line_name = os.getenv("cell_line")
if not cell_line_name:
    raise ValueError("Environment variable 'cell_line' is not set. Example: export cell_line=PANC-1")

print(f"🔍 Extracting mutations for cell line: {cell_line_name}")

# === Step 1: Set directories ===
vini_dir = os.path.dirname(os.path.abspath(__file__))
depmap_dir = os.getenv("DEPMAP_DIR", os.path.join(vini_dir, "database"))
cell_lines_dir = os.path.join(depmap_dir, "cell_lines")
cell_line_dir = os.path.join(cell_lines_dir, cell_line_name, "mutations")

os.makedirs(cell_line_dir, exist_ok=True)

print(f"📁 Using DEPMAP_DIR: {depmap_dir}")
print(f"📂 Saving output to: {cell_line_dir}")

# === Step 2: Lookup ModelID ===
model_file = os.path.join(depmap_dir, "Model.csv")
model_df = pd.read_csv(model_file)

cell_line_col = model_df.columns[2]
matches = model_df[model_df[cell_line_col].str.contains(cell_line_name, case=False, na=False)]

if matches.empty:
    raise ValueError(f"No match found for {cell_line_name} in {model_file}")

depmap_id = matches.iloc[0, 0]
print(f"✅ Found ModelID for {cell_line_name}: {depmap_id}")

# === Step 3: Load mutation data ===
mutation_file = os.path.join(depmap_dir, "OmicsSomaticMutations.csv")
if not os.path.exists(mutation_file):
    raise FileNotFoundError(f"'{mutation_file}' not found. Make sure the file exists in DEPMAP_DIR.")

print(f"📖 Loading mutation data from {mutation_file}...")
mut_df = pd.read_csv(mutation_file, low_memory=False)

# === Step 4: Filter by ModelID ===
if "ModelID" not in mut_df.columns:
    raise ValueError(f"'ModelID' column not found in {mutation_file}")

filtered = mut_df[mut_df["ModelID"] == depmap_id]
if filtered.empty:
    raise ValueError(f"No mutations found for {depmap_id} in {mutation_file}")

print(f"✅ Found {len(filtered)} mutations for {cell_line_name} ({depmap_id})")

# === Step 5: Select relevant columns for VINI ===
possible_cols = {
    "HugoSymbol": "Gene",
    "ProteinChange": "Mutation",
    "VariantType": "Type",
    "ModelID": "ModelID"
}

available_cols = [col for col in possible_cols if col in filtered.columns]
mut_subset = filtered[available_cols].rename(columns=possible_cols)

# === Step 6: Save outputs ===
output_csv = os.path.join(cell_line_dir, f"{cell_line_name}_{depmap_id}_mutations.csv")
output_txt = os.path.join(cell_line_dir, f"{cell_line_name}_mutations.txt")

mut_subset.to_csv(output_csv, index=False)
mut_subset.to_csv(output_txt, index=False, sep=" ", header=False)

print("🎉 Saved mutation data to:")
print(f"   📁 {output_csv}")
print(f"   📁 {output_txt}")
print(f"✅ Total mutations extracted: {len(mut_subset)}")

