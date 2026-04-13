import pandas as pd
import argparse
import os

# this script will generaate both metadata and clinical data files for fusion data
parser = argparse.ArgumentParser(description='Create fusion MAF file.')
parser.add_argument('--input-directory', required=True, help='Path to the input fusion file.')
parser.add_argument('--output-directory', required=True, help='Path to the output directory.')
parser.add_argument('--study-id', required=True, help='Cancer study identifier.')

args = parser.parse_args()
input_directory = args.input_directory
output_directory = args.output_directory
study_id = args.study_id

os.makedirs(output_directory, exist_ok=True)

fusion_df = []

for input_file in os.listdir(input_directory):
    if not input_file.endswith('.preliminary'):
        continue
    input_file = os.path.join(input_directory, input_file)
    print(f"Processing fusion file: {input_file}")
    df = pd.read_csv(input_file, sep="\t")

    for index, row in df.iterrows():
        fusion_genes= row['#FusionGene'].split('--')
        if len(fusion_genes) != 2:
            print(f"Skipping invalid fusion gene format: {row['#FusionGene']}")
            continue
        Site1_Hugo_Symbol = fusion_genes[0]
        Site2_Hugo_Symbol = fusion_genes[1]

        Site1_Ensembl_Transcript_Id = row['Gene1Id']
        Site2_Ensembl_Transcript_Id = row['Gene2Id']

        positions_site1 = row['LeftBreakpoint'].split(':')
        positions_site2 = row['RightBreakpoint'].split(':')

        if len(positions_site1) != 3 or len(positions_site2) != 3:
            print(f"Skipping invalid breakpoint format: {row['LeftBreakpoint']} or {row['RightBreakpoint']}")
            continue

        Site1_Chromosome = positions_site1[0].replace('chr', '')
        Site1_Position = positions_site1[1]
        Site2_Chromosome = positions_site2[0].replace('chr', '')
        Site2_Position = positions_site2[1]

        Site1_Region = row["Gene1Location"]
        Site2_Region = row["Gene2Location"]

        Tumor_Split_Read_Count = row["NumSplitReads"]

        # Assuming the sample ID is derived from the filename
        filename = os.path.basename(input_file)
        Sample_ID = filename.split('.')[0]

        fusion_df.append({
            "Sample_Id": Sample_ID,
            "SV_Status": "SOMATIC",
            "Site1_Hugo_Symbol": Site1_Hugo_Symbol,
            "Site2_Hugo_Symbol": Site2_Hugo_Symbol,
            "Site1_Ensembl_Transcript_Id": Site1_Ensembl_Transcript_Id,
            "Site2_Ensembl_Transcript_Id": Site2_Ensembl_Transcript_Id,
            "Site1_Chromosome": Site1_Chromosome,
            "Site1_Position": Site1_Position,
            "Site2_Chromosome": Site2_Chromosome,
            "Site2_Position": Site2_Position,
            "Site1_Region": Site1_Region,
            "Site2_Region": Site2_Region,
            "Tumor_Split_Read_Count": Tumor_Split_Read_Count
        })
    print(f"Processed fusion for sample: {Sample_ID}")

output_df = pd.DataFrame(fusion_df)
output_df.to_csv(os.path.join(output_directory, "data_sv.txt"), sep="\t", index=False)
print(f"Fusion data file created at: {os.path.join(output_directory, 'data_sv.txt')}")

# now make metadata file

metadata_lines = [
    f"cancer_study_identifier: {study_id}",
    "genetic_alteration_type: STRUCTURAL_VARIANT",
    "datatype: SV",
    "stable_id: structural_variants",
    "show_profile_in_analysis_tab: true",
    "profile_name: Structural variants",
    f"profile_description: Structural Variant Data for {study_id}",
    "data_filename: data_sv.txt"
]

with open(os.path.join(output_directory, "meta_sv.txt"), 'w') as f:
    f.write("\n".join(metadata_lines))

print(f"Fusion metadata files created in: {output_directory}")