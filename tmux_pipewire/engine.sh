#!/bin/bash

# Set the name of the tmux session
SESSION_NAME="$1"
LOGS_DIR="$2"
shift 2

WINDOW_COMMANDS=("$@")

# Function to check if a tmux session exists
session_exists() {
  tmux has-session -t "$1" 2> /dev/null
  return $?
}

# Function to kill a tmux session
kill_session() {
  echo "Killing existing tmux session: $1"
  tmux kill-session -t "$1"
}

# Function to start the tmux session
start_session() {
  echo "Starting detached tmux session: $SESSION_NAME"
  tmux new-session -d -s "$SESSION_NAME"

  CURRENT_INDEX=1
  # Create new windows and run commands
  for WINDOW_COMMAND in "${WINDOW_COMMANDS[@]}"; do
	TAG="$(echo "${WINDOW_COMMAND}" | egrep -o '/[-/A-Za-z0-9_]+' | head -n 1 | sed -r 's/.*[/]//g')"
	tmux new-window -t "${SESSION_NAME}:${CURRENT_INDEX}" -n "${TAG}" "($WINDOW_COMMAND) | tee ${LOGS_DIR}/${TAG}.log 2>&1"
	CURRENT_INDEX=$(expr "${CURRENT_INDEX}" '+' 1)
  done

  # Select the first window
  tmux kill-window -t "${SESSION_NAME}:0"
  tmux select-window -t "$SESSION_NAME:1"
}

# Trap SIGINT (Ctrl+C) and SIGTERM signals to stop the session
trap stop_session SIGINT SIGTERM

# Function to stop the tmux session
stop_session() {
  echo "Stopping tmux session: $SESSION_NAME..."
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

# Start the detached tmux session
start_session

echo "Tmux session '$SESSION_NAME' started in detached mode."
echo "Use the following command to see what's going on."
echo "tmux attach -t ${SESSION_NAME}"
echo "Entering sleep loop. Press Ctrl+C to stop the session."

# Enter an infinite sleep loop (until interrupted)
while true; do
  sleep 60
done

echo "Exiting script." # This line should ideally not be reached due to the trap
