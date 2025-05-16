#!/bin/bash

OWN_DIR="$(cd "$(dirname "$0")" && pwd)"

EXECUTABLE="${OWN_DIR}/scream/Receivers/unix/build/scream"

KILL_SCREAM_SHELL_COMMAND='echo "Killing scream" && pkill -KILL -f '"'^${EXECUTABLE}'"
trap "bash -c '${KILL_SCREAM_SHELL_COMMAND}'" TERM
# EXIT HUP INT QUIT ABRT KILL TERM

function run_scream() {
#	/bin/bash -cx 'while (date && ('"${KILL_SCREAM_SHELL_COMMAND}"' || true) && ('"${EXECUTABLE}"' -v -u -d "dmix:CARD=AUDIO,DEV=0" -p 4011 || sleep 1)); do true; done'
/bin/bash -cx 'while (date && ('"${KILL_SCREAM_SHELL_COMMAND}"' || true) && ('"${EXECUTABLE}"' -v -u -o pulse -d "USB Audio" -p 4011 || sleep 1)); do true; done'
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
