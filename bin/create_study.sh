#!/bin/bash

while getopts ":i:n:d:m:t:D:" opt; do
  case $opt in
    i) STUDY_ID="$OPTARG"
    ;;
    n) STUDY_NAME="$OPTARG"
    ;;
    d) STUDY_DESC="$OPTARG"
    ;;
    m) MAF_DIR="$OPTARG"
    ;;
    t) TSV_FILE="$OPTARG"
    ;;
    D) DEPENDENCY="$OPTARG"
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
with open('$CONFIG_FILE', 'r') as f:
    config = yaml.safe_load(f)
    for key in ['work_dir', 'bin_dir']:
        if config.get(key):
            print(f'{key}={config[key]}')
")

# Build absolute paths
WORK_DIR="$PROJECT_ROOT/$work_dir"
BIN_DIR="$PROJECT_ROOT/$bin_dir"

REF_DIR="$WORK_DIR/references"
RESULT_DIR="$WORK_DIR/results"
STUDY_DIR="$RESULT_DIR/${STUDY_ID}_cbioportal"
TEMP_DIR="$RESULT_DIR/${STUDY_ID}_temp"
TOOLS_DIR="$WORK_DIR/tools"

# Merge MAF files
# conda install pandas numpy
# should already be in the cbioportal env which is already activated in the setup script

if [ -n "$DEPENDENCY" ]; then
  echo "Submitting job with dependency on job ID $DEPENDENCY"
  DEPENDENCY_TEXT="--dependency=afterok:$DEPENDENCY"
  sbatch --export=PATHS_DIR=$PATHS_DIR $DEPENDENCY_TEXT ./create_study_slurm.sh -i "$STUDY_ID" -n "$STUDY_NAME" -d "$STUDY_DESC" -m "$MAF_DIR" -t "$TSV_FILE"
else
  echo "No dependency, running script directly"
  python merge_maf.py --input-dir $MAF_DIR --output-file $STUDY_DIR/data_mutations_extended.txt
  python metadata_maker.py --study-identifier "$STUDY_ID" --name "$STUDY_NAME" --project-dir "$STUDY_DIR" --description "$STUDY_DESC"
  python clinicaldata_maker.py --input-tsv "$TSV_FILE" --project-dir "$STUDY_DIR"
  python cases_sequenced.py --project-dir "$STUDY_DIR"
fi



