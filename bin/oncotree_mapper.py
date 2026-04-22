# this script will ensure proper header and formatting of sample_info.tsv files
# this script will map the cancer type description from the pathologist
# and match it to the oncotree codes for cBioPortal using the oncotree API and fuzzy matching

import argparse
import pandas as pd

# Parse command-line arguments
parser = argparse.ArgumentParser(description='Map cancer types to oncotree codes.')
parser.add_argument('--input-tsv', required=True, help='Path to input TSV file.')
parser.add_argument('--output-tsv', required=True, help='Path to output TSV file.')

args = parser.parse_args()
input_tsv = args.input_tsv
output_tsv = args.output_tsv

# Read the input TSV
df = pd.read_csv(input_tsv, sep='\t')

# Check if CANCER_TYPE column exists and has any non-empty values
cancer_type_has_data = False
if 'CANCER_TYPE' in df.columns:
    # Check if any values are not NaN/None/empty string
    cancer_type_has_data = df['CANCER_TYPE'].notna().any() and (df['CANCER_TYPE'].astype(str).str.strip() != '').any()

if cancer_type_has_data:
    # Cancer type data exists but oncotree mapping is not implemented yet
    import sys
    print("\n" + "="*70, file=sys.stderr)
    print("ERROR: CANCER_TYPE data found but oncotree mapping not implemented!", file=sys.stderr)
    print("="*70, file=sys.stderr)
    print(f"\nInput file: {input_tsv}", file=sys.stderr)
    print(f"Found {df['CANCER_TYPE'].notna().sum()} samples with cancer type data:", file=sys.stderr)
    print("\nSample of cancer types found:", file=sys.stderr)
    print(df[df['CANCER_TYPE'].notna()][['SAMPLE_ID', 'CANCER_TYPE']].head(10).to_string(index=False), file=sys.stderr)
    print("\nACTION REQUIRED:", file=sys.stderr)
    print("  1. Remove CANCER_TYPE column from sample_info.tsv files, OR", file=sys.stderr)
    print("  2. Implement oncotree_mapper.py to map cancer types to ONCOTREE_CODE", file=sys.stderr)
    print("\nPipeline stopped to prevent data loss.", file=sys.stderr)
    print("="*70 + "\n", file=sys.stderr)
    sys.exit(1)

# All cancer type entries are blank/missing - remove oncotree columns
columns_to_remove = ['CANCER_TYPE', 'CANCER_TYPE_DETAILED', 'ONCOTREE_CODE']
for col in columns_to_remove:
    if col in df.columns:
        df = df.drop(columns=[col])

# Write the updated TSV (only SAMPLE_ID and PATIENT_ID)
df.to_csv(output_tsv, sep='\t', index=False)

print(f"Oncotree mapping skipped (no cancer type data). Output: {output_tsv}")

