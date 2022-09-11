#!/bin/bash
set -xe

root=$1
shift
cd $root
mount -t proc proc proc
mount -t sysfs sys sys
mount -o bind /dev dev
mount -t tmpfs none dev/shm
mount -o bind /run run
mount -t tmpfs none tmp

set +e
chroot "." "$@"
umount run
umount dev/shm
umount dev
umount proc
umount sys
umount tmp

