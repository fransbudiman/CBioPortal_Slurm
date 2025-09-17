#!/bin/bash

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

mkdir -p $REF_DIR $RESULT_DIR $TOOLS_DIR $STUDY_DIR $TEMP_DIR

module load samtools

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