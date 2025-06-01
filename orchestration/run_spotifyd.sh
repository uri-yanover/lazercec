#!/bin/bash

set -x

OWN_DIR="$(cd "$(dirname "$0")" && pwd)"

while ! pactl info; do
	echo 'No PulseAudio available yet, retrying'
	sleep 5
done

while true; do
	bash -x "${OWN_DIR}"/run_until.sh 'tomorrow 3am' "${OWN_DIR}/spotifyd/spotifyd" --backend pulseaudio --device 'USB AUDIO' --device-name 'Sunet Bun' --no-daemon
done
