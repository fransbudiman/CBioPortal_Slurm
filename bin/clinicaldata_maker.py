# This script takes in a csv file with that contains the data from each clinical sample.
# The minimum required columns are: PATIENT_ID, SAMPLE_ID

import argparse
import os
import pandas as pd

parser = argparse.ArgumentParser(description='Generate clinical data files for CBioPortal.')
parser.add_argument('--input-tsv', required=True, help='Path to the input TSV file')
parser.add_argument('--project-dir', required=True, help='Path to the project directory')

args = parser.parse_args()
input_tsv = args.input_tsv
project_dir = args.project_dir

output_file_path = os.path.join(project_dir, "data_clinical_sample.txt")
df = pd.read_csv(input_tsv, sep="\t")

# Sanitize column names
df.columns = df.columns.str.strip()  # removes leading/trailing spaces
df.columns = df.columns.str.replace('\xa0', '')  # removes non-breaking spaces

# Only PATIENT_ID and SAMPLE_ID are required
required_columns = ["PATIENT_ID", "SAMPLE_ID"]
if not all(col in df.columns for col in required_columns):
    print(f"Available columns: {df.columns.tolist()}")
    raise ValueError(f"Input TSV must contain the following columns: {required_columns}")

# Define header descriptions for known columns
header_descriptions = {
    "PATIENT_ID": ("Patient Identifier", "Identifier to uniquely specify a patient.", "STRING", "1"),
    "SAMPLE_ID": ("Sample Identifier", "A unique sample identifier.", "STRING", "1"),
    "CANCER_TYPE": ("Cancer Type", "Cancer type.", "STRING", "1"),
    "CANCER_TYPE_DETAILED": ("Cancer Type Detailed", "Cancer type detailed.", "STRING", "1"),
    "ONCOTREE_CODE": ("Oncotree Code", "Oncotree code.", "STRING", "1")
}

# Build headers dynamically based on columns present in input
available_columns = df.columns.tolist()
line1_parts = []
line2_parts = []
line3_parts = []
line4_parts = []

for col in available_columns:
    if col in header_descriptions:
        desc = header_descriptions[col]
        line1_parts.append(desc[0])
        line2_parts.append(desc[1])
        line3_parts.append(desc[2])
        line4_parts.append(desc[3])
    else:
        # For unknown columns, use generic descriptions
        line1_parts.append(col.replace("_", " ").title())
        line2_parts.append(f"{col} data")
        line3_parts.append("STRING")
        line4_parts.append("1")

# Write dynamic headers to output file
with open(output_file_path, "w") as f:
    f.write("#" + "\t".join(line1_parts) + "\n")
    f.write("#" + "\t".join(line2_parts) + "\n")
    f.write("#" + "\t".join(line3_parts) + "\n")
    f.write("#" + "\t".join(line4_parts) + "\n")
    
# Write the output file
df.to_csv(output_file_path, sep="\t", index=False, mode='a')
print(f"Clinical data file created at: {output_file_path}")

