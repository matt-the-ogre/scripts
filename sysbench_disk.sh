#!/bin/bash

# Check for sysbench installation
if ! type sysbench > /dev/null 2>&1; then
  echo "sysbench is not installed. Please install using: brew install sysbench"
  exit 1
fi

# Show help
show_help() {
    echo "Usage: $0 <size-in-mb> [--outputFormat <format>] [--saveRaw <file>]"
    echo ""
    echo "Arguments:"
    echo "  <size-in-mb>              Size of test files in megabytes"
    echo ""
    echo "Options:"
    echo "  --outputFormat <format>   Output format: text, json, or csv (default: text)"
    echo "  --saveRaw <file>          Save raw sysbench output to file (optional)"
    echo "  --help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 1024"
    echo "  $0 1024 --outputFormat json"
    echo "  $0 1024 --saveRaw results.txt"
    echo "  $0 1024 --outputFormat csv --saveRaw results.txt"
    exit 0
}

# Parse arguments
OUTPUT_FORMAT="text"
SIZE_MB=""
RAW_OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --help)
            show_help
            ;;
        --outputFormat)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        --saveRaw)
            RAW_OUTPUT_FILE="$2"
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

# Create temporary files for raw output
TEMP_DIR=$(mktemp -d)
RNDRW_OUT="${TEMP_DIR}/rndrw.txt"
RNDRD_OUT="${TEMP_DIR}/rndrd.txt"
RNDWR_OUT="${TEMP_DIR}/rndwr.txt"
SEQRD_OUT="${TEMP_DIR}/seqrd.txt"
SEQWR_OUT="${TEMP_DIR}/seqwr.txt"

echo "Starting sysbench disk test (${SIZE_MB}MB)..."

# Prepare the test files
echo "Preparing test files..."
sysbench fileio --file-total-size=${SIZE_MB}M prepare > /dev/null 2>&1

# Run tests
echo "Running random read/write test..."
sysbench fileio --file-total-size=${SIZE_MB}M --file-test-mode=rndrw --time=30 --max-requests=0 run > "$RNDRW_OUT" 2>&1

echo "Running random read test..."
sysbench fileio --file-total-size=${SIZE_MB}M --file-test-mode=rndrd --time=30 --max-requests=0 run > "$RNDRD_OUT" 2>&1

echo "Running random write test..."
sysbench fileio --file-total-size=${SIZE_MB}M --file-test-mode=rndwr --time=30 --max-requests=0 run > "$RNDWR_OUT" 2>&1

echo "Running sequential read test..."
sysbench fileio --file-total-size=${SIZE_MB}M --file-test-mode=seqrd --time=30 --max-requests=0 run > "$SEQRD_OUT" 2>&1

echo "Running sequential write test..."
sysbench fileio --file-total-size=${SIZE_MB}M --file-test-mode=seqwr --time=30 --max-requests=0 run > "$SEQWR_OUT" 2>&1

# Cleanup
echo "Cleaning up..."
sysbench fileio --file-total-size=${SIZE_MB}M cleanup > /dev/null 2>&1

# Parse results
parse_throughput() {
    grep "written, MiB/s:" "$1" | awk '{print $NF}' | head -1
}

parse_read_throughput() {
    grep "read, MiB/s:" "$1" | awk '{print $NF}' | head -1
}

# Extract metrics (convert MiB/s to MB/s)
RNDRW_THROUGHPUT=$(parse_throughput "$RNDRW_OUT")
RNDRD_THROUGHPUT=$(parse_read_throughput "$RNDRD_OUT")
RNDWR_THROUGHPUT=$(parse_throughput "$RNDWR_OUT")
SEQRD_THROUGHPUT=$(parse_read_throughput "$SEQRD_OUT")
SEQWR_THROUGHPUT=$(parse_throughput "$SEQWR_OUT")

# Convert MiB/s to MB/s (multiply by 1.048576)
convert_to_mbs() {
    echo "scale=0; $1 * 1.048576" | bc 2>/dev/null || echo "0"
}

RNDRW_MBPS=$(convert_to_mbs "$RNDRW_THROUGHPUT")
RNDRD_MBPS=$(convert_to_mbs "$RNDRD_THROUGHPUT")
RNDWR_MBPS=$(convert_to_mbs "$RNDWR_THROUGHPUT")
SEQRD_MBPS=$(convert_to_mbs "$SEQRD_THROUGHPUT")
SEQWR_MBPS=$(convert_to_mbs "$SEQWR_THROUGHPUT")

# Save raw output if requested
if [ -n "$RAW_OUTPUT_FILE" ]; then
    cat "$RNDRW_OUT" "$RNDRD_OUT" "$RNDWR_OUT" "$SEQRD_OUT" "$SEQWR_OUT" > "$RAW_OUTPUT_FILE"
    echo "Raw output saved to: $RAW_OUTPUT_FILE" >&2
fi

# Clean up temp files
rm -rf "$TEMP_DIR"

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
  "random_read_write_mbps": "$RNDRW_MBPS",
  "random_read_mbps": "$RNDRD_MBPS",
  "random_write_mbps": "$RNDWR_MBPS",
  "sequential_read_mbps": "$SEQRD_MBPS",
  "sequential_write_mbps": "$SEQWR_MBPS"
}
EOF

elif [ "$OUTPUT_FORMAT" = "csv" ]; then
    echo "test_date,host,os,volume_name,device_type,capacity_gb,percent_full,test_size_mb,random_read_write_mbps,random_read_mbps,random_write_mbps,sequential_read_mbps,sequential_write_mbps"
    echo "$TEST_DATE,$HOST_NAME,$OS_NAME $OS_VERSION,$VOLUME_NAME,$DEVICE_TYPE,$CAPACITY_GB,$PERCENT_FULL,$SIZE_MB,$RNDRW_MBPS,$RNDRD_MBPS,$RNDWR_MBPS,$SEQRD_MBPS,$SEQWR_MBPS"

else
    # text format (default)
    echo "=========================================="
    echo "Sysbench Disk Test Results"
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
    echo "Random Read/Write: ${RNDRW_MBPS} MB/s"
    echo "Random Read:       ${RNDRD_MBPS} MB/s"
    echo "Random Write:      ${RNDWR_MBPS} MB/s"
    echo "Sequential Read:   ${SEQRD_MBPS} MB/s"
    echo "Sequential Write:  ${SEQWR_MBPS} MB/s"
    echo "=========================================="
fi
