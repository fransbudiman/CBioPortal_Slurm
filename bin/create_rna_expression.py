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
