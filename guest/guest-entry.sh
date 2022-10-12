#!/bin/bash

source /etc/profile
env-update

source /firebox/guest/flags.sh

if test "$#" != "0"
then
    $@
else
    bash
fi
