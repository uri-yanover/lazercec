#!/usr/bin/env bash
# Removed -e so minor grep failures don't kill the script. 
# Kept -x for debugging so you can see exactly what runs.
set -x

while ! pactl info >/dev/null 2>&1; do
        echo 'No PulseAudio available yet, retrying'
        sleep 60
done

# Wrap this in a retry loop or handle the empty check gracefully without set -e
CARD=$(aplay -l | egrep '\[USB Audio\]' | egrep -o 'card [0-9]+' | egrep -o '[0-9]+')

if [ -z "${CARD}" ]; then
    echo 'No device found'
    exit 1
fi

BUDGET_MINS=0

while true; do
        # Safely capture amixer output. Using 'set +e' inside a subshell or 
        # simply removing global 'set -e' makes this safe.
        AMIX_OUT=$(amixer -c "${CARD}" sget PCM 2>/dev/null | grep -E 'Front|Master' | egrep -o '[0-9]+%' | paste -s -d ' ')

        if [ "${AMIX_OUT}" = "80% 80%" ] || [ "${AMIX_OUT}" = "80%" ] || [ "${BUDGET_MINS}" -gt 0 ] ; then
                sleep 60
                # Use Bash arithmetic $((...)) instead of 'expr' to avoid the exit-status-0 trap
                BUDGET_MINS=$(( BUDGET_MINS - 1 ))
        else
                echo "Resetting sound"
                date
                BUDGET_MINS=240
                amixer -c "${CARD}" set 'PCM' '80%'
        fi
done
