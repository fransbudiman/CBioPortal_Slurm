#!/bin/bash

#SBATCH --job-name=vep
#SBATCH --time=00:30:00

while getopts ":i:o:r:s:a:" opt; do
  case $opt in
    i) VCF_FILE="$OPTARG"
    ;;
    o) OUTPUT_FILE="$OPTARG"
    ;;
    a) ASSEMBLY="$OPTARG"
    ;;
    r) REF_DIR="$OPTARG"
    ;;
    s) STUDY_ID="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

singularity exec --bind $SCRATCH:$SCRATCH vep.sif vep --dir $REF_DIR --cache --offline --format vcf --vcf --force_overwrite --input_file $VCF_FILE --output_file $OUTPUT_FILE --assembly $ASSEMBLY