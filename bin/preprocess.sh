#!/bin/bash

while getopts ":i:v:r:" opt; do
  case $opt in
    i) STUDY_ID="$OPTARG"
    ;;
    v) VCF_DIR="$OPTARG"
    ;;
    r) REF_FASTA="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# Calculate project root and load config
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &> /dev/null && pwd)"
CONFIG_FILE="$PROJECT_ROOT/config/config.yaml"

# Parse YAML and set path variables
eval $(python3 -c "
import yaml
import shlex
with open('$CONFIG_FILE', 'r') as f:
    config = yaml.safe_load(f)
    for key in ['work_dir', 'bin_dir', 'env_dir']:
        if config.get(key):
            print(f'{key}={shlex.quote(str(config[key]))}')
")

# Build absolute paths
WORK_DIR="$PROJECT_ROOT/$work_dir"
BIN_DIR="$PROJECT_ROOT/$bin_dir"
ENV_DIR="$PROJECT_ROOT/$env_dir"

$BIN_DIR/setup.sh -i $STUDY_ID -r $REF_FASTA

# Storing all FASTA references
REF_DIR="$WORK_DIR/references"
# Storing all result
RESULT_DIR="$WORK_DIR/results"
# Storing all tools
TOOLS_DIR="$WORK_DIR/tools"
# Final project directory to upload to CBioPortal
STUDY_DIR="$RESULT_DIR/${STUDY_ID}_cbioportal"
# Temporary directory for intermediate files (delete after upload)
TEMP_DIR="$RESULT_DIR/${STUDY_ID}_temp"


if [ $REF_FASTA = "hg19" ]; then
    REF_FASTA_PATH="$REF_DIR/hg19.fa.gz"
elif [ $REF_FASTA = "hg38" ]; then
    REF_FASTA_PATH="$REF_DIR/hg38.fa.gz"
else
    REF_FASTA_PATH="$REF_FASTA"
fi

# Process VCF files to change name from TM to SGT
mkdir -p $TEMP_DIR/processed_vcf

# First try .vcf.gz files
for vcf in $VCF_DIR/*.vcf.gz; do
    if [ -f "$vcf" ]; then
        echo "Processing compressed VCF: $vcf..."
        # Decompress to temp location first
        temp_vcf="${vcf%.gz}"
        gunzip -c "$vcf" > "$temp_vcf"
        python $BIN_DIR/process_vcf.py --input-vcf "$temp_vcf" --output-dir $TEMP_DIR/processed_vcf
        rm -f "$temp_vcf"
    fi
done

# Then try uncompressed .vcf files
for vcf in $VCF_DIR/*.vcf; do
    if [ -f "$vcf" ]; then
        echo "Processing uncompressed VCF: $vcf..."
        python $BIN_DIR/process_vcf.py --input-vcf "$vcf" --output-dir $TEMP_DIR/processed_vcf
    fi
done


mkdir -p $TEMP_DIR/vep_output
jid_vep=$($BIN_DIR/vep.sh -i $TEMP_DIR/processed_vcf -o $TEMP_DIR/vep_output -r $REF_DIR -s $STUDY_ID -f $REF_FASTA_PATH | awk '/jid:/ {print $2}')
echo "jid: $jid_vep"
