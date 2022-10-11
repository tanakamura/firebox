exec qemu-system-x86_64 -kernel bzImage -initrd firebox_initrd.zstd -m 2G -serial mon:stdio -nic bridge,id=br0 -smp 4 -machine type=q35,accel=kvm -append "console=ttyS0" -display gtk,gl=on -device virtio-vga-gl

#exec qemu-system-x86_64 -kernel bzImage -m 2G -serial mon:stdio -nic bridge,id=br0 -smp 4 -machine type=q35,accel=kvm -append "console=ttyS0"
#exec qemu-system-x86_64 -m 2G -serial mon:stdio -netdev bridge,id=br0 -smp 4 -machine type=q35,accel=kvm -cdrom /mnt/storage/image/ubuntu-22.04.1-desktop-amd64.iso

#qemu-system-x86_64 -kernel bzImage -initrd ./arch.zstd -m 1G -append "console=ttyS0 init=/bin/bash" -nographic
#qemu-system-x86_64 -kernel /boot/vmlinuz-linux -initrd ./initramfs-linux.img -m 1G -append "console=ttyS0 init=/bin/bash quiet loglevel=7" -nographic 

