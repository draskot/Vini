import os
import pandas as pd

# === Step 0: Read cell line name from environment variable ===
cell_line_name = os.getenv("cell_line")
if not cell_line_name:
    raise ValueError("Environment variable 'cell_line' is not set. Example: export cell_line=PANC-1")

print(f"🔍 Extracting expression for cell line: {cell_line_name}")

# === Step 1: Set directories ===
vini_dir = os.path.dirname(os.path.abspath(__file__))
depmap_dir = os.getenv("DEPMAP_DIR", os.path.join(vini_dir, "database"))
cell_lines_dir = os.path.join(depmap_dir, "cell_lines")
cell_line_dir = os.path.join(cell_lines_dir, cell_line_name, "expressions")

os.makedirs(cell_line_dir, exist_ok=True)

print(f"📁 Using DepMap data from: {depmap_dir}")
print(f"📂 Saving output to: {cell_line_dir}")

# === Step 2: Lookup DepMap ID ===
model_file = os.path.join(depmap_dir, "Model.csv")
model_df = pd.read_csv(model_file)

cell_line_col = model_df.columns[2]
matches = model_df[model_df[cell_line_col].str.contains(cell_line_name, case=False, na=False)]

if matches.empty:
    raise ValueError(f"No match found for {cell_line_name} in {model_file}")

depmap_id = matches.iloc[0, 0]
print(f"✅ Found DepMap ID for {cell_line_name}: {depmap_id}")

# === Step 3: Load expression data ===
input_file = os.path.join(depmap_dir, "OmicsExpressionTPMLogp1HumanProteinCodingGenes.csv")
output_csv = os.path.join(cell_line_dir, f"{cell_line_name}_{depmap_id}_expression.csv")
output_txt = os.path.join(cell_line_dir, f"{cell_line_name}_expression.txt")

meta_cols = ["ModelID"]
df_meta = pd.read_csv(input_file, usecols=meta_cols)
if depmap_id not in df_meta["ModelID"].values:
    raise ValueError(f"{depmap_id} not found in ModelID column of {input_file}")

print(f"📖 Loading full row for {depmap_id} (this may take a minute)...")
row_df = pd.read_csv(
    input_file,
    skiprows=lambda x: x != 0 and df_meta.iloc[x - 1]["ModelID"] != depmap_id,
)

row_df = row_df.loc[:, ~row_df.columns.str.startswith("Unnamed")]

# === Step 4: Transform and clean ===
row_transposed = row_df.drop(
    columns=["SequencingID", "ModelID", "IsDefaultEntryForModel", "ModelConditionID", "IsDefaultEntryForMC"],
    errors="ignore"
).T
row_transposed.reset_index(inplace=True)
row_transposed.columns = ["Gene", "Expression_logTPM+1"]
row_transposed["Gene"] = row_transposed["Gene"].str.replace(r"\s*\(\d+\)", "", regex=True)

# === Step 5: Save results ===
row_transposed.to_csv(output_csv, index=False)
row_transposed.to_csv(output_txt, index=False, sep=" ", header=False)

print("🎉 Saved expression data to:")
print(f"   📁 {output_csv}")
print(f"   📁 {output_txt}")
print(f"✅ Total genes extracted: {len(row_transposed)}")

