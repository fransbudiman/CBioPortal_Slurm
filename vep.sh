#! /bin/bash

while getopts ":i:o:r:s:" opt; do
  case $opt in
    i) VCF_DIR="$OPTARG"
    ;;
    o) OUTPUT_DIR="$OPTARG"
    ;;
    r) REF_DIR="$OPTARG"
    ;;
    s) STUDY_ID="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

echo "Pick a genome build to cache:"
echo "1) hg19/GRCh37"
echo "2) hg38/GRCh38"
read -p "Enter choice [1 or 2]: " choice

case $choice in
  1) CACHE_BUILD="hg19/GRCh37"
     ;;
  2) CACHE_BUILD="hg38/GRCh38"
     ;;
  *) echo "Invalid choice"
     exit 1
     ;;
esac

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd $SCRATCH/cbioportal_projects/tools
if [ ! -f vep.sif ]; then
    singularity pull --name vep.sif docker://ensemblorg/ensembl-vep
fi

if [ "$CACHE_BUILD" = "hg19/GRCh37" ]; then
    ASSEMBLY="GRCh37"
    if compgen -G "$REF_DIR/homo_sapiens/*GRCh37*" > /dev/null; then
        echo "Cache for $CACHE_BUILD already exists."
    else
        singularity exec --bind $REF_DIR:$REF_DIR vep.sif INSTALL.pl -c $REF_DIR -a cf -s homo_sapiens -y GRCh37
    fi
elif [ "$CACHE_BUILD" = "hg38/GRCh38" ]; then
    ASSEMBLY="GRCh38"
    if compgen -G "$REF_DIR/homo_sapiens/*GRCh38*" > /dev/null; then
        echo "Cache for $CACHE_BUILD already exists."
    else
        singularity exec --bind $REF_DIR:$REF_DIR vep.sif INSTALL.pl -c $REF_DIR -a cf -s homo_sapiens -y GRCh38
    fi
fi

# Run VEP on each VCF in $VCF_DIR
for vcf in $VCF_DIR/*.vcf; do
    mkdir -p $SCRATCH/cbioportal_projects/logs
    SAMPLE_NAME=$(basename ${vcf%.vcf})
    sbatch --output=$SCRATCH/cbioportal_projects/logs/vep_%A.out $SCRIPT_DIR/vep_slurm.sh -i $vcf -o $OUTPUT_DIR/${SAMPLE_NAME}.vep.vcf -r $REF_DIR -s $STUDY_ID -a $ASSEMBLY
done