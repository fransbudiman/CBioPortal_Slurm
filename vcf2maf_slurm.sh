#!/bin/bash
#SBATCH --job-name=vcf2maf
#SBATCH --time=00:10:00

while getopts ":i:o:r:" opt; do
  case $opt in
    i) INPUT_VCF="$OPTARG"
    ;;
    o) OUTPUT_MAF="$OPTARG"
    ;;
    r) REF_FASTA="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

module load perl/5.30.3
module load samtools

SAMPLE_NAME=$(awk '/^#CHROM/ {print $10}' $INPUT_VCF)
echo "Sample Name: $SAMPLE_NAME"

perl vcf2maf.pl --verbose --inhibit-vep --input-vcf $INPUT_VCF --output-maf $OUTPUT_MAF --ref-fasta $REF_FASTA --tumor-id $SAMPLE_NAME