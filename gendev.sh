mknod -m 400 initrd/dev/initrd b 1 250
chown root:disk initrd/dev/initrd
mknod -m 600 initrd/dev/console c 5 1
mknod -m 666 initrd/dev/null c 1 3
mknod -m 622 initrd/dev/console c 5 1
mknod -m 666 initrd/dev/null c 1 3
mknod -m 666 initrd/dev/zero c 1 5
mknod -m 666 initrd/dev/ptmx c 5 2
mknod -m 666 initrd/dev/tty c 5 0
mknod -m 444 initrd/dev/random c 1 8
mknod -m 444 initrd/dev/urandom c 1 9
chown -v root:tty initrd/dev/{console,ptmx,tty}

mknod -m 666 initrd/dev/ram0 b 1 0

i=0
while [ "$i" -lt "32" ]
do
    mknod -m 666 initrd/dev/tty$i c 4 $i
    chown root:tty initrd/dev/tty$i
    i=`expr $i + 1`
done

