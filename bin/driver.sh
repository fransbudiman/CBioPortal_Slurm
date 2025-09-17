#!/bin/bash

# This script will auto run the whole pipeline from vcf samples directory to cbioportal study directory

source "${BASH_SOURCE%/*}/../config/paths.env"

while getopts "i:v:r:n:d:t:p" opt; do
  case $opt in
    i) STUDY_ID="$OPTARG" ;;
    v) VCF_DIR="$OPTARG" ;;
    r) REF_TYPE="$OPTARG" ;;
    n) STUDY_NAME="$OPTARG" ;;
    d) STUDY_DESC="$OPTARG" ;;
    t) TSV_FILE="$OPTARG" ;;
    p) PROMPT_BOOL=1 ;;
    *) echo "Invalid option"; exit 1 ;;
  esac
done

if [ -n "$PROMPT_BOOL" ] && [ "$PROMPT_BOOL" -eq 1 ]; then
# Interactive inputting of arguments
    echo "Enter Study ID:"
    read STUDY_ID
    echo "Enter VCF Directory:"
    read VCF_DIR
    echo "Enter Reference Type:"
    read REF_TYPE
    echo "Enter Reference File:"
    read REF_FILE
    echo "Enter Study Name:"
    read STUDY_NAME
    echo "Enter Study Description:"
    read STUDY_DESC
    echo "Enter TSV File:"
    read TSV_FILE
else
    # Check if all required arguments are provided
    if [ -z "$STUDY_ID" ] || [ -z "$VCF_DIR" ] || [ -z "$REF_TYPE" ] || [ -z "$STUDY_NAME" ] || [ -z "$STUDY_DESC" ] || [ -z "$TSV_FILE" ]; then
        echo "Error: Missing required arguments."
        echo "Usage: ./driver.sh -i STUDY_ID -v VCF_DIR -r REF_TYPE -n STUDY_NAME -d STUDY_DESC -t TSV_FILE [-p]"
        exit 1
    fi
fi

VEP_DIR="$WORK_DIR/results/${STUDY_ID}_temp/vep_output"
MAF_DIR="$WORK_DIR/results/${STUDY_ID}_temp/maf_files"
echo "VEP Directory: $VEP_DIR"
echo "MAF Directory: $MAF_DIR"

REF_DIR="$WORK_DIR/references"

mkdir -p "$VEP_DIR"
mkdir -p "$MAF_DIR"

jid_vep=$(./$BIN_DIR/preprocess.sh -i "$STUDY_ID" -v "$VCF_DIR" -r "$REF_TYPE" | awk '/jid:/ {print $2}')
echo "Job ID for VEP: $jid_vep"

jid_vcf2maf=$(./$BIN_DIR/vcf2maf.sh -i "$VEP_DIR" -p "$STUDY_ID" -r "$REF_DIR/hg19.fa.gz.fai" -D "$jid_vep" | awk '/jid:/ {print $2}')
echo "Job ID for VCF2MAF: $jid_vcf2maf"

./$BIN_DIR/create_study.sh -i "$STUDY_ID" -n "$STUDY_NAME" -d "$STUDY_DESC" -m "$MAF_DIR" -t "$TSV_FILE" -D "$jid_vcf2maf"