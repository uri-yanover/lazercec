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


BUDGET_MINS=0

if [ "$(amixer -c "${CARD}" sget PCM | grep Front | egrep -o '[0-9]+%' | paste -s -d ' ')" = "80% 80%" ] || [ "${BUDGET_MINS}" -gt 0 ] ; then
	sleep 60
	BUDGET_MINS="$(expr "${BUDGET_MINS}" - 1)"
else
	echo "Resetting sound"
	date
	BUDGET_MINS=180
	amixer -c "${CARD}" set 'PCM' '80%'
fi

# watch -n 30 -d=permanent amixer -c ${CARD} sget  PCM
# alsamixer -c "${CARD}"
