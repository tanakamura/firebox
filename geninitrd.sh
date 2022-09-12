#!/bin/bash

set -xe

rm -rf root0.initrd
mkdir -p root0.initrd
cd root0.initrd

find -print0 | cpio -0 -o -H newc | lzma -9 > ../firebox.cpio.lzma
#find -print0 | cpio -0 -p -m ../root0.initrd
