
while getopts ":i:p:r:" opt; do
  case $opt in
    i) VEP_VCF_DIR="$OPTARG"
    ;;
    r) REF_FASTA="$OPTARG"
    ;;
    p) PROJECT_NAME="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# Storing all FASTA references
REF_DIR="$SCRATCH/cbioportal_projects/references"
# Storing all result
RESULT_DIR="$SCRATCH/cbioportal_projects/results"
# Temporary directory for intermediate files (delete after upload)
TEMP_DIR="$RESULT_DIR/${PROJECT_NAME}_temp"

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Download and extract vcf2maf scripts
mkdir -p $SCRATCH/cbioportal_projects/tools
cd $SCRATCH/cbioportal_projects/tools
if [ ! -d "mskcc-vcf2maf*" ]; then
  export VCF2MAF_URL=`curl -sL https://api.github.com/repos/mskcc/vcf2maf/releases | grep -m1 tarball_url | cut -d\" -f4`
  curl -L -o mskcc-vcf2maf.tar.gz $VCF2MAF_URL; tar -zxf mskcc-vcf2maf.tar.gz; cd mskcc-vcf2maf-*
fi

mkdir -p $TEMP_DIR/maf_files

# Submit array job instead
FILE_NO=$(ls $VEP_VCF_DIR/*.vcf | wc -l)
ls $VEP_VCF_DIR/*.vcf > $VEP_VCF_DIR/vcf_files.txt

jid=$(sbatch --array=1-$FILE_NO --output=$SCRATCH/cbioportal_projects/logs/vcf2maf_%A_%a.out $SCRIPT_DIR/vcf2maf_slurm.sh -i $VEP_VCF_DIR/vcf_files.txt -o $TEMP_DIR/maf_files -r $REF_FASTA | awk '{print $4}')
echo "jid: $jid"

# # Run the vcf2maf.pl on each vep.vcf file in the input directory through slurm
# for vcf in $VEP_VCF_DIR/*.vcf; do
#     sbatch --output=$SCRATCH/cbioportal_projects/logs/vcf2maf_%A.out $SCRIPT_DIR/vcf2maf_slurm.sh -i $vcf -o $TEMP_DIR/maf_files/$(basename $vcf .vep.vcf).maf -r $REF_FASTA
# done

