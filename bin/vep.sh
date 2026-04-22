#! /bin/bash

while getopts ":i:o:r:s:f:" opt; do
  case $opt in
    i) VCF_DIR="$OPTARG"
    ;;
    o) OUTPUT_DIR="$OPTARG"
    ;;
    r) REF_DIR="$OPTARG"
    ;;
    s) STUDY_ID="$OPTARG"
    ;;
    f) FASTA_FILE="$OPTARG"
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
    for key in ['work_dir', 'env_dir']:
        if config.get(key):
            print(f'{key}={shlex.quote(str(config[key]))}')
")

# Build absolute paths
WORK_DIR="$PROJECT_ROOT/$work_dir"
ENV_DIR="$PROJECT_ROOT/$env_dir"

# Default to hg19/GRCh37 (no user input needed)
CACHE_BUILD="hg19/GRCh37"
ASSEMBLY="GRCh37"
echo "Using genome build: hg19/GRCh37" >&2

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd $SCRATCH/cbioportal_projects/tools
if [ ! -f vep.sif ]; then
    singularity pull --name vep.sif docker://ensemblorg/ensembl-vep
fi

# Install VEP cache if needed (ASSEMBLY already set from auto-detection above)
if [ "$CACHE_BUILD" = "hg19/GRCh37" ]; then
    if compgen -G "$REF_DIR/homo_sapiens/*GRCh37*" > /dev/null; then
        echo "Cache for $CACHE_BUILD already exists." >&2
    else
        echo "Installing VEP cache for $CACHE_BUILD..." >&2
        singularity exec --bind $REF_DIR:$REF_DIR vep.sif INSTALL.pl -c $REF_DIR -a cf -s homo_sapiens -y GRCh37
    fi
elif [ "$CACHE_BUILD" = "hg38/GRCh38" ]; then
    if compgen -G "$REF_DIR/homo_sapiens/*GRCh38*" > /dev/null; then
        echo "Cache for $CACHE_BUILD already exists." >&2
    else
        echo "Installing VEP cache for $CACHE_BUILD..." >&2
        singularity exec --bind $REF_DIR:$REF_DIR vep.sif INSTALL.pl -c $REF_DIR -a cf -s homo_sapiens -y GRCh38
    fi
fi

echo "=========================================="  >&2
echo "VEP Input Verification" >&2
echo "=========================================="  >&2
echo "Input VCF directory: $VCF_DIR" >&2

# Verify we're using filtered/processed VCFs, not original raw data
if [[ "$VCF_DIR" == *"/processed_vcf"* ]]; then
    echo "VERIFIED: Using processed VCF directory (filtered data)" >&2
else
    echo "WARNING: Input directory does not appear to be processed_vcf" >&2
    echo "Expected path to contain 'processed_vcf', got: $VCF_DIR" >&2
fi

# Quick check: verify VCFs contain only PASS variants
FIRST_VCF=$(ls $VCF_DIR/*.vcf 2>/dev/null | head -1)
if [ -f "$FIRST_VCF" ]; then
    NON_PASS=$(grep -v "^#" "$FIRST_VCF" | cut -f7 | grep -v "PASS" | wc -l)
    TOTAL=$(grep -v "^#" "$FIRST_VCF" | wc -l)
    echo "Sample check on $(basename $FIRST_VCF):" >&2
    echo "  Total variants: $TOTAL" >&2
    echo "  Non-PASS variants: $NON_PASS" >&2
    if [ "$NON_PASS" -gt 0 ]; then
        echo "  ERROR: Non-PASS variants detected in input VCFs!" >&2
        echo "  VEP should only process PASS-filtered variants." >&2
        exit 1
    else
        echo "  VERIFIED: All variants have PASS filter" >&2
    fi
fi
echo "==========================================" >&2

# run as job array
FILE_NO=$(ls $VCF_DIR/*.vcf | wc -l)
ls $VCF_DIR/*.vcf > $VCF_DIR/vcf_files.txt
mkdir -p $OUTPUT_DIR
for vcf in $VCF_DIR/*.vcf; do
    SAMPLE_NAME=$(basename ${vcf%.vcf})
    touch $OUTPUT_DIR/${SAMPLE_NAME}.vep.vcf
done

LOG_DIR="$PROJECT_ROOT/work/logs"
mkdir -p $LOG_DIR

jid=$(sbatch --export=PATHS_DIR=$PATHS_DIR --array=1-$FILE_NO --output=$LOG_DIR/vep_%A_%a.out $SCRIPT_DIR/vep_slurm.sh -i $VCF_DIR/vcf_files.txt -o $OUTPUT_DIR -r $REF_DIR -s $STUDY_ID -a $ASSEMBLY -f $FASTA_FILE | awk '{print $4}')
echo "jid: $jid"