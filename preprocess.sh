#!/bin/bash

while getopts ":i:n:d:v:" opt; do
  case $opt in
    i) STUDY_ID="$OPTARG"
    ;;
    n) STUDY_NAME="$OPTARG"
    ;;
    d) STUDY_DESC="$OPTARG"
    ;;
    v) VCF_DIR="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

./setup.sh -i $STUDY_ID -n $STUDY_NAME -d $STUDY_DESC -v $VCF_DIR

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

./vep.sh -i $VCF_DIR -o $TEMP_DIR/vep_output -r $REF_DIR -s $STUDY_ID

