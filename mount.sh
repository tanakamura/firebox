#!/bin/bash
# set -xe

mount -t proc proc proc
mount -t sysfs sys sys
mount -o bind /dev dev
mount -t tmpfs none dev/shm
mount -t tmpfs none run
mount -t tmpfs none tmp
chroot "$1" "$2"
umount run
umount dev/shm
umount dev
umount proc
umount sys
umount tmp

