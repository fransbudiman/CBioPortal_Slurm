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

source "${BASH_SOURCE%/*}/../config/paths.env"

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
for vcf in $VCF_DIR/*.vcf; do
    # Process each VCF file
    echo "Processing $vcf..."
    python $BIN_DIR/process_vcf.py --input-vcf $vcf --output-dir $TEMP_DIR/processed_vcf
done


mkdir -p $TEMP_DIR/vep_output
jid_vep=$($BIN_DIR/vep.sh -i $TEMP_DIR/processed_vcf -o $TEMP_DIR/vep_output -r $REF_DIR -s $STUDY_ID -f $REF_FASTA_PATH | awk '/jid:/ {print $2}')
echo "jid: $jid_vep"
