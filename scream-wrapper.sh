#!/bin/bash

KILL_SCREAM_SHELL_COMMAND='echo "Killing scream"; pgrep scream | xargs -r kill'
trap "bash -c '${KILL_SCREAM_SHELL_COMMAND}'" TERM
# EXIT HUP INT QUIT ABRT KILL TERM

function run_scream() {
	/bin/bash -cx 'EXECUTABLE=/home/pi/scream/Receivers/unix/build/scream; while date; ('"${KILL_SCREAM_SHELL_COMMAND}"'); $EXECUTABLE -v -u -d "sysdefault:CARD=AUDIO" -p 4011 | egrep "Device or resource busy" || sleep 1; do true; done'
}

function get_udp_port_queue() {
	local PORT="$1"

	ss -u -a | egrep ":${PORT}\s" | cut -d ' ' -f 2
	# UNCONN 0      0             0.0.0.0:4011        0.0.0.0:*
	# UNCONN 18368  0             0.0.0.0:4011        0.0.0.0:*
}

function get_state() {
	TESTS="x-$(get_udp_port_queue 4011)-$(get_udp_port_queue 4011)-$(get_udp_port_queue 4011)" 
	
	case "${TESTS}" in
		x-0-0-0)
			echo "NO_SOUND"
			;;
		x---)
			echo "NO_SCREAM"
			;;

		*)
			echo "YES_SOUND"
			;;
	esac
}

PREV_STATE="INITIAL"

run_scream & SCREAM_PID=$!


while sleep 1; do
	NEW_STATE="$(get_state)"

	TRANSITION="${PREV_STATE}_to_${NEW_STATE}"
	
	if [ "${PREV_STATE}" != "${NEW_STATE}" ]; then
		date
		echo "Transition ${TRANSITION}" 
	fi

	if [[ "${TRANSITION}" = 'YES_SOUND_to_NO_SOUND' ]]; then
		echo "Restarting"
		bash -c "${KILL_SCREAM_SHELL_COMMAND}"
	fi
	PREV_STATE="${NEW_STATE}"
done
