#!/bin/bash

# See: https://github.com/duncanthrax/scream/tree/master/Receivers/unix
sudo apt-get -y install libasound2-dev cmake

OWN_DIR="$(cd "$(dirname "$0")" && pwd)"
rm -rf "${OWN_DIR}/scream"
(cd "${OWN_DIR}" && \
	git clone https://github.com/duncanthrax/scream.git &&\
	mkdir -p "${OWN_DIR}"/scream/Receivers/unix/build && \
	cd "${OWN_DIR}"/scream/Receivers/unix/build && \
	cmake ..
	make
)

