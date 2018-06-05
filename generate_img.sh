#!/bin/bash
# generate_img.sh
# Generate example images for README
# Requirements:
#  - imagemagick
#  - Input Mono Light font

mkdir tmp

luajit examples/carpet.lua > tmp/header.txt
convert -size 650x320 xc:black +antialias -font "InputMonoL" -pointsize 12 -fill white \
-annotate +5+12 "@tmp/header.txt" img/header.png

luajit examples/game_of_life_async.lua > tmp/symmetry.txt
convert -size 650x320 xc:black +antialias -font "InputMonoL" -pointsize 12 -fill white \
-annotate +5+12 "@tmp/symmetry.txt" img/symmetry.png

luajit examples/caves.lua > tmp/caves.txt
convert -size 650x320 xc:black +antialias -font "InputMonoL" -pointsize 12 -fill white \
-annotate +5+12 "@tmp/caves.txt" img/caves.png

luajit examples/corridors.lua > tmp/corridor.txt
convert -size 650x320 xc:black +antialias -font "InputMonoL" -pointsize 12 -fill white \
-annotate +5+12 "@tmp/corridor.txt" img/corridor.png

rm -rf tmp
