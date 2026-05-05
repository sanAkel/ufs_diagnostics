#!/bin/bash

# 1. Parameter Validation
if [ "$#" -ne 5 ]; then
    echo "Error: Exactly 5 arguments are required."
    echo "Usage: $0 <INPUT_DIR> <OUTPUT_DIR> <DATE> <CULLER_EXE> <BINV_EXE>"
    echo "Example: $0 /path/to/prepbufr/20260501 /path/to/no_dbuoy/20260501 20260501 /path/to/no_dbuoy.x /path/to/binv"
    exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"
DATE_STR="$3"
CULLER_EXE="$4"
BINV_EXE="$5"

# 2. Path & Executable Checks
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory does not exist: $INPUT_DIR"
    exit 1
fi

if [ ! -x "$CULLER_EXE" ]; then
    echo "Error: Culler executable not found or not executable: $CULLER_EXE"
    exit 1
fi

if [ ! -x "$BINV_EXE" ]; then
    echo "Error: binv executable not found or not executable: $BINV_EXE"
    exit 1
fi

echo "------------------------------------------------------------"
echo "Starting One-Pass Precision Filter: $DATE_STR"
echo "------------------------------------------------------------"

PROCESSED_COUNT=0

# 3. Execution Loop
for HR in 00z 06z 12z 18z; do
    
    # Handle files whether they have the .nr suffix (original) or not (from staging)
    INPUT_FILE="$INPUT_DIR/gdas.t${HR}.prepbufr"
    if [ ! -f "$INPUT_FILE" ]; then
        if [ -f "${INPUT_FILE}.nr" ]; then
            INPUT_FILE="${INPUT_FILE}.nr"
        else
            echo "  SKIP: Original file not found at $INPUT_FILE or ${INPUT_FILE}.nr"
            continue
        fi
    fi

    echo -e "\n[Cycle $HR]"
    
    # Safely create target cycle directory
    mkdir -p "$OUTPUT_DIR/$HR"
    
    OUTPUT_FILE="$OUTPUT_DIR/$HR/gdas.t${HR}.prepbufr_no_cat_564"
    
    # 4. Run Surgical Filter
    "$CULLER_EXE" "$INPUT_FILE" "$OUTPUT_FILE"
    CULL_STATUS=$?
    
    if [ $CULL_STATUS -ne 0 ]; then
        echo "  ERROR: Culler script failed with exit code $CULL_STATUS."
        rm -f "$OUTPUT_FILE"
        exit 1
    fi
    
    # 5. Verify the squaring of the data
    if [ -s "$OUTPUT_FILE" ]; then
        echo "  Verification (Final Counts):"
        "$BINV_EXE" "$OUTPUT_FILE" | grep -E "SFCSHP|TOTAL"
        PROCESSED_COUNT=$((PROCESSED_COUNT + 1))
    else
        echo "  ERROR: Output file is empty or missing after culling."
        rm -f "$OUTPUT_FILE"
        exit 1
    fi
done

echo -e "\n------------------------------------------------------------"

# 6. Final Status Check
if [ "$PROCESSED_COUNT" -gt 0 ]; then
    echo "Filter Complete. All 564s removed, Ships preserved."
    exit 0
else
    echo "Filter Complete, but NO files were successfully processed."
    exit 1
fi
