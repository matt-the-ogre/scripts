#!/bin/bash

# Define the partial hostname
partial_hostname="elgato"

# Ping your local network subnet
for ip in 192.168.7.{229..254}; do
    echo "Pinging $ip"
  # Ping each IP address
  ping -c 1 $ip &> /dev/null

  # Check if the device responds
  if [ $? -eq 0 ]; then
    # Get the MAC address from the ARP table
    mac=$(arp -a | grep "$ip" | awk '{print $4}')
    echo "MAC: $mac"

    # Check if the MAC address exists
    if [ ! -z "$mac" ]; then
      # Search for the device by hostname using the MAC address
      hostname=$(grep -i "$partial_hostname" /etc/hosts | awk '{print $2}')

      # If a matching hostname is found, print the details
      if [[ $hostname == *"$partial_hostname"* ]]; then
        echo "Device found: $hostname, IP: $ip, MAC: $mac"
      fi
    fi
  fi
done
