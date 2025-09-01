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

CONDA_VER=$(conda --version)
echo "conda: $CONDA_VER"

conda activate cbioportal

python merge_maf.py --input-dir $MAF_DIR --output-file $STUDY_DIR/data_mutations_extended.txt
python metadata_maker.py --study-identifier "$STUDY_ID" --name "$STUDY_NAME" --project-dir "$STUDY_DIR" --description "$STUDY_DESC"
python clinicaldata_maker.py --input-tsv "$TSV_FILE" --project-dir "$STUDY_DIR"
python cases_sequenced.py --project-dir "$STUDY_DIR"

echo "All scripts executed successfully."
