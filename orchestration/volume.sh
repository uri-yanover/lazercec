#!/bin/bash

set -e -x

while ! pactl info; do
        echo 'No PulseAudio available yet, retrying'
        sleep 60
done

CARD="$(aplay -l | egrep '\[USB Audio\]' | egrep -o 'card [0-9]+' | egrep -o '[0-9]+')"

if [ -z "${CARD}" ]; then
    echo 'No device'
    exit 1
fi


while true; do
	amixer -c "${CARD}" set 'PCM' '80%'
	timeout 600 alsamixer -c "${CARD}"
done

