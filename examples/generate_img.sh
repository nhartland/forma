#!/bin/bash
# generate_img.sh
# Generate example images for example gallery
# Requirements:
#  - imagemagick
#  - Input Mono Light font

mkdir tmp
mkdir img

for file in *.lua; do
    root="${file%.*}"
    echo $root
    luajit $file > tmp/$root.txt
    convert -size 650x320 xc:black +antialias -font "InputMonoL" -pointsize 12 -fill white \
    -annotate +5+12 "@tmp/$root.txt" ./img/$root.png
done

rm -rf tmp
