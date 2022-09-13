#!/bin/bash

set -xe -o pipefail

rm -rf initrd
mkdir -p initrd

mkdir -p initrd/dev
mkdir -p initrd/proc
mkdir -p initrd/sys
mkdir -p initrd/tmp
mkdir -p initrd/sbin
mkdir -p initrd/usr/sbin
mkdir -p initrd/run

cd root0

rm -rf root/.mozilla root/.cache root/.dbus root/.config
chmod a+r root/.*
set +e
cpio -p -v -d  -m -0 < ../firebox/touch_files.txt ../initrd
install -m 755 ../firebox/initrd/init ../initrd
cd ..

rm initrd/bin/sh
cp firebox/init_root.sh initrd

chroot initrd /bin/busybox --install


mknod -m 400 initrd/dev/initrd b 1 250
chown root:disk initrd/dev/initrd
mknod -m 600 initrd/dev/console c 5 1
mknod -m 666 initrd/dev/null c 1 3
mknod -m 622 initrd/dev/console c 5 1
mknod -m 666 initrd/dev/null c 1 3
mknod -m 666 initrd/dev/zero c 1 5
mknod -m 666 initrd/dev/ptmx c 5 2
mknod -m 666 initrd/dev/tty c 5 0
mknod -m 444 initrd/dev/random c 1 8
mknod -m 444 initrd/dev/urandom c 1 9
chown -v root:tty initrd/dev/{console,ptmx,tty}

mkdir -p initrd/dev/input

i=0
while [ $i -lt 32 ]
do
    mknod -m 666 initrd/dev/tty$i b 4 $i
    chown root:tty initrd/dev/tty$i

    mknod -m 666 initrd/dev/input/event$i b 13 `expr $i + 64`

    i=`expr $i + 1`
done