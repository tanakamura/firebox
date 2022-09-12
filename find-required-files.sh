set -xe -o pipefail

find / -mount -type f -print0 | xargs -0 touch -a -d 1980/01/01

busybox ls
busybox mkdir -p /etc/X11/xorg.conf.d
busybox cp /firebox/xorg.conf.d/*.conf /etc/X11/xorg.conf.d

xinit -- :2

sleep 1

busybox rm -rf /root/.mozilla /root/.cache

cd /
find -L ./ -mount -not -name ".cache" -not -name ".mozilla" -not -amin +1000 -type f -print0 > /firebox/touch_files.txt
