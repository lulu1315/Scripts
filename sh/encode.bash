#!/bin/bash

proj=$1
shot=$2
name=$3

ffmpeg -gamma 2.2 -i $proj/render/$shot/$name.%04d.exr -c:v prores -profile:v 3 $proj\_$shot\_$name.mov
#-gamma 2.2
