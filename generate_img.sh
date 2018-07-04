#!/bin/bash
# generate_img.sh
# Generate example images for README
# Requirements:
#  - imagemagick
#  - Input Mono Light font

IMG_TARGET=./

mkdir tmp

SOURCES=( carpet game_of_life_async caves corridors worley )

for i in "${SOURCES[@]}"; do
    echo $i
    luajit examples/$i.lua > tmp/$i.txt
    convert -size 650x320 xc:black +antialias -font "InputMonoL" -pointsize 12 -fill white \
    -annotate +5+12 "@tmp/$i.txt" $IMG_TARGET/$i.png
done

rm -rf tmp
