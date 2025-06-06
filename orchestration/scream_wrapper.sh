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

shopt -s extglob
# https://stackoverflow.com/questions/4554718/how-to-use-patterns-in-a-case-statement

function get_state() {
	TESTS="x-$(get_udp_port_queue 4011)-$(sleep 1 && get_udp_port_queue 4011)-$(sleep 1 && get_udp_port_queue 4011)-$(sleep 1 && get_udp_port_queue 4011)" 
	# echo "${TESTS}" 1>&2

	case "${TESTS}" in
		x----)
			echo "NO_SCREAM"
			;;

		x-?(0)-?(0)-0-0)
			echo "NO_SOUND"
			;;
		*)
			echo "YES_SOUND"
			;;
	esac
}

PREV_STATE="NO_SCREAM"

while ! pactl info; do
	echo 'No PulseAudio available yet, retrying'
	sleep 5
done

run_scream & disown

while sleep 1; do
	NEW_STATE="$(get_state)"

	if [ "${PREV_STATE}" == "${NEW_STATE}" ]; then
		continue
	fi
		
	TRANSITION="${PREV_STATE}_to_${NEW_STATE}"
	
	echo "$(date)" "${TRANSITION}"
	if [[ "${TRANSITION}" = 'YES_SOUND_to_NO_SOUND' ]]; then
		echo "Restarting" 1>&2
		bash -c "${KILL_SCREAM_SHELL_COMMAND}"
	fi
	PREV_STATE="${NEW_STATE}"
done


