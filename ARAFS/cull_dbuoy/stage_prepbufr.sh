#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Error: Exactly three arguments are required."
    echo "Usage: $0 <SRC_BASE> <DEST_BASE> <DATE_PREFIX>"
    echo "Example: $0 /lfs/h2/emc/global/noscrub/emc.global/dump /lfs/h2/emc/couple/noscrub/santha.akella/dbouy_with_hold/data/prepbufr 202605"
    exit 1
fi

SRC_BASE="$1"
DEST_BASE="$2"
DATE_PREFIX="$3"

# Find matching files. If no files match, the loop will exit gracefully.
shopt -s nullglob
files=(${SRC_BASE}/gdas.${DATE_PREFIX}*/*/atmos/gdas.t*z.prepbufr)
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
    echo "Error: No files found matching pattern: ${SRC_BASE}/gdas.${DATE_PREFIX}*/*/atmos/gdas.t*z.prepbufr"
    exit 1
fi

for src_file in "${files[@]}"; do
    # Extract YYYYMMDD and HH from the path
    gdas_dir=$(echo "$src_file" | awk -F'/' '{print $(NF-3)}')
    DATE_DIR=${gdas_dir#gdas.} 
    
    HH=$(echo "$src_file" | awk -F'/' '{print $(NF-2)}') 
    
    # Create the target YYYYMMDD directory
    TARGET_DIR="${DEST_BASE}/${DATE_DIR}"
    mkdir -p "$TARGET_DIR"
    
    # Construct target filename without the .nr suffix
    TARGET_FILE="${TARGET_DIR}/gdas.t${HH}z.prepbufr"
    
    echo -n "Staging: ${DATE_DIR} ${HH}z... "
    
    # Copy file, preserving timestamps and permissions
    cp -p "$src_file" "$TARGET_FILE"
    CP_STATUS=$?
    
    # Check if the copy succeeded AND the staged file exists with size > 0
    if [ $CP_STATUS -eq 0 ] && [ -s "$TARGET_FILE" ]; then
        echo "Success"
    else
        echo "FAILED (Copy error or file empty)"
        # Clean up partial/failed copy
        rm -f "$TARGET_FILE"
        exit 1
    fi
done

echo "Staging complete."
exit 0
