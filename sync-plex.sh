#!/bin/bash

# Define source and destination folders
source_folder="$HOME/Plex"
destination_folder="/Library/CloudStorage/SynologyDrive-mattnoapple/Plex"

# Perform two-way synchronization without deletions
rsync -avh --update "$source_folder/" "$destination_folder/"
rsync -avh --update "$destination_folder/" "$source_folder/"

echo "Two-way sync completed without deletions!"
