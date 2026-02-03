# This script will merge all the sample_info.tsv files from different data type directories
# into a unified sample_info_unified.tsv for clinical data creation.

import argparse
import os
import pandas as pd
import yaml

# read the config file to get the data type directories
with open(os.path.join(os.path.dirname(__file__), '../config/config.yaml'), 'r') as config_file:
    config = yaml.safe_load(config_file)
rna_dir = config.get('rna_dir')
fusion_dir = config.get('fusion_dir')
vcf_dir = config.get('vcf_dir')

# check if the directories exist and collect sample_info.tsv paths
sample_info_files = []
for data_dir in [rna_dir, fusion_dir, vcf_dir]:
    if data_dir and os.path.exists(data_dir):
        sample_info_path = os.path.join(data_dir, 'sample_info.tsv')
        if os.path.exists(sample_info_path):
            sample_info_files.append(sample_info_path)

if not sample_info_files:
    import sys
    print("ERROR: No sample_info.tsv files found in the specified data directories.", file=sys.stderr)
    print("Please ensure each data directory (vcf_dir, fusion_dir, rna_dir) contains a sample_info.tsv file.", file=sys.stderr)
    sys.exit(1)

# merge all sample_info.tsv files
merged_df = pd.DataFrame()
for file_path in sample_info_files:
    df = pd.read_csv(file_path, sep="\t")
    merged_df = pd.concat([merged_df, df], ignore_index=True)

# remove duplicate entries based on SAMPLE_ID
merged_df.drop_duplicates(subset=['SAMPLE_ID'], inplace=True)

# write the unified sample_info_unified.tsv
# create temp directory for the study if it doesn't exist
study_id = config.get('study_id', 'default_study')
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
work_dir = os.path.join(project_root, config.get('work_dir', 'work'))
temp_dir = os.path.join(work_dir, 'results', f'{study_id}_temp')
os.makedirs(temp_dir, exist_ok=True)

metadata_output_path = os.path.abspath(os.path.join(temp_dir, 'sample_info_unified.tsv'))
merged_df.to_csv(metadata_output_path, sep="\t", index=False)

# Print the absolute path for use in driver.sh
print(metadata_output_path)
