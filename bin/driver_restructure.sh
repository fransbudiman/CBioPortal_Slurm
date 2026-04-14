#!/bin/bash

# Driver script to restructure data and upload to Trillium cluster
# Usage: ./bin/driver_restructure.sh <input_directory>
# Example: ./bin/driver_restructure.sh /mnt/c/UNIFRANS/Work/JLE/CBioPortal/DATA/test

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Calculate project root
PROJECT_ROOT="/mnt/c/UNIFRANS/Work/JLE/CBioPortal/CBioPortal_Slurm"
CONFIG_FILE="$PROJECT_ROOT/config/config.yaml"
BIN_DIR="$PROJECT_ROOT/bin"

echo "========================================"
echo "CBioPortal Data Restructure & Upload"
echo "========================================"

# Check arguments
if [ $# -ne 1 ]; then
    echo -e "${RED}ERROR: Missing input directory${NC}"
    echo "Usage: $0 <input_directory>"
    echo "Example: $0 /mnt/c/UNIFRANS/Work/JLE/CBioPortal/DATA/test"
    exit 1
fi

INPUT_DIR="$1"

# Validate input directory
if [ ! -d "$INPUT_DIR" ]; then
    echo -e "${RED}ERROR: Input directory does not exist: $INPUT_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}Step 1: Restructuring data...${NC}"
echo "Input directory: $INPUT_DIR"

# Run restructure_data.py
python3 "$BIN_DIR/restructure_data.py" "$INPUT_DIR"

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Data restructuring failed${NC}"
    exit 1
fi

# Determine output directory
INPUT_DIR_NAME=$(basename "$INPUT_DIR")
PARENT_DIR=$(dirname "$INPUT_DIR")
RESTRUCTURED_DIR="$PARENT_DIR/${INPUT_DIR_NAME}_restructured"

if [ ! -d "$RESTRUCTURED_DIR" ]; then
    echo -e "${RED}ERROR: Restructured directory not found: $RESTRUCTURED_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}Restructuring complete!${NC}"
echo "Restructured directory: $RESTRUCTURED_DIR"

# Read config.yaml to get remote paths
echo ""
echo -e "${GREEN}Step 2: Reading remote paths from config.yaml...${NC}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}ERROR: config.yaml not found at $CONFIG_FILE${NC}"
    exit 1
fi

# Parse YAML to get one of the remote directories and extract parent path
eval $(python3 -c "
import yaml
import shlex
import os
with open('$CONFIG_FILE', 'r') as f:
    config = yaml.safe_load(f)
    # Get any configured directory (prefer vcf_dir)
    for key in ['vcf_dir', 'fusion_dir', 'rna_dir']:
        if config.get(key):
            full_path = config[key]
            # Extract parent directory (remove /mutation_data, /fusion_data, or /rna_data)
            parent_path = os.path.dirname(full_path)
            print(f'REMOTE_PARENT_DIR={shlex.quote(parent_path)}')
            break
")

REMOTE_HOST="frans@trillium.alliancecan.ca"
REMOTE_PROJECT_DIR="/scratch/frans/CBioPortal/CBioPortal_Slurm"
CONTROL_PATH="/tmp/ssh_control_%h_%p_%r"

if [ -z "$REMOTE_PARENT_DIR" ]; then
    echo -e "${RED}ERROR: No remote directories configured in config.yaml${NC}"
    echo "Please set at least one of: vcf_dir, fusion_dir, or rna_dir"
    exit 1
fi

echo "Remote parent directory: $REMOTE_PARENT_DIR"

# Get the grandparent directory (one level up from REMOTE_PARENT_DIR)
REMOTE_GRANDPARENT_DIR=$(dirname "$REMOTE_PARENT_DIR")
echo "Will upload restructured data to: $REMOTE_HOST:$REMOTE_GRANDPARENT_DIR/"

# Establish SSH ControlMaster connection
echo ""
echo -e "${GREEN}Establishing SSH connection (authenticate once)...${NC}"
ssh -M -S "$CONTROL_PATH" -fN "$REMOTE_HOST"
if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to establish SSH connection${NC}"
    exit 1
fi
echo -e "${GREEN}✓ SSH connection established!${NC}"

# Upload restructured directory
echo ""
echo -e "${GREEN}Step 3: Uploading restructured data to Trillium...${NC}"

RESTRUCTURED_DIR_NAME=$(basename "$RESTRUCTURED_DIR")
echo "Uploading: $RESTRUCTURED_DIR"
echo "Destination: $REMOTE_HOST:$REMOTE_GRANDPARENT_DIR/$RESTRUCTURED_DIR_NAME/"

# Upload entire restructured directory using scp with ControlMaster
scp -o ControlPath="$CONTROL_PATH" -r "$RESTRUCTURED_DIR" "$REMOTE_HOST:$REMOTE_GRANDPARENT_DIR/"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Upload successful!${NC}"
else
    echo -e "${RED}ERROR: Upload failed${NC}"
    ssh -S "$CONTROL_PATH" -O exit "$REMOTE_HOST" 2>/dev/null
    exit 1
fi

# Submit SLURM job
echo ""
echo -e "${GREEN}Step 4: Submitting SLURM job on Trillium...${NC}"
echo "Running: sbatch bin/driver.sh"

JOB_OUTPUT=$(ssh -S "$CONTROL_PATH" "$REMOTE_HOST" "cd $REMOTE_PROJECT_DIR && sbatch bin/driver.sh")
JOB_ID=$(echo "$JOB_OUTPUT" | grep -oP '\d+')

if [ -z "$JOB_ID" ]; then
    echo -e "${RED}ERROR: Failed to submit SLURM job${NC}"
    echo "$JOB_OUTPUT"
    ssh -S "$CONTROL_PATH" -O exit "$REMOTE_HOST" 2>/dev/null
    exit 1
fi

echo -e "${GREEN}✓ SLURM job submitted! Job ID: $JOB_ID${NC}"

# Verify job is in queue
echo "Verifying job is queued..."
QUEUE_CHECK=$(ssh -S "$CONTROL_PATH" "$REMOTE_HOST" "squeue -j $JOB_ID 2>/dev/null")

if echo "$QUEUE_CHECK" | grep -q "$JOB_ID"; then
    echo -e "${GREEN}✓ Job $JOB_ID is in the queue${NC}"
else
    echo -e "${YELLOW}Warning: Job $JOB_ID not found in queue (may have already started/finished)${NC}"
fi

# Close SSH ControlMaster
echo ""
echo "Closing SSH connection..."
ssh -S "$CONTROL_PATH" -O exit "$REMOTE_HOST" 2>/dev/null

# Summary
echo ""
echo "========================================"
echo -e "${GREEN}UPLOAD & SUBMISSION COMPLETE${NC}"
echo "========================================"
echo "Local restructured directory: $RESTRUCTURED_DIR"
echo "Remote host: $REMOTE_HOST"
echo "SLURM Job ID: $JOB_ID"
echo ""
echo "Next steps:"
echo "  1. Monitor job: ssh $REMOTE_HOST 'squeue -u frans'"
echo "  2. Check logs: ssh $REMOTE_HOST 'cat $REMOTE_PROJECT_DIR/slurm-$JOB_ID.out'"
echo "  3. Download results when complete: ./bin/driver_download_import.sh"
echo "========================================"
