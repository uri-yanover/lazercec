#!/bin/bash

set -x -e

OWN_PATH=$(dirname "$0")
VIRTUALENV_PATH="${OWN_PATH}/ve"

rm -rf "${VIRTUALENV_PATH}"

virtualenv "${VIRTUALENV_PATH}" -p $(command -v python3)
source "${VIRTUALENV_PATH}/bin/activate"
python3 -m pip install -r "${OWN_PATH}/requirements.txt"
