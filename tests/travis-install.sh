#!/bin/bash -e

echo "###"
echo "### Cloning angr-dev..."
echo "###"

cd
git clone -q https://github.com/angr/angr-dev && cd angr-dev
angr-dev/tests/shell.sh debug.angr.io 3105
git checkout $TRAVIS_BRANCH || echo "No branch $TRAVIS_BRANCH in angr-dev. Using default test scripts."
./tests/travis-setup.sh
