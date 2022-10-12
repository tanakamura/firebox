firebox_path=$( dirname -- $(readlink -f ${BASH_SOURCE} ) )/..
firebox_path=$(readlink -f $firebox_path)

rootpath=$firebox_path/work/root
image=$firebox_path/work/root0.8g
kernel=$firebox_path/work/linux

mount_root () {
    sudo mount -o loop $image $rootpath

    sudo mount -t proc proc $rootpath/proc
    sudo mount -t sysfs sys $rootpath/sys
    sudo mount -o bind /dev $rootpath/dev
    sudo mount -t tmpfs none $rootpath/dev/shm
    sudo mount -t devpts none $rootpath/dev/pts
    sudo mount -o bind /run $rootpath/run
    sudo mount -t tmpfs none $rootpath/tmp
    sudo mkdir -p $rootpath/firebox
    sudo mount -o bind ../firebox $rootpath/firebox
}

unmount_root () {
    sudo umount $rootpath/firebox
    sudo umount $rootpath/run
    sudo umount $rootpath/dev/shm
    sudo umount $rootpath/dev/pts
    sudo umount $rootpath/dev
    sudo umount $rootpath/proc
    sudo umount $rootpath/sys
    sudo umount $rootpath/tmp

    sudo umount $rootpath
}

chroot_to_gentoo () {
    mount_root
    sudo chroot $rootpath /bin/bash /firebox/guest/guest-entry.sh
    unmount_root
}

run_emerge () {
    mount_root
    sudo chroot $rootpath /bin/bash /firebox/guest/guest-entry.sh bash /firebox/guest/emerge.sh
    unmount_root

}

echo "firebox_path = $firebox_path"

