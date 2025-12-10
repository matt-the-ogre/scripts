#!/bin/bash

# Control Elgato Ring Light via HTTP API
# Usage: ./elgato_control.sh [-h hostname] [-o 0|1] [-b 1-100] [-t 143-344] [-s]

hostname="${ELGATO_HOST:-elgato-ring-light-079c.local}"
on=""
brightness=""
temperature=""
status_only=0

show_help() {
    echo "Usage: $0 [-h hostname] [-o 0|1] [-b 1-100] [-t 143-344] [-s]"
    echo "  -h  Hostname (default: $hostname or \$ELGATO_HOST)"
    echo "  -o  On/off (1=on, 0=off)"
    echo "  -b  Brightness (1-100)"
    echo "  -t  Temperature (143=cold/6500K, 344=warm/2900K)"
    echo "  -s  Show current status only"
    exit 0
}

while getopts ":h:o:b:t:s" opt; do
    case ${opt} in
        h ) hostname=$OPTARG ;;
        o ) on=$OPTARG ;;
        b ) brightness=$OPTARG ;;
        t ) temperature=$OPTARG ;;
        s ) status_only=1 ;;
        \? ) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
        : ) echo "Option -$OPTARG requires an argument" >&2; exit 1 ;;
    esac
done

# Resolve hostname to IP
lightIp=$(ping -c 1 -W 1 "$hostname" 2>/dev/null | awk -F'[()]' '/PING/{print $2}')
if [ -z "$lightIp" ]; then
    echo "Error: Could not resolve $hostname"
    exit 1
fi
lightIp="${lightIp}:9123"

# Status query
if [ "$status_only" -eq 1 ]; then
    curl -s "http://$lightIp/elgato/lights" | python3 -m json.tool 2>/dev/null || \
        curl -s "http://$lightIp/elgato/lights"
    exit 0
fi

# Build JSON payload with only specified options
json='{"lights":[{'
parts=()
[ -n "$on" ] && parts+=("\"on\":$on")
[ -n "$brightness" ] && parts+=("\"brightness\":$brightness")
[ -n "$temperature" ] && parts+=("\"temperature\":$temperature")

if [ ${#parts[@]} -eq 0 ]; then
    show_help
fi

json+=$(IFS=,; echo "${parts[*]}")
json+='}]}'

response=$(curl -s -X PUT "http://$lightIp/elgato/lights" \
    -H 'Content-Type: application/json' \
    --data-raw "$json")

echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
