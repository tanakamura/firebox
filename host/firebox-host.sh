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

firebox_initrd_nspawn () {
    initrd=$firebox_path/work/initrd
    sudo systemd-nspawn --bind $firebox_path:/firebox -D $initrd
}

run_emerge () {
    mount_root
    sudo chroot $rootpath /bin/bash /firebox/guest/guest-entry.sh bash /firebox/guest/emerge.sh
    unmount_root
}

firebox_reload () {
    source $firebox_path/host/firebox-host.sh
}


run_qemu () {
    file=$1
    qemu-system-x86_64 -kernel linux/arch/x86/boot/bzImage -m 2G -serial mon:stdio \
         -nic bridge,id=br0 -smp 4 -machine type=q35,accel=kvm \
         -append "console=ttyS0 root=/dev/vda rw init=/init" \
         -drive id=disk,file=$file,if=virtio \
         -display gtk,gl=on \
         -device virtio-vga-gl
}

install_config () {
    mount_root0

    sudo cp $firebox_path/configs/$1 $rootpath/etc/firebox.json

    unmount_root0
}

run_installer () {
    install_config installer.json

    pushd $firebox_path/work
    run_qemu root0.8g
    popd
}

test_installer () {
    install_config run.json

    pushd $firebox_path/work

    rm -f overlay.cow
    qemu-img create -o backing_file=root0.8g,backing_fmt=raw -f qcow2 overlay.cow

    run_qemu overlay.cow

    popd
}

extract_touched_files () {
    initrd=$firebox_path/work/initrd
    sudo rm -rf $initrd
    sudo mkdir -p $initrd

    sudo mkdir -p $initrd/dev
    sudo mkdir -p $initrd/proc
    sudo mkdir -p $initrd/sys
    sudo mkdir -p $initrd/tmp
    sudo mkdir -p $initrd/run

    mount_root0

    sudo cp $rootpath/init $initrd/init
    pushd $rootpath
    cat touch_files.txt | sudo cpio -p -v -d -m -0 $initrd
    sed s/^/./g < additional_files.txt | sudo cpio -p -v -d  -m $initrd
    sudo cp $root/bin/busybox $initrd/bin/busybox
    popd

    unmount_root0

    sudo rm -rf $initrd/root/.*
    sudo rm -rf $initrd/root/*

    pushd $initrd
    cat $firebox_path/remove-list.txt | sudo xargs rm
    sudo rm -rf $initrd/usr/share/man
    sudo rm -rf $initrd/usr/share/doc
    sudo rm -rf $initrd/usr/share/bash-completion
    sudo rm -rf $initrd/usr/lib64/pkgconfig
    sudo rm -rf $initrd/usr/include
    sudo rm $initrd/etc/firebox.json
    popd

    sudo rsync -arAHX $firebox_path/initrd/ $initrd

    sudo systemd-nspawn -D $initrd /bin/busybox --install

    pushd $initrd
    sudo chown -R root:root .
    sudo find -print0 | sudo cpio -0 -o -H newc | zstd -9 > $firebox_path/work/firebox_initrd.zstd
    popd
    bytes=$(stat -c '%s' $firebox_path/work/firebox_initrd.zstd)
    echo initrd : $(($bytes / (1024*1024)))MiB
}


install_rinit () {
    pushd $firebox_path/tools/rinit
    cargo build --release
    popd

    mount_root0
    sudo cp $firebox_path/tools/rinit/target/release/rinit $rootpath/init
    unmount_root0
}

run_initrd () {
    pushd $firebox_path/work
    qemu-system-x86_64 -kernel linux/arch/x86/boot/bzImage -initrd firebox_initrd.zstd -m 2G -serial mon:stdio -nic bridge,id=br0 -smp 4 -machine type=q35,accel=kvm -append "console=ttyS0" -display gtk,gl=on -device virtio-vga-gl
    popd
}

echo "firebox_path = $firebox_path"

