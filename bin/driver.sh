#!/bin/bash

# This script will auto run the whole pipeline from vcf samples directory to cbioportal study directory
# Configure your study in config/config.yaml, then simply run: ./bin/driver.sh

# Calculate project root dynamically
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}").." &> /dev/null && pwd)"
CONFIG_FILE="$PROJECT_ROOT/config/config.yaml"

echo "Loading configuration from config.yaml..."

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: config.yaml not found at $CONFIG_FILE"
    echo "Please create and configure config/config.yaml before running."
    exit 1
fi

# Parse YAML and set variables
eval $(python3 -c "
import yaml
with open('$CONFIG_FILE', 'r') as f:
    config = yaml.safe_load(f)
    for key, value in config.items():
        if value:
            print(f'{key}={value}')
")

# Build absolute paths from config
WORK_DIR="$PROJECT_ROOT/$work_dir"
BIN_DIR="$PROJECT_ROOT/$bin_dir"
PATHS_DIR="$PROJECT_ROOT/$config_dir"
ENV_DIR="$PROJECT_ROOT/$env_dir"
LIB_DIR="$PROJECT_ROOT/$lib_dir"

STUDY_ID="$study_id"
VCF_DIR="$vcf_dir"
REF_TYPE="$reference_type"
STUDY_NAME="$study_name"
STUDY_DESC="$study_description"
FUSION_DIR="$fusion_dir"
RNA_DIR="$rna_dir"

# Validate required parameters
if [ -z "$STUDY_ID" ] || [ -z "$VCF_DIR" ] || [ -z "$REF_TYPE" ] || [ -z "$STUDY_NAME" ] || [ -z "$STUDY_DESC" ]; then
    echo "Error: Missing required configuration in config.yaml"
    echo "Please ensure all required fields are set in config/config.yaml"
    exit 1
fi

echo "Configuration loaded successfully:"
echo "  Study ID: $STUDY_ID"
echo "  VCF Directory: $VCF_DIR"
echo "  Reference: $REF_TYPE"
echo "  Study Name: $STUDY_NAME"
echo "  RNA Directory: $RNA_DIR"
echo "  Fusion Directory: $FUSION_DIR"
VEP_DIR="$WORK_DIR/results/${STUDY_ID}_temp/vep_output"
MAF_DIR="$WORK_DIR/results/${STUDY_ID}_temp/maf_files"
echo "VEP Directory: $VEP_DIR"
echo "MAF Directory: $MAF_DIR"

REF_DIR="$WORK_DIR/references"

mkdir -p "$VEP_DIR"
mkdir -p "$MAF_DIR"

jid_vep=$($BIN_DIR/preprocess.sh -i "$STUDY_ID" -v "$VCF_DIR" -r "$REF_TYPE" | awk '/jid:/ {print $2}')
echo "Job ID for VEP: $jid_vep"

jid_vcf2maf=$($BIN_DIR/vcf2maf.sh -i "$VEP_DIR" -p "$STUDY_ID" -r "$REF_DIR/hg19.fa.gz" -D "$jid_vep" | awk '/jid:/ {print $2}')
echo "Job ID for VCF2MAF: $jid_vcf2maf"

# since we deprecated sample_info_tsv, we won't pass it to create_study.sh.
# but we need new logic to merge all sample_info.tsv from each data type directory.
# to create a unified sample_info_unified.tsv for clinical data creation.
# TO IMPLEMENT AS SOON AS POSSIBLE!


$BIN_DIR/create_study.sh -i "$STUDY_ID" -n "$STUDY_NAME" -d "$STUDY_DESC" -m "$MAF_DIR" -t "$TSV_FILE" -D "$jid_vcf2maf"

if [ -n $FUSION_DIR ]; then
    echo "Creating fusion files"
    python $BIN_DIR/create_fusion.py --input-directory "$FUSION_DIR" --output-directory "$WORK_DIR/results/${STUDY_ID}_cbioportal" --study-id "$STUDY_ID"
else
    echo "No fusion directory provided, skipping fusion data creation."
fi
