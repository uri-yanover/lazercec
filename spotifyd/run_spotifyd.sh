#!/bin/bash

set -x

OWN_DIR="$(cd "$(dirname "$0")" && pwd)"

"${OWN_DIR}/spotifyd" --backend pulseaudio --device 'USB AUDIO' --device-name 'Sunet Bun' --no-daemon
