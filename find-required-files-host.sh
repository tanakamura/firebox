set -xe -o pipefail

#xhost +local:

root=$1
shift
cd $root

mkdir -p firebox
mkdir -p run/udev

mount -o bind /dev dev
mount -o bind ../firebox firebox
mount -o bind /run/udev run/udev
mount -t devpts none dev/pts

mount -t proc proc proc
mount -t sysfs sys sys

set +e
chroot "." "$@"
umount firebox
umount run/udev
umount dev/pts
umount dev
umount proc
umount sys
