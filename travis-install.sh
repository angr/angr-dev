#!/bin/bash -e

echo "###"
echo "### Cloning angr-dev..."
echo "###"

cd
git clone https://github.com/angr/angr-dev && cd angr-dev
git checkout $TRAVIS_BRANCH
./travis-setup.sh
