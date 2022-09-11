#!/bin/bash

set -xe

cd root0.initrd

rm -rf root/.mozilla root/.cache root/.dbus root/.config
find -print0 | cpio -0 -o -H newc | lzma -9 > ../firebox.cpio.lzma
