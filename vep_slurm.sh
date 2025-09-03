#!/bin/bash

#SBATCH --job-name=vep
#SBATCH --time=00:15:00
#SBATCH --cpus-per-task=4
#SBATCH --nodes=1

while getopts ":i:o:r:s:a:" opt; do
  case $opt in
    i) VCF_LIST="$OPTARG"
    ;;
    o) OUTPUT_DIR="$OPTARG"
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

VCF=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $VCF_LIST)
SAMPLE_NAME=$(basename $VCF .vcf)

singularity exec --bind $SCRATCH:$SCRATCH vep.sif vep --dir $REF_DIR --cache --offline --format vcf --vcf --force_overwrite --input_file "$VCF" --output_file $OUTPUT_DIR/${SAMPLE_NAME}.vep.vcf --assembly $ASSEMBLY --everything

echo "Finished processing $VCF, output saved to $OUTPUT_DIR/${SAMPLE_NAME}.vep.vcf"