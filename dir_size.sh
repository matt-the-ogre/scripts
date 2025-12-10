#!/bin/bash

# Show largest items in a directory
# Usage: ./dir_size.sh [directory] [count]

dir="${1:-.}"
count="${2:-20}"

# Validate directory exists
if [ ! -d "$dir" ]; then
    echo "Error: '$dir' is not a directory"
    exit 1
fi

echo "Top $count largest items in $dir/"

du -sh "$dir"/* 2>/dev/null | sort -rh | head -"$count"