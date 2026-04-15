#!/bin/bash

# Driver script to download results from Trillium and import to local cBioPortal
# Usage: ./bin/driver_download_import.sh
# This script will:
#   1. Download study from Trillium
#   2. Start local cBioPortal (docker compose)
#   3. Import study using metaImport.py
#   4. Save warnings to log file

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Calculate project root
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &> /dev/null && pwd)"
CONFIG_FILE="$PROJECT_ROOT/config/config.yaml"

# Local paths
DOCKER_COMPOSE_DIR="/mnt/c/UNIFRANS/Work/JLE/CBioPortal/cbioportal-docker-compose"
STUDY_DIR="$DOCKER_COMPOSE_DIR/study"
WARNING_DIR="$STUDY_DIR/warning"

# Remote settings
REMOTE_HOST="frans@trillium.alliancecan.ca"
REMOTE_BASE="/scratch/frans/CBioPortal/CBioPortal_Slurm/work/results"

echo "========================================"
echo "CBioPortal Download & Import"
echo "========================================"

# Read study_id from config.yaml
echo -e "${GREEN}Step 1: Reading study configuration...${NC}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}ERROR: config.yaml not found at $CONFIG_FILE${NC}"
    exit 1
fi

eval $(python3 -c "
import yaml
import shlex
with open('$CONFIG_FILE', 'r') as f:
    config = yaml.safe_load(f)
    study_id = config.get('study_id', '')
    print(f'STUDY_ID={shlex.quote(study_id)}')
")

if [ -z "$STUDY_ID" ]; then
    echo -e "${RED}ERROR: study_id not set in config.yaml${NC}"
    exit 1
fi

REMOTE_STUDY_PATH="$REMOTE_BASE/${STUDY_ID}_cbioportal"
LOCAL_STUDY_PATH="$STUDY_DIR/${STUDY_ID}_cbioportal"

echo "Study ID: $STUDY_ID"
echo "Remote path: $REMOTE_HOST:$REMOTE_STUDY_PATH"
echo "Local path: $LOCAL_STUDY_PATH"

# Download study from Trillium
echo ""
echo -e "${GREEN}Step 2: Downloading study from Trillium...${NC}"

# Create study directory if it doesn't exist
mkdir -p "$STUDY_DIR"

# Check if study already exists locally
if [ -d "$LOCAL_STUDY_PATH" ]; then
    echo -e "${YELLOW}WARNING: Study already exists locally: $LOCAL_STUDY_PATH${NC}"
    read -p "Overwrite existing study? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Task aborted by user${NC}"
        exit 0
    fi
    echo "Removing existing study..."
    rm -rf "$LOCAL_STUDY_PATH"
fi

echo "You will be prompted for password..."

# Download using scp
scp -r "$REMOTE_HOST:$REMOTE_STUDY_PATH" "$STUDY_DIR/"

if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: Failed to download study from Trillium${NC}"
    exit 1
fi

echo -e "${GREEN}Download complete!${NC}"

# Verify study directory exists
if [ ! -d "$LOCAL_STUDY_PATH" ]; then
    echo -e "${RED}ERROR: Study directory not found: $LOCAL_STUDY_PATH${NC}"
    exit 1
fi

# Start docker compose
echo ""
echo -e "${GREEN}Step 3: Starting cBioPortal (docker compose)...${NC}"

cd "$DOCKER_COMPOSE_DIR"

# Check if already running
if docker compose ps | grep -q "Up"; then
    echo "cBioPortal is already running"
else
    echo "Starting cBioPortal in background..."
    docker compose up -d
    
    # Wait for cBioPortal to be ready
    echo "Waiting for cBioPortal to start (30 seconds)..."
    sleep 30
fi

# Create warning directory
mkdir -p "$WARNING_DIR"

# Generate log filename with date
LOG_DATE=$(date +%Y%m%d_%H%M%S)
WARNING_LOG="$WARNING_DIR/warning_${LOG_DATE}.log"

# Import study
echo ""
echo -e "${GREEN}Step 4: Importing study to cBioPortal...${NC}"
echo "Study: /study/${STUDY_ID}_cbioportal"

# Run metaImport and capture output (temporarily disable exit on error)
set +e
IMPORT_OUTPUT=$(docker compose run --rm cbioportal \
  metaImport.py \
    -u http://cbioportal:8080 \
    -s /study/${STUDY_ID}_cbioportal \
    -o 2>&1)

IMPORT_EXIT_CODE=$?
set -e

# Save full output to log file
echo "$IMPORT_OUTPUT" > "$WARNING_LOG"
echo "Warning log saved to: $WARNING_LOG"

# Check if import was successful
echo ""
echo "========================================"
if [ $IMPORT_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}IMPORT SUCCESSFUL${NC}"
else
    echo -e "${RED}IMPORT FAILED${NC}"
fi
echo "========================================"

# Show warning/error summary
ERROR_COUNT=$(echo "$IMPORT_OUTPUT" | grep -i "error" | wc -l)
WARNING_COUNT=$(echo "$IMPORT_OUTPUT" | grep -i "warning" | wc -l)

echo "Errors: $ERROR_COUNT"
echo "Warnings: $WARNING_COUNT"
echo ""
echo "Full log saved to: $WARNING_LOG"
echo ""
echo "cBioPortal is running at: http://localhost:8080"
echo "To stop: cd $DOCKER_COMPOSE_DIR && docker compose down"
echo "========================================"

# Show last few lines of output for quick review
echo ""
echo "Last 20 lines of import output:"
echo "--------------------------------"
echo "$IMPORT_OUTPUT" | tail -20
echo "--------------------------------"

exit $IMPORT_EXIT_CODE
