N=11
losetup -fP esp
mount /dev/loop${N}p1 boot
cp -L bzImage boot/bzImage.efi
cp -L firebox_initrd.zstd boot/initrd
umount boot
losetup --detach /dev/loop11
