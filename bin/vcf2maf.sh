#!/bin/bash

while getopts ":i:p:r:D:" opt; do
  case $opt in
    i) VEP_DIR="$OPTARG"
    ;;
    r) REF_FASTA="$OPTARG"
    ;;
    p) PROJECT_NAME="$OPTARG"
    ;;
    D) DEPENDENCY="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

source "${BASH_SOURCE%/*}/../config/paths.env"

REF_DIR="$WORK_DIR/references"
RESULT_DIR="$WORK_DIR/results"
TEMP_DIR="$RESULT_DIR/${PROJECT_NAME}_temp"
TOOLS_DIR="$WORK_DIR/tools"

# Download and extract vcf2maf scripts
mkdir -p $TOOLS_DIR
cd $TOOLS_DIR
if [ ! -d "mskcc-vcf2maf*" ]; then
  export VCF2MAF_URL=`curl -sL https://api.github.com/repos/mskcc/vcf2maf/releases | grep -m1 tarball_url | cut -d\" -f4`
  curl -L -o mskcc-vcf2maf.tar.gz $VCF2MAF_URL; tar -zxf mskcc-vcf2maf.tar.gz; cd mskcc-vcf2maf-*
fi

mkdir -p $TEMP_DIR/maf_files

# Submit array job instead
FILE_NO=$(ls $VEP_DIR/*.vcf | wc -l)
ls $VEP_DIR/*.vcf > $VEP_DIR/vcf_files.txt
echo "VEP_DIR = $VEP_DIR"

if [ -n "$DEPENDENCY" ]; then
  DEPENDENCY_TEXT="--dependency=afterok:$DEPENDENCY"
fi

LOG_DIR="$PROJECT_ROOT/work/logs"
mkdir -p $LOG_DIR

jid=$(sbatch $DEPENDENCY_TEXT --export=PATHS_DIR=$PATHS_DIR --array=1-$FILE_NO --output=$LOG_DIR/vcf2maf_%A_%a.out $BIN_DIR/vcf2maf_slurm.sh -i $VEP_DIR/vcf_files.txt -o $TEMP_DIR/maf_files -r $REF_FASTA | awk '{print $4}')
echo "jid: $jid"
