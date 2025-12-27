#!/bin/bash

# Check for coreutils installation for nanosecond support
if ! type gdate > /dev/null; then
  echo "coreutils is not installed. Please install for nanosecond precision using: brew install coreutils"
  exit 1
fi

# Show help
show_help() {
    echo "Usage: $0 <size-in-mb> [--outputFormat <format>]"
    echo ""
    echo "Arguments:"
    echo "  <size-in-mb>              Size of test file in megabytes"
    echo ""
    echo "Options:"
    echo "  --outputFormat <format>   Output format: text, json, or csv (default: text)"
    echo "  --help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 100"
    echo "  $0 500 --outputFormat json"
    echo "  $0 1024 --outputFormat csv"
    exit 0
}

# Parse arguments
OUTPUT_FORMAT="text"
SIZE_MB=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_help
            ;;
        --outputFormat)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        *)
            if [ -z "$SIZE_MB" ]; then
                SIZE_MB="$1"
            else
                echo "Error: Unknown argument '$1'"
                echo "Run '$0 --help' for usage information"
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [ -z "$SIZE_MB" ]; then
    echo "Error: Missing required argument <size-in-mb>"
    echo "Run '$0 --help' for usage information"
    exit 1
fi

# Validate output format
if [[ ! "$OUTPUT_FORMAT" =~ ^(text|json|csv)$ ]]; then
    echo "Error: Invalid output format '$OUTPUT_FORMAT'. Must be text, json, or csv"
    exit 1
fi
# FILENAME=~/testfile_${SIZE_MB}MB
FILENAME=./testfile_${SIZE_MB}MB

# Gather system and device information
TEST_DATE=$(date +%Y-%m-%d)
HOST_NAME=$(scutil --get ComputerName 2>/dev/null || hostname -s)
OS_NAME=$(sw_vers -productName)
OS_VERSION=$(sw_vers -productVersion)

# Get device information from the current directory
DEVICE=$(df . | tail -1 | awk '{print $1}')
VOLUME_NAME=$(df . | tail -1 | awk '{print $9}' | xargs basename)

# Check if it's a network drive
if [[ "$DEVICE" == //* ]]; then
    # Network drive - get filesystem type from mount
    FS_TYPE=$(mount | grep "$VOLUME_NAME" | grep -o '([^,]*' | tr -d '(')
    case "$FS_TYPE" in
        smbfs) DEVICE_TYPE="Network Drive (SMB)" ;;
        nfs) DEVICE_TYPE="Network Drive (NFS)" ;;
        afpfs) DEVICE_TYPE="Network Drive (AFP)" ;;
        *) DEVICE_TYPE="Network Drive" ;;
    esac
    DEVICE_INFO=""
else
    # Local drive - use diskutil
    DEVICE_INFO=$(diskutil info "$DEVICE" 2>/dev/null)

    # Extract device type
    if echo "$DEVICE_INFO" | grep -q "Solid State.*Yes"; then
        if echo "$DEVICE_INFO" | grep -q "Device Location:.*Internal"; then
            DEVICE_TYPE="Internal SSD"
        else
            DEVICE_TYPE="External SSD"
        fi
    elif echo "$DEVICE_INFO" | grep -q "Protocol.*USB"; then
        DEVICE_TYPE="USB Flash Drive"
    else
        DEVICE_TYPE="Unknown"
    fi
fi

# Get capacity
if [ -n "$DEVICE_INFO" ]; then
    # Local drive - extract from diskutil
    CAPACITY_GB=$(echo "$DEVICE_INFO" | grep "Disk Size:" | awk '{print $3}')
else
    # Network drive - calculate from df (in KB, convert to GB)
    TOTAL_KB=$(df -k . | tail -1 | awk '{print $2}')
    CAPACITY_GB=$(echo "scale=1; $TOTAL_KB / 1024 / 1024" | bc)
fi

# Get percent full (use df -k for consistent output)
PERCENT_USED=$(df -k . | tail -1 | awk '{gsub(/%/, "", $5); print $5}')
PERCENT_FULL=$(echo "scale=2; $PERCENT_USED / 100" | bc)

# Create a file of the specified size with dd and time the operation
echo "Starting disk speed test (${SIZE_MB}MB)..."
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

# Calculate speeds
WRITE_SPEED=$(echo "scale=0; $SIZE_MB / $WRITE_TIME" | bc)
READ_SPEED=$(echo "scale=0; $SIZE_MB / $READ_TIME" | bc)

# Display results based on output format
echo ""

if [ "$OUTPUT_FORMAT" = "json" ]; then
    cat <<EOF
{
  "test_date": "$TEST_DATE",
  "host": "$HOST_NAME",
  "os": "$OS_NAME $OS_VERSION",
  "volume_name": "$VOLUME_NAME",
  "device_type": "$DEVICE_TYPE",
  "capacity_gb": "$CAPACITY_GB",
  "percent_full": "$PERCENT_FULL",
  "test_size_mb": "$SIZE_MB",
  "write_speed_mbps": "$WRITE_SPEED",
  "read_speed_mbps": "$READ_SPEED"
}
EOF

elif [ "$OUTPUT_FORMAT" = "csv" ]; then
    echo "test_date,host,os,volume_name,device_type,capacity_gb,percent_full,test_size_mb,write_speed_mbps,read_speed_mbps"
    echo "$TEST_DATE,$HOST_NAME,$OS_NAME $OS_VERSION,$VOLUME_NAME,$DEVICE_TYPE,$CAPACITY_GB,$PERCENT_FULL,$SIZE_MB,$WRITE_SPEED,$READ_SPEED"

else
    # text format (default)
    echo "=========================================="
    echo "Disk Speed Test Results"
    echo "=========================================="
    echo "Test Date:        $TEST_DATE"
    echo "Host:             $HOST_NAME"
    echo "OS:               $OS_NAME $OS_VERSION"
    echo "Volume Name:      $VOLUME_NAME"
    echo "Device Type:      $DEVICE_TYPE"
    echo "Capacity:         ${CAPACITY_GB} GB"
    echo "Percent Full:     $PERCENT_FULL"
    echo "Test Size:        ${SIZE_MB} MB"
    echo "----------------------------------------"
    echo "Write Speed:      ${WRITE_SPEED} MB/sec"
    echo "Read Speed:       ${READ_SPEED} MB/sec"
    echo "=========================================="
fi
