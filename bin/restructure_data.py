#!/usr/bin/env python3
"""
Restructure data directory by consolidating sample files into centralized subdirectories.

This script takes a directory containing multiple sample subdirectories and creates
a restructured version with all files organized by data type (mutation, fusion, RNA).

Usage:
    python restructure_data.py <input_directory>

Example:
    python restructure_data.py /path/to/test
"""

import os
import sys
import shutil
from pathlib import Path
import pandas as pd


def merge_sample_info(source_file, dest_file):
    """
    Merge sample_info.tsv from source into destination file using pandas.
    
    Args:
        source_file: Path to source sample_info.tsv
        dest_file: Path to destination sample_info.tsv (will be created if doesn't exist)
    """
    # Read source TSV file
    source_df = pd.read_csv(source_file, sep='\t')
    
    if source_df.empty:
        print(f"  Warning: Source sample_info.tsv '{source_file}' is empty, skipping merge")
        return
    
    # Fill empty CANCER_TYPE values with "Tissue"
    if 'CANCER_TYPE' in source_df.columns:
        source_df['CANCER_TYPE'] = source_df['CANCER_TYPE'].fillna('Tissue')
        source_df['CANCER_TYPE'] = source_df['CANCER_TYPE'].replace('', 'Tissue')
    
    # If destination doesn't exist, write source as-is
    if not dest_file.exists():
        source_df.to_csv(dest_file, sep='\t', index=False)
    else:
        # Destination exists, read it and concatenate
        dest_df = pd.read_csv(dest_file, sep='\t')
        merged_df = pd.concat([dest_df, source_df], ignore_index=True)
        merged_df.to_csv(dest_file, sep='\t', index=False)


def restructure_data(input_dir):
    """
    Restructure data directory by consolidating files by data type.
    
    Args:
        input_dir: Path to the input directory containing sample subdirectories
    """
    input_path = Path(input_dir).resolve()
    
    if not input_path.exists():
        print(f"Error: Input directory '{input_dir}' does not exist")
        sys.exit(1)
    
    if not input_path.is_dir():
        print(f"Error: '{input_dir}' is not a directory")
        sys.exit(1)
    
    # Create restructured directory (remove if exists to start fresh)
    dir_name = input_path.name
    restructured_dir = input_path.parent / f"{dir_name}_restructured"
    
    # Remove existing restructured directory to avoid conflicts
    if restructured_dir.exists():
        print(f"WARNING: Restructured directory already exists: {restructured_dir}")
        print("Removing existing directory to start fresh...")
        shutil.rmtree(restructured_dir)
        print("Removed.")

    
    # Create subdirectories
    mutation_dir = restructured_dir / "mutation_data"
    fusion_dir = restructured_dir / "fusion_data"
    rna_dir = restructured_dir / "rna_data"
    
    print(f"Creating restructured directory: {restructured_dir}")
    restructured_dir.mkdir(exist_ok=True)
    mutation_dir.mkdir(exist_ok=True)
    fusion_dir.mkdir(exist_ok=True)
    rna_dir.mkdir(exist_ok=True)
    
    # Initialize sample_info.tsv paths for each data type
    mutation_sample_info = mutation_dir / "sample_info.tsv"
    fusion_sample_info = fusion_dir / "sample_info.tsv"
    rna_sample_info = rna_dir / "sample_info.tsv"
    
    # Track statistics
    stats = {
        'mutation': 0,
        'fusion': 0,
        'rna': 0,
        'mutation_info': 0,
        'fusion_info': 0,
        'rna_info': 0,
        'samples_processed': 0
    }
    
    # Process each sample directory
    sample_dirs = [d for d in input_path.iterdir() if d.is_dir()]
    
    if not sample_dirs:
        print(f"Warning: No sample directories found in {input_dir}")
        return
    
    print(f"\nProcessing {len(sample_dirs)} sample directories...")
    
    for sample_dir in sorted(sample_dirs):
        sample_name = sample_dir.name
        print(f"\nProcessing sample: {sample_name}")
        
        # Process mutation data - copy .vcf.gz files and merge sample_info.tsv
        mutation_src = sample_dir / "mutation_data"
        if mutation_src.exists():
            for vcf_file in mutation_src.glob("*.vcf.gz"):
                dest_file = mutation_dir / vcf_file.name
                shutil.copy2(vcf_file, dest_file)
                print(f"  Copied mutation: {vcf_file.name}")
                stats['mutation'] += 1
            
                # Merge sample_info.tsv if mutation file exist
                sample_info_src = sample_dir / "sample_info.tsv"
                if sample_info_src.exists():
                    merge_sample_info(sample_info_src, mutation_sample_info)
                    print(f"  Merged mutation sample_info.tsv")
                    stats['mutation_info'] += 1
        
        # Process fusion data - copy .preliminary files and merge sample_info.tsv
        fusion_src = sample_dir / "fusion_data"
        if fusion_src.exists():
            for fusion_file in fusion_src.glob("*.preliminary"):
                dest_file = fusion_dir / fusion_file.name
                shutil.copy2(fusion_file, dest_file)
                print(f"  Copied fusion: {fusion_file.name}")
                stats['fusion'] += 1
            
                # Merge sample_info.tsv if fusion file exist
                sample_info_src = sample_dir / "sample_info.tsv"
                if sample_info_src.exists():
                    merge_sample_info(sample_info_src, fusion_sample_info)
                    print(f"  Merged fusion sample_info.tsv")
                    stats['fusion_info'] += 1
        
        # Process RNA data - copy .txt files and merge sample_info.tsv
        rna_src = sample_dir / "rna_data"
        if rna_src.exists():
            for rna_file in rna_src.glob("*.txt"):
                dest_file = rna_dir / rna_file.name
                shutil.copy2(rna_file, dest_file)
                print(f"  Copied RNA: {rna_file.name}")
                stats['rna'] += 1
            
                # Merge sample_info.tsv if RNA file exist
                sample_info_src = sample_dir / "sample_info.tsv"
                if sample_info_src.exists():
                    merge_sample_info(sample_info_src, rna_sample_info)
                    print(f"  Merged RNA sample_info.tsv")
                    stats['rna_info'] += 1
        
        stats['samples_processed'] += 1
    
    # Print summary
    print("\n" + "="*60)
    print("RESTRUCTURING COMPLETE")
    print("="*60)
    print(f"Output directory: {restructured_dir}")
    print(f"\nSamples processed: {stats['samples_processed']}")
    print(f"\nMutation files copied: {stats['mutation']}")
    print(f"  sample_info.tsv entries merged: {stats['mutation_info']}")
    print(f"Fusion files copied: {stats['fusion']}")
    print(f"  sample_info.tsv entries merged: {stats['fusion_info']}")
    print(f"RNA files copied: {stats['rna']}")
    print(f"  sample_info.tsv entries merged: {stats['rna_info']}")
    print(f"\nTotal data files copied: {stats['mutation'] + stats['fusion'] + stats['rna']}")
    print("="*60)


def main():
    if len(sys.argv) != 2:
        print("Usage: python restructure_data.py <input_directory>")
        print("\nExample:")
        print("  python restructure_data.py /path/to/test")
        sys.exit(1)
    
    input_dir = sys.argv[1]
    restructure_data(input_dir)


if __name__ == "__main__":
    main()
