#!/bin/bash

# Scan local network for devices matching a hostname pattern
# Usage: ./ping_for_hostname.sh [hostname_pattern] [subnet] [range_start] [range_end]

partial_hostname="${1:-elgato}"
subnet="${2:-192.168.7}"
range_start="${3:-229}"
range_end="${4:-254}"

echo "Scanning for devices matching '$partial_hostname' on $subnet.$range_start-$range_end"

for ip in $(seq $range_start $range_end); do
    full_ip="$subnet.$ip"
    # Run pings in background for speed, with short timeout
    (
        ping -c 1 -W 1 "$full_ip" &> /dev/null && {
            # Get hostname from ARP table (often includes mDNS names)
            arp_entry=$(arp -a | grep "($full_ip)")
            hostname=$(echo "$arp_entry" | awk '{print $1}')
            mac=$(echo "$arp_entry" | awk '{print $4}')

            if [[ "$hostname" == *"$partial_hostname"* ]]; then
                echo "Found: $hostname - $full_ip ($mac)"
            fi
        }
    ) &
done
wait
