qemu-system-x86_64 -nic bridge,id=br0  -m 2G -serial mon:stdio -hdd esp -bios OVMF.fd -smp 4 -machine type=q35,accel=kvm
