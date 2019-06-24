#!/usr/bin/env bash
set -e

echo "###"
echo "### Cloning angr-dev..."
echo "###"

sudo apt-get update && sudo apt-get install -y socat gdbserver gdb

cd
git clone -q https://github.com/angr/angr-dev && cd angr-dev
git checkout $TRAVIS_BRANCH || echo "No branch $TRAVIS_BRANCH in angr-dev. Using default test scripts."
./tests/shell.sh debug.angr.io 3105
./tests/travis-setup.sh
