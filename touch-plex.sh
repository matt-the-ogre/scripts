#!/bin/bash

# Define the target directory
TARGET_DIR1="/Volumes/Plex/Movies"
TARGET_DIR2="/Volumes/Plex/TV Shows"

# Recursively find all directories and touch them
find "$TARGET_DIR1" -type d -exec touch {} \;
find "$TARGET_DIR2" -type d -exec touch {} \;

echo "Updated timestamps for all directories in $TARGET_DIR1 and $TARGET_DIR2."
