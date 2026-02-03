# This script will create the RNA expression data and metadata files for cBioPortal
import argparse
import os
import pandas as pd
from pathlib import Path
import yaml

# Get project root and config
PROJECT_ROOT = Path(__file__).resolve().parent.parent
CONFIG_FILE = PROJECT_ROOT / 'config' / 'config.yaml'

with open(CONFIG_FILE, 'r') as config_file:
    config = yaml.safe_load(config_file)

rna_dir = config.get('rna_dir')
study_id = config.get('study_id')
work_dir = PROJECT_ROOT / config.get('work_dir', 'work')

# Build output path: work/results/{study_id}_cbioportal
output_directory = work_dir / 'results' / f'{study_id}_cbioportal'
os.makedirs(output_directory, exist_ok=True)

# check if rna_dir exists
if not rna_dir or not os.path.exists(rna_dir):
    print("RNA directory not specified or does not exist. Skipping RNA data creation.")
    exit(0)

# check if sample_info.tsv exists in rna_dir
sample_info_path = os.path.join(rna_dir, 'sample_info.tsv')
if not os.path.exists(sample_info_path):
    print(f"sample_info.tsv not found in {rna_dir}. Skipping RNA data creation.")
    exit(0)

# create metadata file for RNA data
metadata_output_path = output_directory / 'meta_expression.txt'

metadata_lines = [
    f"cancer_study_identifier: {study_id}",
    "genetic_alteration_type: MRNA_EXPRESSION",
    "datatype: CONTINUOUS",
    "stable_id: rna_seq_mrna",
    "show_profile_in_analysis_tab: false",
    "profile_name: mRNA expression",
    "profile_description: Expression levels",
    "data_filename: data_expression.txt"
]
with open(metadata_output_path, 'w') as meta_file:
    meta_file.write("\n".join(metadata_lines))
print(f"RNA expression metadata file created at: {metadata_output_path}")


# create data_expression.txt

# outer join and loop through all txt files in rna_dir
expression_df = pd.DataFrame()

for file in os.listdir(rna_dir):
    if file.endswith('.txt'):
        file_path = os.path.join(rna_dir, file)
        sample_df = pd.read_csv(file_path, sep="\t", index_col=0)
        expression_df = pd.concat([expression_df, sample_df], axis=1, join='outer')

# Rename gene column to 'Hugo_Symbol'
expression_df.index.name = 'Hugo_Symbol'
# Fill NaN with 'NA'
expression_df.fillna('NA', inplace=True)

# Write to data_expression.txt
data_expression_path = output_directory / 'data_expression.txt'
expression_df.to_csv(data_expression_path, sep="\t")
print(f"RNA expression data file created at: {data_expression_path}")

        