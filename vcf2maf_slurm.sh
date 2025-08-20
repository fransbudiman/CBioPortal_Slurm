#SBATCH --job-name=vcf2maf
#SBATCH --output=vcf2maf_%j.log
#SBATCH --time=02:00:00

getopts ":i:o:r:" opt; do
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

