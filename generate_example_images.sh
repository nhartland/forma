#!/bin/bash
# generate_img.sh
# Generate example images for example gallery
# Requirements:
#  - imagemagick
#  - Input Mono Light font

mkdir -p examples/tmp
mkdir -p examples/img

for file in examples/*.lua; do
    ROOTNAME=$(basename "$file" .lua)
    if [ "$ROOTNAME" = "gallery" ]; then
        echo "Skipping gallery.lua"
        continue
    fi
    echo "$ROOTNAME"
    lua "$file" > "examples/tmp/$ROOTNAME.txt"
    magick -size 650x320 xc:black +antialias -font "InputMono-Light" -pointsize 12 -fill white \
    -annotate +5+12 "@examples/tmp/$ROOTNAME.txt" "./examples/img/$ROOTNAME.png"
done

# Cleanup
rm -rf examples/tmp
