#!/bin/bash

# a utility script to use sysbench to test disk speed and write the report to a file
# usage: ./sysbench_disk.sh <size-in-mb> <output-file>
# example: ./sysbench_disk.sh 1024 disk_speed_report.txt

# Check if the parameter is provided
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <size-in-mb> <output-file>"
  exit 1
fi

# Set the size in MB
SIZE_MB=$1
OUTPUT_FILE=$2

# Run sysbench disk test and write the output to the specified file
# prepare the test
sysbench fileio --file-total-size=${SIZE_MB}M prepare
# random read
sysbench fileio --file-total-size=${SIZE_MB}M --file-test-mode=rndrw --time=60 --max-requests=0 run > ${OUTPUT_FILE}
# random write, append to the file
sysbench fileio --file-total-size=${SIZE_MB}M --file-test-mode=rndwr --time=60 --max-requests=0 run >> ${OUTPUT_FILE}
# sequential read, append to the file
sysbench fileio --file-total-size=${SIZE_MB}M --file-test-mode=seqrd --time=60 --max-requests=0 run >> ${OUTPUT_FILE}
# sequential write, append to the file
sysbench fileio --file-total-size=${SIZE_MB}M --file-test-mode=seqwr --time=60 --max-requests=0 run >> ${OUTPUT_FILE}
# cleanup
sysbench fileio --file-total-size=${SIZE_MB}M cleanup

echo "Disk speed test completed. Results written to ${OUTPUT_FILE}."
