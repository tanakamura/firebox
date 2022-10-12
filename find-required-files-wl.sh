set -xe -o pipefail

pushd /firebox/tools/rinit
cargo build --release
cp target/release/rinit /init
popd

find / -mount -type f -print0 | xargs -0 touch -a -d 1980/01/01

busybox ls
eval `dbus-launch`

sleep 1

set +e
#/init dummy
export XDG_RUNTIME_DIR=/run/user/1
seatd-launch -- Hyprland --i-am-really-stupid &
sleep 30

pkill -9 Hyprland
pkill -9 seatd-launch
pkill -9 seatd

sleep 1

busybox rm -rf /root/.mozilla /root/.cache
kill $DBUS_SESSION_BUS_PID

cd /
set +e
find -L ./ -mount -not -name ".cache" -not -name ".mozilla" -not -amin +1000 -type f -print0 > /firebox/touch_files.txt
equery -C f xz-utils eudev kmod | cut -d' ' -f1 > /firebox/additional_files
