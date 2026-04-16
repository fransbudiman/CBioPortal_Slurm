#!/bin/bash

# Load required modules for bcftools
module load StdEnv/2023
module load gcc/12.3
module load bcftools/1.22

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
# Clean up existing processed files to ensure we only use newly filtered data
rm -rf $TEMP_DIR/processed_vcf $TEMP_DIR/filtered_vcf
mkdir -p $TEMP_DIR/processed_vcf
mkdir -p $TEMP_DIR/filtered_vcf

echo "=========================================="  >&2
echo "Starting PASS variant filtering with bcftools" >&2
echo "==========================================" >&2

# First try .vcf.gz files
for vcf in $VCF_DIR/*.vcf.gz; do
    if [ -f "$vcf" ]; then
        echo "Processing compressed VCF: $vcf..." >&2
        # Decompress to temp location first
        temp_vcf="${vcf%.gz}"
        gunzip -c "$vcf" > "$temp_vcf"
        
        # Filter for PASS variants only using bcftools
        sample_name=$(basename "$temp_vcf" .vcf)
        filtered_vcf="$TEMP_DIR/filtered_vcf/${sample_name}.filtered.vcf"
        echo "Filtering for PASS variants only..." >&2
        bcftools view -f PASS "$temp_vcf" > "$filtered_vcf"
        
        # Verify filtered VCF was created and has content
        if [ ! -f "$filtered_vcf" ]; then
            echo "ERROR: Filtered VCF not created: $filtered_vcf" >&2
            rm -f "$temp_vcf"
            continue
        fi
        
        variant_count=$(grep -v "^#" "$filtered_vcf" | wc -l)
        echo "  → Filtered to $variant_count PASS variants" >&2
        
        # Verify no non-PASS variants remain
        non_pass_count=$(grep -v "^#" "$filtered_vcf" | cut -f7 | grep -v "PASS" | wc -l)
        if [ "$non_pass_count" -gt 0 ]; then
            echo "  ERROR: Found $non_pass_count non-PASS variants after filtering!" >&2
            echo "  bcftools filtering failed. Aborting." >&2
            rm -f "$temp_vcf" "$filtered_vcf"
            exit 1
        else
            echo "  VERIFIED: All variants have PASS filter" >&2
        fi
        
        if [ "$variant_count" -eq 0 ]; then
            echo "  WARNING: No PASS variants found in $vcf" >&2
        fi
        
        # Process filtered VCF
        python $BIN_DIR/process_vcf.py --input-vcf "$filtered_vcf" --output-dir $TEMP_DIR/processed_vcf
        rm -f "$temp_vcf" "$filtered_vcf"
    fi
done

# Then try uncompressed .vcf files
for vcf in $VCF_DIR/*.vcf; do
    if [ -f "$vcf" ]; then
        echo "Processing uncompressed VCF: $vcf..." >&2
        
        # Filter for PASS variants only using bcftools
        sample_name=$(basename "$vcf" .vcf)
        filtered_vcf="$TEMP_DIR/filtered_vcf/${sample_name}.filtered.vcf"
        echo "Filtering for PASS variants only..." >&2
        bcftools view -f PASS "$vcf" > "$filtered_vcf"
        
        # Verify filtered VCF was created and has content
        if [ ! -f "$filtered_vcf" ]; then
            echo "ERROR: Filtered VCF not created: $filtered_vcf" >&2
            continue
        fi
        
        variant_count=$(grep -v "^#" "$filtered_vcf" | wc -l)
        echo "  → Filtered to $variant_count PASS variants" >&2
        
        # Verify no non-PASS variants remain
        non_pass_count=$(grep -v "^#" "$filtered_vcf" | cut -f7 | grep -v "PASS" | wc -l)
        if [ "$non_pass_count" -gt 0 ]; then
            echo "  ERROR: Found $non_pass_count non-PASS variants after filtering!" >&2
            echo "  bcftools filtering failed. Aborting." >&2
            rm -f "$filtered_vcf"
            exit 1
        else
            echo "  VERIFIED: All variants have PASS filter" >&2
        fi
        
        if [ "$variant_count" -eq 0 ]; then
            echo "  WARNING: No PASS variants found in $vcf" >&2
        fi
        
        # Process filtered VCF
        python $BIN_DIR/process_vcf.py --input-vcf "$filtered_vcf" --output-dir $TEMP_DIR/processed_vcf
        rm -f "$filtered_vcf"
    fi
done


mkdir -p $TEMP_DIR/vep_output
jid_vep=$($BIN_DIR/vep.sh -i $TEMP_DIR/processed_vcf -o $TEMP_DIR/vep_output -r $REF_DIR -s $STUDY_ID -f $REF_FASTA_PATH | awk '/jid:/ {print $2}')
echo "jid: $jid_vep"
