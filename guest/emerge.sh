#!/bin/bash
set -xe -o pipefail

source /firebox/guest/flags.sh

A=--ask
N=--newuse
D=--deep

#emerge --update --deep --newuse $A @world

export USE="$USE0"
emerge $A --update --deep --newuse vlgothic gentoo-sources libpciaccess pciutils vlgothic iwd seatd mesa-progs
emerge $A --update --newuse --deep mesa
emerge $A --update vim busybox
emerge $A --oneshot --update sys-fs/eudev

export ACCEPT_KEYWORDS=~amd64
#emerge $A $N $D --update gtk+
#emerge $A $N $D --update hyprland
#emerge $A $N $D --update foot
#emerge $A $N $D --update waybar

export USE="$USE0 pgo"
emerge $A $N --update firefox

