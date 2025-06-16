#!/bin/bash

OWN_DIR="$(cd "$(dirname "$0")" && pwd)"

EXECUTABLE="${OWN_DIR}/scream/Receivers/unix/build/scream"

KILL_SCREAM_SHELL_COMMAND='echo "Killing scream" && pkill -KILL -f '"'^${EXECUTABLE}'"
# trap "bash -c '${KILL_SCREAM_SHELL_COMMAND}'" TERM
# EXIT HUP INT QUIT ABRT KILL TERM

#function run_scream() {
#	/bin/bash -cx 'while (date && ('"${KILL_SCREAM_SHELL_COMMAND}"' || true) && ('"${EXECUTABLE}"' -v -u -d "dmix:CARD=AUDIO,DEV=0" -p 4011 || sleep 1)); do true; done'
#/bin/bash -cx 'while (date && ('"${KILL_SCREAM_SHELL_COMMAND}"' || true) && ('"${EXECUTABLE}"' -v -u -o pulse -d "USB Audio" -p 4011 || sleep 1)); do true; done'
#}

function kill_scream() {
	bash -cx "${KILL_SCREAM_SHELL_COMMAND}"
}

function get_udp_port_queue() {
	local PORT="$1"

	ss -u -a | egrep ":${PORT}\s" | cut -d ' ' -f 2
	# UNCONN 0      0             0.0.0.0:4011        0.0.0.0:*
	# UNCONN 18368  0             0.0.0.0:4011        0.0.0.0:*
}

function get_state() {
	local OUTCOME='NO_SCREAM'
	#set -x
	for _ITERATION in $(seq 1 20); do
		# echo "ITERATION ${_ITERATION}" 1>&2
		SAMPLE="$(get_udp_port_queue 4011)"
		if [[ -z "${SAMPLE}" ]]; then
			sleep 1
		elif [[ "${SAMPLE}" != 0 ]]; then
			OUTCOME="YES_SOUND"
			break
		else  # zero
			OUTCOME='NO_SOUND'
			sleep 1
		fi
	done

	echo "${OUTCOME}"
}

function watchdog() {
	PREV_STATE="NO_SCREAM"
	while sleep 1; do
		NEW_STATE="$(get_state)"

		if [ "${PREV_STATE}" == "${NEW_STATE}" ]; then
			continue
		fi
		
		TRANSITION="${PREV_STATE}_to_${NEW_STATE}"
	
		echo "$(date)" "${TRANSITION}"
		if [[ "${TRANSITION}" = 'YES_SOUND_to_NO_SOUND' ]]; then
			echo "Restarting" 1>&2
			kill_scream
		fi
		PREV_STATE="${NEW_STATE}"
	done
}

# run_scream & disown

while ! pactl info; do
	echo 'No PulseAudio available yet, retrying'
	sleep 5
done

watchdog & disown

while /bin/true; do
	kill_scream
	date
	"${EXECUTABLE}" -v -u -o pulse -d "USB Audio" -p 4011 || sleep 5
done



