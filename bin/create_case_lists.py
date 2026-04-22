import pandas as pd
import argparse
import os

# Generate case list files for all available data types in cBioPortal study
parser = argparse.ArgumentParser(description='Generate case list files for CBioPortal.')
parser.add_argument('--project-dir', required=True, help='Path to the project directory')
args = parser.parse_args()
project_dir = args.project_dir

# Read study ID from meta_study.txt
with open(os.path.join(project_dir, "meta_study.txt"), 'r') as meta_file:
    for line in meta_file:
        if line.startswith("cancer_study_identifier:"):
            study_id = line.split(":")[1].strip()
            break

# Create case_lists directory
os.makedirs(os.path.join(project_dir, "case_lists"), exist_ok=True)

# ============================================================================
# 1. MUTATION DATA (data_mutations_extended.txt)
# ============================================================================
mutations_file = os.path.join(project_dir, "data_mutations_extended.txt")
if os.path.exists(mutations_file):
    df = pd.read_csv(mutations_file, sep="\t", comment='#')
    # Filter out empty or NA sample IDs
    case_list_ids = df["Tumor_Sample_Barcode"].dropna().drop_duplicates().tolist()
    case_list_ids = [x for x in case_list_ids if str(x).strip() != '']
    num_samples = len(case_list_ids)
    
    stable_id = study_id + "_sequenced"
    output_file = os.path.join(project_dir, "case_lists", "cases_sequenced.txt")
    
    with open(output_file, "w") as f:
        f.write(f"cancer_study_identifier: {study_id}\n")
        f.write(f"stable_id: {stable_id}\n")
        f.write(f"case_list_name: Sequenced samples\n")
        f.write(f"case_list_description: Sequenced samples ({num_samples} samples)\n")
        f.write(f"case_list_category: all_cases_with_mutation_data\n")
        f.write("case_list_ids: " + "\t".join(case_list_ids) + "\n")
    
    print(f"Mutation case list: {num_samples} samples → {output_file}")

# ============================================================================
# 2. STRUCTURAL VARIANT / FUSION DATA (data_sv.txt)
# ============================================================================
sv_file = os.path.join(project_dir, "data_sv.txt")
if os.path.exists(sv_file):
    df = pd.read_csv(sv_file, sep="\t", comment='#')
    # Extract unique Sample_Id values
    case_list_ids = df["Sample_Id"].dropna().drop_duplicates().tolist()
    case_list_ids = [x for x in case_list_ids if str(x).strip() != '']
    num_samples = len(case_list_ids)
    
    stable_id = study_id + "_sv"
    output_file = os.path.join(project_dir, "case_lists", "cases_sv.txt")
    
    with open(output_file, "w") as f:
        f.write(f"cancer_study_identifier: {study_id}\n")
        f.write(f"stable_id: {stable_id}\n")
        f.write(f"case_list_name: Samples with SV data\n")
        f.write(f"case_list_description: Samples with structural variant data ({num_samples} samples)\n")
        f.write(f"case_list_category: all_cases_with_sv_data\n")
        f.write("case_list_ids: " + "\t".join(case_list_ids) + "\n")
    
    print(f"SV/Fusion case list: {num_samples} samples → {output_file}")

# ============================================================================
# 3. RNA EXPRESSION DATA (data_expression.txt)
# ============================================================================
expression_file = os.path.join(project_dir, "data_expression.txt")
if os.path.exists(expression_file):
    # Read only the header to get sample IDs
    with open(expression_file, 'r') as f:
        header_line = f.readline().strip()
    
    # Split header and skip first two columns (Hugo_Symbol, Entrez_Gene_Id)
    columns = header_line.split('\t')
    case_list_ids = [col for col in columns[2:] if col.strip()]  # Skip first 2 columns
    num_samples = len(case_list_ids)
    
    stable_id = study_id + "_rna_seq_mrna"
    output_file = os.path.join(project_dir, "case_lists", "cases_rna_seq_mrna.txt")
    
    with open(output_file, "w") as f:
        f.write(f"cancer_study_identifier: {study_id}\n")
        f.write(f"stable_id: {stable_id}\n")
        f.write(f"case_list_name: Samples with mRNA data (RNA Seq)\n")
        f.write(f"case_list_description: Samples with mRNA expression data ({num_samples} samples)\n")
        f.write(f"case_list_category: all_cases_with_mrna_rnaseq_data\n")
        f.write("case_list_ids: " + "\t".join(case_list_ids) + "\n")
    
    print(f"RNA expression case list: {num_samples} samples → {output_file}")

print(f"\nCase lists generation complete for study: {study_id}")