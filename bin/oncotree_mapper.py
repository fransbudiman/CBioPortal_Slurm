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

# Add stub columns for oncotree mapping (TODO: implement actual mapping)
# These are required by cBioPortal clinical data validation
if 'CANCER_TYPE' not in df.columns:
    df['CANCER_TYPE'] = 'Tissue'

if 'CANCER_TYPE_DETAILED' not in df.columns:
    df['CANCER_TYPE_DETAILED'] = 'Tissue'

if 'ONCOTREE_CODE' not in df.columns:
    df['ONCOTREE_CODE'] = 'TISSUE'

# Write the updated TSV
df.to_csv(output_tsv, sep='\t', index=False)

print(f"Oncotree mapping completed (stub values added). Output: {output_tsv}")

