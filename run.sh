#!/bin/bash

set -e -x

OWN_PATH=$(dirname "$0")

source "${OWN_PATH}/ve/bin/activate"

date 2>&1
date 1>&2
# TODO: move into the Python
echo 'is' | cec-client -s
python3 "${OWN_PATH}/main.py" -v DEBUG --configuration "${OWN_PATH}/config.json"
exit $?
