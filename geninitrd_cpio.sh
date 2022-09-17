#!/bin/bash
set -xe -o pipefail

FIREBOX=$(readlink -f $(dirname "$0"))

cd initrd
cp ${FIREBOX}/initrd/root/.xinitrc root/.xinitrc
#mkdir -p etc/X11/xorg.conf.d
#cp ${FIREBOX}/xorg.conf.d/*.conf etc/X11/xorg.conf.d

find -print0 | cpio -0 -o -H newc | zstd -9 > ../firebox/qemu/firebox_initrd.zstd
#find -print0 | cpio -0 -o -H newc | lzma -9 > ../firebox/qemu/firebox_initrd.lzma
