#!/bin/bash

#Genereate Stars:
for n in {1..3}
do
    convert -size  842x1142 xc: +noise Random -channel R -threshold .02% \
              -negate -channel RG -separate +channel \
              \( +clone \) -compose multiply -flatten \
              -virtual-pixel tile  -blur 0x.3 \
              \( -clone 0  -motion-blur 0x10+15  -motion-blur 0x10+195 \) \
              \( -clone 0  -motion-blur 0x10+75  -motion-blur 0x10+255 \) \
              \( -clone 0  -motion-blur 0x10-45  -motion-blur 0x10+135 \) \
              -compose screen -background transparent -flatten  -normalize \
              star_field$n.gif
done

#Make gif:

convert resizedfinal.png   -compose Screen \
      \( -clone 0 star_field1.gif -composite \) \
      \( -clone 0 star_field2.gif -composite \) \
      \( -clone 0 star_field3.gif -composite \) \
      -delete 0 -set delay 25 -layers Optimize rose_sparkle.gif
rm star_field[123].gif

#src
#http://www.imagemagick.org/Usage/anim_basics/
