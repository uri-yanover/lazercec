#!/bin/bash

set -x

OWN_DIR="$(cd "$(dirname "$0")" && pwd)"

while ! pactl info; do
	echo 'No PulseAudio available yet, retrying'
	sleep 5
done

# EXECUTABLE="${OWN_DIR}/spotifyd/spotifyd" 
#
# Currently working: 0.47.1 from https://github.com/dtcooper/raspotify/releases
EXECUTABLE="/usr/bin/librespot"
while true; do
	pkill -9 -f "^${EXECUTABLE}"
	# spotifyd semantics
	#bash -x "${OWN_DIR}"/run_until.sh 'tomorrow 3am' "${EXECUTABLE}" --backend pulseaudio --device 'USB AUDIO' --device-name 'Sunet Bun' --no-daemon
	# librespot semantics
	bash -x "${OWN_DIR}"/run_until.sh 'tomorrow 3am' "${EXECUTABLE}" --backend pulseaudio --device 'USB AUDIO' --name 'Sunet Bun'
done
