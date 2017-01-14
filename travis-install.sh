#!/bin/bash -e

echo "###"
echo "### Starting CI setup..."
echo "###"

sudo apt-get update || true
cd
git clone https://github.com/angr/angr-dev && cd angr-dev
git checkout $TRAVIS_BRANCH

# install
mv $TRAVIS_BUILD_DIR .
[ "$TRAVIS_PULL_REQUEST" == "false" ] && BRANCH=$TRAVIS_BRANCH || BRANCH="master"
./setup.sh -i -w -v -b $BRANCH -$PY angr tracer fuzzer driller povsim compilerex rex colorguard fidget identifier patcherex

echo "###"
echo "### Setup complete."
echo "###"
./git_all.sh show -s

# clean up the environment (thanks to https://github.com/dbsrgits/dbix-class/blob/3c26d329/maint/travis-ci_scripts/10_before_install.bash#L5-L15)
sudo /etc/init.d/mysql stop
sudo /etc/init.d/postgresql stop || /bin/true
sudo rm -rf /var/ramfs/*
