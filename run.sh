#!/bin/bash

set -e -x

OWN_PATH=$(dirname "$0")

source "${OWN_PATH}/ve/bin/activate"

date 2>&1
date 1>&2
# TODO: move into the Python
echo 'is' | cec-client -s

KILL_COMMAND="pkill -f '${OWN_PATH}'/main.py"

bash -c "${KILL_COMMAND}" || /bin/true

trap "{ ${KILL_COMMAND} }" SIGINT SIGTERM SIGKILL

python3 "${OWN_PATH}/main.py" -v INFO --configuration "${OWN_PATH}/config.json"

exit $?
