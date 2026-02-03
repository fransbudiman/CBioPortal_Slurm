#! /bin/bash

set -x

while getopts ":i:o:r:s:f:" opt; do
  case $opt in
    i) VCF_DIR="$OPTARG"
    ;;
    o) OUTPUT_DIR="$OPTARG"
    ;;
    r) REF_DIR="$OPTARG"
    ;;
    s) STUDY_ID="$OPTARG"
    ;;
    f) FASTA_FILE="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# Calculate project root and load config
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}").." &> /dev/null && pwd)"
CONFIG_FILE="$PROJECT_ROOT/config/config.yaml"

# Parse YAML and set path variables
eval $(python3 -c "
import yaml
import shlex
with open('$CONFIG_FILE', 'r') as f:
    config = yaml.safe_load(f)
    for key in ['work_dir', 'env_dir']:
        if config.get(key):
            print(f'{key}={shlex.quote(str(config[key]))}')
")

# Build absolute paths
WORK_DIR="$PROJECT_ROOT/$work_dir"
ENV_DIR="$PROJECT_ROOT/$env_dir"

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

# run as job array
FILE_NO=$(ls $VCF_DIR/*.vcf | wc -l)
ls $VCF_DIR/*.vcf > $VCF_DIR/vcf_files.txt
mkdir -p $OUTPUT_DIR
for vcf in $VCF_DIR/*.vcf; do
    SAMPLE_NAME=$(basename ${vcf%.vcf})
    touch $OUTPUT_DIR/${SAMPLE_NAME}.vep.vcf
done

LOG_DIR="$PROJECT_ROOT/work/logs"
mkdir -p $LOG_DIR

jid=$(sbatch --export=PATHS_DIR=$PATHS_DIR --array=1-$FILE_NO --output=$LOG_DIR/vep_%A_%a.out $SCRIPT_DIR/vep_slurm.sh -i $VCF_DIR/vcf_files.txt -o $OUTPUT_DIR -r $REF_DIR -s $STUDY_ID -a $ASSEMBLY -f $FASTA_FILE | awk '{print $4}')
echo "jid: $jid"