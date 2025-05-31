#!/bin/bash

# Set the name of the tmux session
SESSION_NAME="$1"
LOGS_DIR="$2"
shift 2

TMUX_COMMAND=(tmux -L"${SESSION_NAME}")


WINDOW_COMMANDS=("$@")

# Function to check if a "${TMUX_COMMAND[@]}" session exists
session_exists() {
  "${TMUX_COMMAND[@]}" has-session -t "$1" 2> /dev/null
  return $?
}

# Function to kill a "${TMUX_COMMAND[@]}" session
kill_session() {
  echo "Killing existing "${TMUX_COMMAND[@]}" session: $1"
  "${TMUX_COMMAND[@]}" kill-session -t "$1"
}

# Function to start the "${TMUX_COMMAND[@]}" session
start_session() {
  echo "Starting detached "${TMUX_COMMAND[@]}" session: $SESSION_NAME"
  "${TMUX_COMMAND[@]}" new-session -d -s "$SESSION_NAME"
  CURRENT_INDEX=1
  # Create new windows and run commands
  for WINDOW_COMMAND in "${WINDOW_COMMANDS[@]}"; do
	TAG="$(echo "${WINDOW_COMMAND}" | egrep -o '/[-/A-Za-z0-9_]+' | head -n 1 | sed -r 's/.*[/]//g')"
	"${TMUX_COMMAND[@]}" new-window -t "${SESSION_NAME}:${CURRENT_INDEX}" -n "${TAG}" "sleep 1 && ($WINDOW_COMMAND)" 
	LOG_FILE="${LOGS_DIR}/${TAG}.log" 
	savelog -9 "${LOG_FILE}"
	"${TMUX_COMMAND[@]}" pipe-pane -o -t "${SESSION_NAME}:${CURRENT_INDEX}" "cat - > '${LOG_FILE}'"	
	CURRENT_INDEX=$(expr "${CURRENT_INDEX}" '+' 1)
  done

  # Select the first window
  "${TMUX_COMMAND[@]}" kill-window -t "${SESSION_NAME}:0"
  "${TMUX_COMMAND[@]}" select-window -t "$SESSION_NAME:1"
}

# Trap SIGINT (Ctrl+C) and SIGTERM signals to stop the session
trap stop_session SIGINT SIGTERM

# Function to stop the "${TMUX_COMMAND[@]}" session
stop_session() {
  echo "Stopping "${TMUX_COMMAND[@]}" session: $SESSION_NAME..."
  if session_exists "$SESSION_NAME"; then
    kill_session "$SESSION_NAME"
    echo "Tmux session '$SESSION_NAME' stopped."
  else
    echo "Tmux session '$SESSION_NAME' not found."
  fi
  exit 0
}

# Main script logic
echo "Starting script..."

# Clean up any existing session
if session_exists "$SESSION_NAME"; then
  echo "Found existing session '$SESSION_NAME'. Cleaning up..."
  kill_session "$SESSION_NAME"
fi

# Start the detached "${TMUX_COMMAND[@]}" session
start_session

echo "Tmux session '$SESSION_NAME' started in detached mode."
echo "Use the following command to see what's going on."
echo "${TMUX_COMMAND[@]} attach -t ${SESSION_NAME}"
echo "Entering sleep loop. Press Ctrl+C to stop the session."

# Enter an infinite sleep loop (until interrupted)
while true; do
  sleep 60
done

echo "Exiting script." # This line should ideally not be reached due to the trap
