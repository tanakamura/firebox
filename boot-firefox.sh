startx &
sleep 10
pkill fvwm
pkill Xorg

find -L -mount -not -amin +1000 -type f -print0 > /touch_files.txt
