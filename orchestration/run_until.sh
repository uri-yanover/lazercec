#!/bin/bash

RUN_UNTIL="$1"
shift

# Get the current time in seconds since the epoch
CURRENT_TS=$(date +%s)

# Get the timestamp for the goal time in seconds since the epoch
END_TS=$(date -d "${RUN_UNTIL}" +%s)

# Calculate the timeout duration in seconds, plus a deliberate margin
timeout_seconds=$((5 + END_TS - CURRENT_TS))

# Run the proper arguments
timeout "${timeout_seconds}" "${@}"
