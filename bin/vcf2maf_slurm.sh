#!/bin/bash
#SBATCH --job-name=vcf2maf
#SBATCH --time=00:15:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=10

while getopts ":i:o:r:" opt; do
  case $opt in
    i) VCF_LIST="$OPTARG"
    ;;
    o) OUTPUT_DIR="$OPTARG"
    ;;
    r) REF_FASTA="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

module load samtools
module load perl
module load tabix

VCF=$(sed -n "${SLURM_ARRAY_TASK_ID}p" $VCF_LIST)
SAMPLE_NAME=$(basename $VCF .vep.vcf)
echo "Sample Name: $SAMPLE_NAME"

perl vcf2maf.pl --verbose --inhibit-vep --input-vcf $VCF --output-maf $OUTPUT_DIR/${SAMPLE_NAME}.maf --ref-fasta $REF_FASTA --tumor-id $SAMPLE_NAME

echo "Finished processing $VCF, output saved to $OUTPUT_DIR/${SAMPLE_NAME}.maf"