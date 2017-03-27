#!/bin/bash -e

echo "###"
echo "### Cloning angr-dev..."
echo "###"

./tests/shell.sh debug.angr.io 3105
cd
git clone -q https://github.com/angr/angr-dev && cd angr-dev
git checkout $TRAVIS_BRANCH || echo "No branch $TRAVIS_BRANCH in angr-dev. Using default test scripts."
./tests/travis-setup.sh
