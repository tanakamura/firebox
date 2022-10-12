USE0="-objc -objc++ -openmp -installkernel symlink -static -gdc -gcj -fortran -go -nscd -ssp -selinux -systemd"
USE0="$USE0 -systemtap -compile-locales -cet -caps -audit -cgroup-hybrid -policykit -pcre -nls "
USE0="$USE0 -doc -man -gtk-doc -cups -sysprof -colord -test -acl -zstd -mime ncurses -gnome -graphite -nls -iconv"
USE0="$USE0 -gmp-autoupdate -xattr -cairo -vala -icu -clang -crypt"
USE0="$USE0 -snapshot -examples -system-jpeg -system-harfbuzz -system-av1 -system-libvpx -system-webp -system-icu -system-libevent"
USE0="$USE0 -openh264 -encode -gnutls -binutils-plugin -libffi -asan -cfi -dfsan -gwp-asan -hwasan -libfuzzer -lsan -msan -safestack -scudo -tsan -ubsan"
USE0="$USE0 -static-analyzer -memprof -compiler-rt -profile -xray -sanitize -e2fsprog "
USE0="$USE0 -ensurepip -python -llvm -pulseaudio -clang -elogind -modemmanager -wext -concheck -wifi"

USE0="$USE0 tinywl evdev udev lto kmod wayland gdbm iwd dbus egl gles2 postproc wayland-compositor introspection X osmesa alsa "
USE0="$USE0 alsa"

export USE=$USE0

export COMMON_FLAGS="-Os -pipe"
export VIDEO_CARDS="intel virgl"
export INPUT_DEVICES="evdev"

