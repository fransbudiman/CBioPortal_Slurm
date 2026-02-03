#!/bin/bash

# Make sure necessary directories exist and download reference files if needed

while getopts ":i:r:" opt; do
  case $opt in
    i) STUDY_ID="$OPTARG"
    ;;
    r) REF_FASTA="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# Calculate project root and load config
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}").." &> /dev/null && pwd)"
CONFIG_FILE="$PROJECT_ROOT/config/config.yaml"

# Parse YAML and set path variables
eval $(python3 -c "
import yaml
import shlex
with open('$CONFIG_FILE', 'r') as f:
    config = yaml.safe_load(f)
    for key in ['work_dir']:
        if config.get(key):
            print(f'{key}={shlex.quote(str(config[key]))}')
")

# Build absolute paths
WORK_DIR="$PROJECT_ROOT/$work_dir"

REF_DIR="$WORK_DIR/references"
RESULT_DIR="$WORK_DIR/results"
TOOLS_DIR="$WORK_DIR/tools"
STUDY_DIR="$RESULT_DIR/${STUDY_ID}_cbioportal"
TEMP_DIR="$RESULT_DIR/${STUDY_ID}_temp"

mkdir -p $REF_DIR $RESULT_DIR $TOOLS_DIR $STUDY_DIR $TEMP_DIR

module load samtools
module load htslib

if [ $REF_FASTA = "hg19" ]; then
    if [ -f "$REF_DIR/hg19.fa.gz" ] && [ -f "$REF_DIR/hg19.fa.gz.fai" ]; then
        echo "hg19 reference already exists."
    else
        echo "Downloading hg19 reference..."
        wget http://hgdownload.cse.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz
        mv hg19.fa.gz $REF_DIR/hg19.fa.gz
        gunzip $REF_DIR/hg19.fa.gz
        bgzip $REF_DIR/hg19.fa
        samtools faidx $REF_DIR/hg19.fa.gz
    fi

elif [ $REF_FASTA = "hg38" ]; then
    if [ -f "$REF_DIR/hg38.fa.gz" ] && [ -f "$REF_DIR/hg38.fa.gz.fai" ]; then
        echo "hg38 reference already exists."
    else
        echo "Downloading hg38 reference..."
        wget http://hgdownload.cse.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
        mv hg38.fa.gz $REF_DIR/hg38.fa.gz
        gunzip $REF_DIR/hg38.fa.gz
        bgzip $REF_DIR/hg38.fa
        samtools faidx $REF_DIR/hg38.fa.gz
    fi

fi

if [ ! -d "$PROJECT_ROOT/env" ] || [ -z "$(ls -A $PROJECT_ROOT/env)" ]; then
    echo "Creating virtual environment..."
    python3 -m venv $PROJECT_ROOT/env
    source $PROJECT_ROOT/env/bin/activate
    pip install --upgrade pip
    pip install pandas numpy
else
    echo "Virtual environment already exists."
    source $PROJECT_ROOT/env/bin/activate
fi