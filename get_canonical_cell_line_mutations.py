#!/usr/bin/env python3
import os
import pandas as pd
import requests

# === Step 0: Determine KEGG cancer pathway ===
CANCER_PATHWAY = os.getenv("CANCER_PATHWAY")
if not CANCER_PATHWAY:
    cancer_type = os.getenv("cancer_type")
    if not cancer_type:
        raise ValueError("Environment variable 'cancer_type' is not set. Example: export cancer_type=05212")
    CANCER_PATHWAY = f"hsa{cancer_type}"

print(f"📁 Using KEGG pathway: {CANCER_PATHWAY}")

# === Step 1: Read cell line name from Bash variable ===
cell_line_name = os.getenv("cell_line")
if not cell_line_name:
    raise ValueError("Environment variable 'cell_line' is not set. Example: export cell_line=PANC-1")
print(f"🔍 Extracting mutations for cell line: {cell_line_name}")

# === Step 2: Determine DEPMAP_DIR and output directories ===
DEPMAP_DIR = os.getenv("DEPMAP_DIR")
if not DEPMAP_DIR:
    raise ValueError("Environment variable 'DEPMAP_DIR' is not set.")
cell_line_dir = os.path.join(DEPMAP_DIR, "cell_lines", cell_line_name)
mut_dir = os.path.join(cell_line_dir, "mutations")
os.makedirs(mut_dir, exist_ok=True)
print(f"📂 Saving output to: {mut_dir}")

# === Step 3: Lookup ModelID in Model.csv ===
model_file = os.path.join(DEPMAP_DIR, "Model.csv")
model_df = pd.read_csv(model_file)
cell_line_col = model_df.columns[2]
matches = model_df[model_df[cell_line_col].str.contains(cell_line_name, case=False, na=False)]
if matches.empty:
    raise ValueError(f"No match found for {cell_line_name} in {model_file}")
depmap_id = matches.iloc[0, 0]
print(f"✅ Found ModelID for {cell_line_name}: {depmap_id}")

# === Step 4: Download canonical gene list from KEGG ===
kegg_url = f"https://rest.kegg.jp/link/hsa/{CANCER_PATHWAY}"
resp = requests.get(kegg_url)
if resp.status_code != 200:
    raise RuntimeError(f"Failed to fetch KEGG pathway {CANCER_PATHWAY}. Status code: {resp.status_code}")

# Parse KEGG response
canonical_genes = []
for line in resp.text.strip().split("\n"):
    _, gene_entry = line.split("\t")
    # KEGG gene entry format: hsa:1234
    canonical_genes.append(gene_entry.split(":")[1])

canonical_genes = set(canonical_genes)
print(f"✅ Retrieved {len(canonical_genes)} canonical genes from {CANCER_PATHWAY}")

# === Step 5: Load mutation data ===
mutation_file = os.path.join(DEPMAP_DIR, "OmicsSomaticMutations.csv")
mut_df = pd.read_csv(mutation_file, low_memory=False)

# Filter by ModelID and canonical genes
cell_mut_df = mut_df[mut_df["ModelID"] == depmap_id]
# Map HugoSymbol to EntrezGeneID if available
cell_mut_df = cell_mut_df[cell_mut_df["EntrezGeneID"].isin(map(int, canonical_genes))]

print(f"✅ Found {len(cell_mut_df)} canonical mutations for {cell_line_name} ({depmap_id})")

# === Step 6: Save outputs ===
output_csv = os.path.join(mut_dir, f"{cell_line_name}_{depmap_id}_mutations.csv")
output_txt = os.path.join(mut_dir, f"{cell_line_name}_mutations.txt")

cell_mut_df.to_csv(output_csv, index=False)
cell_mut_df.to_csv(output_txt, index=False, sep=" ", header=False)

print("🎉 Saved mutation data to:")
print(f"   📁 {output_csv}")
print(f"   📁 {output_txt}")

