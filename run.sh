#!/bin/bash

set -e -x

OWN_PATH=$(dirname "$0")

source "${OWN_PATH}/ve/bin/activate"

python3 "${OWN_PATH}/main.py" --configuration "${OWN_PATH}/config.json"
