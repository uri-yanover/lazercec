#!/bin/bash

set -e -x

CARD="$(aplay -l | egrep '\[USB Audio\]' | egrep -o 'card [0-9]+' | egrep -o '[0-9]+')"

if [ -z "${CARD}" ]; then
    echo 'No device'
    exit 1
fi

amixer -c "${CARD}" set 'PCM' '80%'
alsamixer -c "${CARD}"

