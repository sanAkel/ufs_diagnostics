#!/bin/bash

# Goal: Get "seaice.t00z.5min.grb.grib2" from:
#       HPSS: /NCEPPROD/hpssprod/runhistory/rh${yyyy}/${yyyymm}/${yyyymmdd}/com_seaice_analysis_v4.5_seaice_analysis.${yyyymmdd}.tar
# --

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <START_DATE> <END_DATE> <OUTPUT_PATH>"
    echo "Example: $0 20250801 20250810 /scratch5/NCEPDEV/rstprod/Santha.Akella/data/sea_ice_conc"
    exit 1
fi

START_DATE="$1"
END_DATE="$2"
OUTPUT_PATH="$3"

HTAR_THREADS=4
PRODUCT_NAME="com_seaice_analysis_v4.5_seaice_analysis"
TARGET_FILE="./seaice.t00z.5min.grb.grib2"

if ! date -d "$START_DATE" >/dev/null 2>&1; then
    echo "Error: Invalid START_DATE. Must be a valid date in YYYYMMDD format."
    exit 1
fi

if ! date -d "$END_DATE" >/dev/null 2>&1; then
    echo "Error: Invalid END_DATE. Must be a valid date in YYYYMMDD format."
    exit 1
fi

if [ "$START_DATE" -gt "$END_DATE" ]; then
    echo "Error: START_DATE ($START_DATE) cannot be later than END_DATE ($END_DATE)."
    exit 1
fi

mkdir -p "$OUTPUT_PATH"

curr_date="$START_DATE"

while [ "$curr_date" -le "$END_DATE" ]; do
    yyyy="${curr_date:0:4}"
    yyyymm="${curr_date:0:6}"
    
    tar_path="/NCEPPROD/hpssprod/runhistory/rh${yyyy}/${yyyymm}/${curr_date}/${PRODUCT_NAME}.${curr_date}.tar"
    base_file=$(basename "$TARGET_FILE")

    echo "Processing $curr_date..."

    htar -T "$HTAR_THREADS" -xvf "$tar_path" "$TARGET_FILE"

    if [[ -s "$base_file" ]]; then
        new_name="${curr_date}_${base_file}"
        mv "$base_file" "$new_name"
        mv "$new_name" "$OUTPUT_PATH/"
        echo "Success: Created and moved $new_name to $OUTPUT_PATH/"
    else
        echo "Warning: Extracted file for $curr_date is missing or empty. Skipping."
        [[ -f "$base_file" ]] && rm "$base_file"
    fi
    
    echo "--------------------------------------------------"
    
    curr_date=$(date -d "$curr_date + 1 day" +%Y%m%d)
done

exit 0
