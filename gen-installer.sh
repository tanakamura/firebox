USE="-objc -objc++ -openmp -installkernel symlink -static -gdc -gcj -fortran -go -nscd -ssp -selinux -systemd"
USE="$USE -systemtap -compile-locales -cet -caps -audit -cgroup-hybrid -policykit -python -pcre -nls -elogind"
USE="$USE -doc -man -gtk-doc -cups -sysprof -colord -test -acl -zstd -mime ncurses -gnome -graphite -nls -iconv"
USE="$USE -gmp-autoupdate -xattr -python -cairo -introspection -vala -egl -gles2 -icu -clang -wayland -llvm -crypt"
USE="$USE -snapshot -examples -system-jpeg -system-harfbuzz -system-av1 -system-libvpx -system-webp -system-libevent -pulseaudio"
USE="$USE -openh264 -encode -gnutls -binutils-plugin -libffi -asan -cfi -dfsan -gwp-asan -hwasan -libfuzzer -lsan -msan -safestack -scudo -tsan -ubsan"
USE="$USE -static-analyzer -memprof -compiler-rt -profile -xray -sanitize"
USE="$USE X minimal -gdbm evdev"

export USE

COMMON_FLAGS="-Os -pipe"

export COMMON_FLAGS
export VIDEO_CARDS=""
export INPUT_DEVICES="evdev synaptics libinput"


emerge --update --deep --ask --newuse @world
#emerge --update --deep --ask --newuse dev-lang/perl

emerge --update --deep --ask --newuse xorg-server gtk+ busybox

ACCEPT_KEYWORDS=~amd64 emerge --ask --update --deep --newuse firefox

USE="$USE -X"
emerge vim

