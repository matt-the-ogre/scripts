#!/bin/bash

# MAC CLEANUP SCRIPT

echo "Starting Mac Cleanup Process"
read -p "Press [Enter] key to start..."

# Empty the Trash
echo "Emptying the Trash..."
sudo rm -rf ~/.Trash/*
echo "Trash emptied."
read -p "Press [Enter] key to continue..."

# Clear System Logs
echo "Clearing system logs..."
sudo rm -rf /var/log/*
sudo rm -rf /Library/Logs/*
echo "System logs cleared."
read -p "Press [Enter] key to continue..."

# Clear Cache Files
echo "Clearing cache files..."
sudo rm -rf ~/Library/Caches/*
sudo rm -rf /Library/Caches/*
sudo rm -rf /System/Library/Caches/*
echo "Cache files cleared."
read -p "Press [Enter] key to continue..."

# Clear Safari Cache
echo "Clearing Safari cache..."
rm -rf ~/Library/Safari/*
echo "Safari cache cleared."
read -p "Press [Enter] key to continue..."

# Remove Mail Downloads
echo "Removing Mail downloads..."
rm -rf ~/Library/Containers/com.apple.mail/Data/Library/Mail\ Downloads/*
echo "Mail downloads removed."
read -p "Press [Enter] key to continue..."

# Optional: Remove old iOS backups
# Uncomment the following lines if you want to remove old iOS backups
#echo "Removing old iOS backups..."
#rm -rf ~/Library/Application\ Support/MobileSync/Backup/*
#echo "iOS backups removed."
#read -p "Press [Enter] key to continue..."

echo "Mac Cleanup Process Completed!"

