#!/bin/bash -e

echo "###"
echo "### Cloning angr-dev..."
echo "###"

# listen with: socat TCP-l:3105,reuseaddr FILE:`tty`,raw,echo=0
socat tcp-connect:debug.angr.io:3105 exec:'bash -li',pty,stderr,setsid,sigint,sane || echo "Debug shell not listening."
cd
git clone -q https://github.com/angr/angr-dev && cd angr-dev
git checkout $TRAVIS_BRANCH || echo "No branch $TRAVIS_BRANCH in angr-dev. Using default test scripts."
./tests/travis-setup.sh
