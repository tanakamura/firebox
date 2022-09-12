exec qemu-system-x86_64 -kernel bzImage -initrd firebox_initrd.zstd -m 2G -serial mon:stdio -smp 4 -machine type=q35,accel=kvm
#qemu-system-x86_64 -kernel bzImage -initrd ./arch.zstd -m 1G -append "console=ttyS0 init=/bin/bash" -nographic
#qemu-system-x86_64 -kernel /boot/vmlinuz-linux -initrd ./initramfs-linux.img -m 1G -append "console=ttyS0 init=/bin/bash quiet loglevel=7" -nographic 

