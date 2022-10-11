#!/bin/bash
set -xe

root=$1
shift
cd $root
mount -t proc proc proc
mount -t sysfs sys sys
mount -o bind /dev dev
mount -t tmpfs none dev/shm
mount -t devpts none dev/pts
mount -o bind /run run
mount -t tmpfs none tmp
mkdir -p firebox
mount -o bind ../firebox firebox

export PATH=/sbin:/usr/sbin:/bin:/usr/bin

set +e
chroot "." "$@"
umount firebox
umount run
umount dev/shm
umount dev/pts
umount dev
umount proc
umount sys
umount tmp

