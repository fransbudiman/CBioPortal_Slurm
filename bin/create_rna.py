# This script will create the RNA expression data and metadata files for cBioPortal
import argparse
import os
import pandas as pd

import yaml

with open(os.path.join(os.path.dirname(__file__), '../config/config.yaml'), 'r') as config_file:
    config = yaml.safe_load(config_file)

rna_dir = config.get('rna_dir')

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
metadata_output_path = 
with open()