#!/bin/bash
fallocate -l 8g root0.8g
mkfs.ext4 root0.8g
mount -o loop root0.8g
sudo rsync -qxaHAXS root0/ root0.mounted/
find root0.mounted -type f -print0 | xargs -0 touch -a -d 1980/01/01

cp boot-firefox.sh root0

bash mount.sh root0 bash boot-firefox.sh
