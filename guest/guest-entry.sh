#!/bin/bash

source /etc/profile
env-update

source /firebox/flags.sh

if test "$#" != "0"
then
    $@
else
    bash
fi
