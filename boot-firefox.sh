startx &
sleep 10
pkill Xorg

find -amin +1000 -type f -print0 > /touch_files.txt
