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

./setup.sh -i $STUDY_ID -r $REF_FASTA

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

# Process VCF files to change name from TM to SGT
mkdir -p $TEMP_DIR/processed_vcf
for vcf in $VCF_DIR/*.vcf; do
    # Process each VCF file
    echo "Processing $vcf..."
    python process_vcf.py --input-vcf $vcf --output-dir $TEMP_DIR/processed_vcf
done


mkdir -p $TEMP_DIR/vep_output
./vep.sh -i $TEMP_DIR/processed_vcf -o $TEMP_DIR/vep_output -r $REF_DIR -s $STUDY_ID

