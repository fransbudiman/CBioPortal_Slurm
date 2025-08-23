#!/bin/bash

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

# Storing all FASTA references
REF_DIR="$SCRATCH/cbioportal_projects/references"
# Storing all result
RESULT_DIR="$SCRATCH/cbioportal_projects/results"
# Storing all tools and scripts
TOOLS_DIR="$SCRATCH/cbioportal_projects/tools"
# Final project directory to upload to CBioPortal
STUDY_DIR="$RESULT_DIR/${STUDY_ID}_cbioportal"
# Temporary directory for intermediate files (delete after upload)
TEMP_DIR="$RESULT_DIR/${STUDY_ID}_temp"

# Merge MAF files
conda install pandas numpy
python merge_maf.py --input-dir $MAF_DIR --output-file $STUDY_DIR/data_mutation_extended.txt

python metadata_maker.py --study-identifier "$STUDY_ID" --name "$STUDY_NAME" --project-dir "$STUDY_DIR" --description "$STUDY_DESC"

python clinicaldata_maker.py --input-tsv "$TSV_FILE" --project-dir "$STUDY_DIR"

python cases_sequenced.py --project-dir "$STUDY_DIR"

