#!/bin/bash

# Check if a filename is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <PDF file>"
    exit 1
fi

PDF_FILE=$1

# Check if the provided file exists
if [ ! -f "$PDF_FILE" ]; then
    echo "Error: File not found - $PDF_FILE"
    exit 1
fi

# Extract the base name without the extension
BASE_NAME=$(basename "$PDF_FILE" .pdf)

# echo the file size in megabytes (MB) of the PDF file
echo "PDF File size: $(du -h "$PDF_FILE" | cut -f1)"

# Convert the PDF to PNG
convert -density 300 "$PDF_FILE" -quality 100 "${BASE_NAME}_%03d.png"

# echo the total file size in megabytes (MB) of the PNG files
echo "PNG Total file size: $(du -h "${BASE_NAME}_"*.png | cut -f1)"

echo "Conversion complete."
