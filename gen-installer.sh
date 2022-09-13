set -xe -o pipefail

USE0="-objc -objc++ -openmp -installkernel symlink -static -gdc -gcj -fortran -go -nscd -ssp -selinux -systemd"
USE0="$USE0 -systemtap -compile-locales -cet -caps -audit -cgroup-hybrid -policykit -python -pcre -nls -elogind"
USE0="$USE0 -doc -man -gtk-doc -cups -sysprof -colord -test -acl -zstd -mime ncurses -gnome -graphite -nls -iconv"
USE0="$USE0 -gmp-autoupdate -xattr -python -cairo -introspection -vala -egl -gles2 -icu -clang -wayland -llvm -crypt"
USE0="$USE0 -snapshot -examples -system-jpeg -system-harfbuzz -system-av1 -system-libvpx -system-webp -system-libevent -pulseaudio"
USE0="$USE0 -openh264 -encode -gnutls -binutils-plugin -libffi -asan -cfi -dfsan -gwp-asan -hwasan -libfuzzer -lsan -msan -safestack -scudo -tsan -ubsan"
USE0="$USE0 -static-analyzer -memprof -compiler-rt -profile -xray -sanitize -e2fsprog"
USE0="$USE0 X minimal -gdbm evdev udev xvfb lto kmod"

export USE=$USE0

export COMMON_FLAGS="-Os -pipe"
export VIDEO_CARDS=""
export INPUT_DEVICES="evdev"

#A=--ask

#emerge --update --deep --newuse $A @world
emerge --update --deep --newuse $A xorg-server gtk+ xterm vlgothic eudev gentoo-sources libpciaccess pciutils

export ACCEPT_KEYWORDS=~amd64
export USE="$USE0 pgo"
emerge $A firefox

export USE="$USE0 -X"
emerge vim busybox


