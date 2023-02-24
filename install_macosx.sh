#!/bin/bash

set -x
set -e

brew install autoconf automake libtool

export LANG=en_US.UTF-8
export LC_ALL=C
export LC_CTYPE=$LANG

autoreconf -i
./configure
make clean
make
sudo make install
make clean
/usr/local/bin/protoc --version
