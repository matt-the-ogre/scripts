#!/bin/bash

# Using the ping command to get the IP address and assign it to the lightIp variable
lightIp=$(ping -c 1 elgato-ring-light-079c.local | awk -F'[()]' '/PING/{print $2}')":9123"

# usage examples
# ./elgato_control.sh -o 1 -b 15 -t 143
# ./elgato_control.sh -o 0
# ./elgato_control.sh -o 1 -b 15
# ./elgato_control.sh -o 1 -t 143

on=1
brightness=15
temperature=143

while getopts ":o:b:t:" opt; do
    case ${opt} in
        o )
            on=$OPTARG
            ;;
        b )
            brightness=$OPTARG
            ;;
        t )
            temperature=$OPTARG
            ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
            exit 1
            ;;
        : )
            echo "Invalid option: $OPTARG requires an argument" 1>&2
            exit 1
            ;;
    esac
done

lightPut=`curl --insecure -X PUT "http://$lightIp/elgato/lights" -H 'Content-Type: application/json' --data-raw '{"lights":[{"temperature":'$temperature',"brightness":'$brightness',"on": '$on'}]}'`

echo "$lightPut"
