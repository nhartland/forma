#!/bin/bash
# generate_img.sh
# Generate example images for example gallery
# Requirements:
#  - imagemagick
#  - Input Mono Light font

mkdir examples/tmp
mkdir examples/img

for file in examples/*.lua; do
    ROOTNAME=$(basename "$file" .lua)
    echo "$ROOTNAME"
    lua "$file" > "examples/tmp/$ROOTNAME.txt"
    convert -size 650x320 xc:black +antialias -font "InputMonoL" -pointsize 12 -fill white \
    -annotate +5+12 "@examples/tmp/$ROOTNAME.txt" "./examples/img/$ROOTNAME.png"
done

# Cleanup
rm -rf examples/tmp
