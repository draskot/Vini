import os
import pandas as pd

# === Step 0: Read cell line name from Bash variable ===
cell_line_name = os.getenv("cell_line")
if not cell_line_name:
    raise ValueError("Environment variable 'cell_line' is not set. Example: export cell_line=PANC-1")

print(f"🔍 Extracting expression for cell line: {cell_line_name}")

# === Step 1: Lookup DepMap ID in Model.csv ===
model_file = os.path.join("database", "Model.csv")
model_df = pd.read_csv(model_file)

# Adjust the column index for cell line name (3rd column)
cell_line_col = model_df.columns[2]
matches = model_df[model_df[cell_line_col].str.contains(cell_line_name, case=False, na=False)]

if matches.empty:
    raise ValueError(f"No match found for {cell_line_name} in {model_file}")

depmap_id = matches.iloc[0, 0]  # first column is DepMap ID
print(f"✅ Found DepMap ID for {cell_line_name}: {depmap_id}")

# === Step 2: Extract expression from OmicsExpressionTPMLogp1HumanProteinCodingGenes.csv ===
input_file = os.path.join("database", "OmicsExpressionTPMLogp1HumanProteinCodingGenes.csv")
output_csv = f"{cell_line_name}_{depmap_id}_expression.csv"
#output_txt = f"{cell_line_name}_{depmap_id}_expression.txt"
output_txt = f"{cell_line_name}_expression.txt"

# Step 2a: Read only ModelID column to locate the row
meta_cols = ["ModelID"]
df_meta = pd.read_csv(input_file, usecols=meta_cols)
if depmap_id not in df_meta["ModelID"].values:
    raise ValueError(f"{depmap_id} not found in ModelID column of {input_file}")

# Step 2b: Load full row for the target model
print(f"📖 Loading full row for {depmap_id} (this may take a minute)...")
row_df = pd.read_csv(
    input_file,
    skiprows=lambda x: x != 0 and df_meta.iloc[x - 1]["ModelID"] != depmap_id,
)

# Drop any unnamed columns (like "Unnamed: 0")
row_df = row_df.loc[:, ~row_df.columns.str.startswith("Unnamed")]

# Step 2c: Transpose and clean
row_transposed = row_df.drop(columns=["SequencingID", "ModelID", "IsDefaultEntryForModel",
                                      "ModelConditionID", "IsDefaultEntryForMC"], errors="ignore").T
row_transposed.reset_index(inplace=True)
row_transposed.columns = ["Gene", "Expression_logTPM+1"]

# Remove numeric IDs from gene names (e.g. "KRAS (3845)" → "KRAS")
row_transposed["Gene"] = row_transposed["Gene"].str.replace(r"\s*\(\d+\)", "", regex=True)

# === Step 3: Save outputs ===
row_transposed.to_csv(output_csv, index=False)                   # comma-separated CSV
row_transposed.to_csv(output_txt, index=False, sep=" ", header=False)  # space-separated TXT for VINI

print("🎉 Saved expression data to:")
print(f"   📁 {output_csv}  (comma-separated)")
print(f"   📁 {output_txt}  (space-separated for VINI)")
print(f"✅ Total genes extracted: {len(row_transposed)}")

