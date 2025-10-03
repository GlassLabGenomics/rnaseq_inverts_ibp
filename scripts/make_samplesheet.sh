#!/bin/bash

# Set working directory to the script's location (optional but useful)
cd "$(dirname "$0")"

# Define the rawdata directory, output
RAWDATA_DIR="rawdata"
OUTPUT_FILE="samplesheet_rnaseq.csv"

# Define the header
HEADER="sample,fastq_1,fastq_2,strandedness"

# Remove the output file if it already exists
rm -f "$OUTPUT_FILE"

# Check if rawdata directory exists
if [ ! -d "$RAWDATA_DIR" ]; then
    echo "Directory '$RAWDATA_DIR' not found."
    exit 1
fi

# Initialise an empty samplesheet template file
echo "$HEADER" > $OUTPUT_FILE

# Loop through all subdirectories in rawdata
find "$RAWDATA_DIR" -type d -name "UAFJRG*" | while read dir; do
    echo "Processing: $dir"
    SAMPLE=$(basename ${dir})
    CONTENTS=( $(ls ${dir}/*'fq.gz') )

    echo "$SAMPLE,${CONTENTS[0]},${CONTENTS[1]},auto" >> $OUTPUT_FILE

done


