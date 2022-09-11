#!/bin/bash

set -xe

rm -f root0.8g

rm -rf root0.mounted
rm -rf initrd

mkdir -p root0.mounted
mkdir -p initrd

fallocate -l 16g root0.8g
mkfs.ext4 root0.8g
mount -o loop root0.8g root0.mounted

rsync -arAXUHxv --exclude="*/usr/include" --exclude='*/.mozilla' --exclude='*/var/db/repos/gentoo' --exclude='*/.cache' --exclude='*/var/cache/' root0/ root0.mounted
find root0.mounted -mount -type f -print0 | xargs -0 touch -a -d 1980/01/01

cp boot-firefox.sh root0.mounted

bash mount.sh root0.mounted bash /boot-firefox.sh

mkdir initrd
cd root0.8g 
cpio -p -v -d  -m -0 < ./touch_files.txt ../initrd
cd ..
umount root0.mounted
