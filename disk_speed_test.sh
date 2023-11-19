#!/bin/bash

# Check for coreutils installation for nanosecond support
if ! type gdate > /dev/null; then
  echo "coreutils is not installed. Please install for nanosecond precision using: brew install coreutils"
  exit 1
fi

# Check if the parameter is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <size-in-mb>"
  exit 1
fi

# Set the size in MB
SIZE_MB=$1
# FILENAME=~/testfile_${SIZE_MB}MB
FILENAME=./testfile_${SIZE_MB}MB

# Create a file of the specified size with dd and time the operation
echo "Writing ${SIZE_MB}MB..."
WRITE_START_TIME=$(gdate +%s.%N)
dd if=/dev/zero of=${FILENAME} bs=1m count=$(($SIZE_MB)) conv=sync
WRITE_END_TIME=$(gdate +%s.%N)

# Calculate write time
WRITE_TIME=$(echo "$WRITE_END_TIME - $WRITE_START_TIME" | bc)
echo "Write Time: $WRITE_TIME seconds"

# Clear cache to ensure accurate read timing
# Note: 'purge' requires sudo permissions, you may need to run the script as root
echo "Clearing cache..."
sudo purge

# Read the file back and time the operation
echo "Reading ${SIZE_MB}MB..."
READ_START_TIME=$(gdate +%s.%N)
dd if=${FILENAME} of=/dev/null bs=1m
READ_END_TIME=$(gdate +%s.%N)

# Calculate read time
READ_TIME=$(echo "$READ_END_TIME - $READ_START_TIME" | bc)
echo "Read Time: $READ_TIME seconds"

# Clean up
rm ${FILENAME}

# Report the results
echo "Write and read operations completed."
echo "Write took $WRITE_TIME seconds. That is $(echo "scale=3; $WRITE_TIME / $SIZE_MB" | bc) seconds per MB or $(echo "scale=4; $SIZE_MB / $WRITE_TIME" | bc) MB/sec."
echo "Read took $READ_TIME seconds. That is $(echo "scale=3; $READ_TIME / $SIZE_MB" | bc) seconds per MB  or $(echo "scale=4; $SIZE_MB / $READ_TIME" | bc) MB/sec."
