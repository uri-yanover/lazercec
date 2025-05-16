#!/bin/bash

OWN_DIR="$(cd "$(dirname "$0")" && pwd)"

"${OWN_DIR}"/engine.sh "pipewire" "/var/log/pipewire" '/usr/bin/pipewire' 'sleep 3 && /usr/bin/wireplumber' 'sleep 5 && /usr/bin/pipewire-pulse' "${OWN_DIR}/run_spotifyd.sh" "${OWN_DIR}/scream_wrapper.sh || bash"

