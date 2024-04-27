#!/bin/bash

# pass in the directory you want the top-20 file sizes for

echo "Getting file sizes for ", $1, "/*"

# sudo du -sh /Users/mattnoapple/Library/Containers/com.docker.docker/Data/* | sort -rh | head -20 
sudo du -sh $1/* | sort -rh | head -20 