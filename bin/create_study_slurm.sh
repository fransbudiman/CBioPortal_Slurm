#!/bin/bash

#SBATCH --job-name=create_study
#SBATCH --time=00:15:00
#SBATCH --cpus-per-task=4
#SBATCH --nodes=1

while getopts ":i:n:d:m:t:" opt; do
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
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# Calculate project root and load config
# Note: In SLURM jobs, PATHS_DIR is passed via --export
if [ -z "$PATHS_DIR" ]; then
  PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &> /dev/null && pwd)"
  PATHS_DIR="$PROJECT_ROOT/config"
fi

CONFIG_FILE="$PATHS_DIR/config.yaml"

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
if [ -z "$PROJECT_ROOT" ]; then
  PROJECT_ROOT="$(cd -- "$PATHS_DIR/.." &> /dev/null && pwd)"
fi
WORK_DIR="$PROJECT_ROOT/$work_dir"
BIN_DIR="$PROJECT_ROOT/bin"
RESULT_DIR="$WORK_DIR/results"
STUDY_DIR="$RESULT_DIR/${STUDY_ID}_cbioportal"

# Load required modules on ComputeCanada
module load python scipy-stack

# Check Python
PYTHON_VER=$(python --version 2>&1)
echo "Python: $PYTHON_VER"

python $BIN_DIR/merge_maf.py --input-dir $MAF_DIR --output-file $STUDY_DIR/data_mutations_extended.txt
python $BIN_DIR/metadata_maker.py --study-identifier "$STUDY_ID" --name "$STUDY_NAME" --project-dir "$STUDY_DIR" --description "$STUDY_DESC"
python $BIN_DIR/clinicaldata_maker.py --input-tsv "$TSV_FILE" --project-dir "$STUDY_DIR"
python $BIN_DIR/cases_sequenced.py --project-dir "$STUDY_DIR"

echo "All scripts executed successfully."
