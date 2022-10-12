firebox_path=$( dirname -- $(readlink -f ${BASH_SOURCE} ) )/..
firebox_path=$(readlink -f $firebox_path)

rootpath=$firebox_path/work/root
image=$firebox_path/work/root0.8g
kernel=$firebox_path/work/linux

mount_root0 () {
    sudo mount -o loop $image $rootpath
}

unmount_root0 () {
    sudo umount $rootpath
}


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

firebox_nspawn () {
    mount_root0
    sudo systemd-nspawn --bind $firebox_path:/firebox -D $rootpath /firebox/guest/guest-entry.sh $@
    unmount_root0
}

run_emerge () {
    mount_root
    sudo chroot $rootpath /bin/bash /firebox/guest/guest-entry.sh bash /firebox/guest/emerge.sh
    unmount_root
}

firebox_reload () {
    source $firebox_path/host/firebox-host.sh
}

run_installer () {
    pushd $firebox_path/work

    rm -f overlay.cow
    qemu-img create -o backing_file=root0.8g,backing_fmt=raw -f qcow2 overlay.cow

    qemu-system-x86_64 -kernel linux/arch/x86/boot/bzImage -m 2G -serial mon:stdio \
         -nic bridge,id=br0 -smp 4 -machine type=q35,accel=kvm \
         -append "console=ttyS0 root=/dev/vda rw init=/init" \
         -drive id=disk,file=overlay.cow,if=virtio \
         -display gtk,gl=on \
         -device virtio-vga-gl

    popd
}

install_rinit () {
    pushd $firebox_path/tools/rinit
    cargo build 
    popd

    mount_root0
    sudo cp $firebox_path/tools/rinit/target/debug/rinit $rootpath/init
    unmount_root0
}

echo "firebox_path = $firebox_path"

