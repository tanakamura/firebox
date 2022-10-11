sudo umount root0

set -xe -o pipefail

rm -f overlay.cow
qemu-img create -o backing_file=root0.8g,backing_fmt=raw -f qcow2 overlay.cow

exec qemu-system-x86_64 -kernel firebox/linux-5.19.8/arch/x86/boot/bzImage -m 2G -serial mon:stdio \
-nic bridge,id=br0 -smp 4 -machine type=q35,accel=kvm \
-append "console=ttyS0 root=/dev/vda rw init=/bin/bash" \
-drive id=disk,file=overlay.cow,if=virtio \
-display gtk,grab-on-hover=on,gl=on \
-device virtio-vga-gl
