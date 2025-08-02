#!/bin/bash

OWN_DIR="$(cd "$(dirname "$0")" && pwd)"

export $(dbus-launch)
# export PIPEWIRE_RUNTIME_DIR=/tmp
export XDG_RUNTIME_DIR=/run/user/"$(id -u)"
# /pulse/native

FIRST_TIME=true

while true; do
	if [ "${FIRST_TIME}" = 'true' ] || (! pgrep -f 'alsamixer -c'); then
		"${OWN_DIR}"/engine.sh "session-media" "/var/log/session-media" \
		"${OWN_DIR}/run_spotifyd.sh" "${OWN_DIR}/scream_wrapper.sh" \
		"${OWN_DIR}/volume.sh" "${OWN_DIR}/start_session.sh" &
	fi
	FIRST_TIME=false
	sleep 60
done
