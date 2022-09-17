set -xe -o pipefail

cp /firebox/tools/init /init
chmod a+x /init
cp /firebox/initrd/root/.xinitrc /root/.xinitrc

find / -mount -type f -print0 | xargs -0 touch -a -d 1980/01/01

busybox ls
busybox mkdir -p /etc/X11/xorg.conf.d
#busybox cp /firebox/xorg.conf.d/*.conf /etc/X11/xorg.conf.d
eval `dbus-launch`

sleep 1

/init dummy

sleep 1

busybox rm -rf /root/.mozilla /root/.cache
kill $DBUS_SESSION_BUS_PID

cd /
set +e
find -L ./ -mount -not -name ".cache" -not -name ".mozilla" -not -amin +1000 -type f -print0 > /firebox/touch_files.txt
equery -C f xz-utils eudev kmod | cut -d' ' -f1 > /firebox/additional_files
