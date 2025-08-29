#!/bin/bash

while getopts ":i:p:r:m:n:d:t:" opt; do
    case $opt in
        i) VEP_DIR="$OPTARG" ;;
        p) STUDY_ID="$OPTARG" ;;
        r) REF_FILE="$OPTARG" ;;
        m) MAF_DIR="$OPTARG" ;;
        n) STUDY_NAME="$OPTARG" ;;
        d) STUDY_DESC="$OPTARG" ;;
        t) TSV_FILE="$OPTARG" ;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
        :)  echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
    esac
done

COLOR='\033[0;32m'
NC='\033[0m'

jid_vcf2maf=$(./vcf2maf.sh -i "$VEP_DIR" -p "$STUDY_ID" -r "$REF_FILE" | awk '/jid:/ {print $2}')
echo -e "${COLOR}Job ID for VCF2MAF: $jid_vcf2maf${NC}"

sbatch --dependency=afterok:$jid_vcf2maf ./create_study.sh -- -i "$MAF_DIR" -n "$STUDY_NAME" -d "$STUDY_DESC" -m "$MAF_DIR" -t "$TSV_FILE"
