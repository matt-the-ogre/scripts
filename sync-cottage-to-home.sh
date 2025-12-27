#!/bin/bash

DEBUG=true

# Source and Destination directories
SOURCE1="/Volumes/Plex/Movies"
DESTINATION1="/Volumes/video/Movies"
SOURCE2="/Volumes/Plex/TV Shows"
DESTINATION2="/Volumes/video/TV Shows"

# Rsync options:
# -a : Archive mode (preserves permissions, timestamps, symlinks, etc.)
# -u : Only copy files that are newer than the destination
# -v : Verbose output (optional, remove if not needed)
# -r : Recursive to include subdirectories (redundant with -a but explicitly stated)
# --progress : Show progress (optional)

echo "Starting to copy from $SOURCE1 to $DESTINATION1."

if [ "$DEBUG" = true ]; then
    echo "Dry run enabled. No files will be copied."
    rsync -auvr --dry-run --progress --include="*/" --include="*" "$SOURCE1" "$DESTINATION1"
else
    rsync -auvr --progress "$SOURCE1" "$DESTINATION1"
fi

echo "Sync completed from $SOURCE1 to $DESTINATION1."

echo "Starting to copy from $SOURCE2 to $DESTINATION2."

if [ "$DEBUG" = true ]; then
    rsync -auvr --dry-run --progress --include="*/" --include="*" "$SOURCE2" "$DESTINATION2"
else
    rsync -auvr --progress "$SOURCE2" "$DESTINATION2"
fi
echo "Sync completed from $SOURCE2 to $DESTINATION2."