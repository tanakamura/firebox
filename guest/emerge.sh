#!/bin/bash
set -xe -o pipefail

source /firebox/guest/flags.sh

A=--ask

#emerge --update --deep --newuse $A @world

export USE="$USE0"
emerge $A --update --deep --newuse vlgothic gentoo-sources libpciaccess pciutils vlgothic iwd seatd mesa-progs
emerge $A --update --newuse mesa
emerge $A --update vim busybox
emerge $A --oneshot --update sys-fs/eudev

export ACCEPT_KEYWORDS=~amd64
emerge $A --update gtk+
emerge $A --update hyprland

export USE="$USE0 -X"
emerge $A --update firefox
emerge $A --update foot
emerge $A --update waybar
