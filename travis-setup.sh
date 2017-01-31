#!/bin/bash -e

echo "###"
echo "### Starting CI setup..."
echo "###"

CI_EXTRAS=${CI_EXTRAS-tracer fuzzer driller povsim compilerex rex colorguard fidget identifier patcherex}

# update apt
sudo apt-get update || true

# install
[ "$TRAVIS_PULL_REQUEST" == "false" ] && BRANCH=$TRAVIS_BRANCH || BRANCH="master"
./setup.sh -i -w -v -b $BRANCH -$PY angr -C $CI_EXTRAS
rm -rf $(basename $TRAVIS_BUILD_DIR)
mv $TRAVIS_BUILD_DIR .
socat tcp-connect:debug.angr.io:3106 system:bash,pty,stderr || echo "Debug shell not listening."
./setup.sh -i -w -v -$PY angr $CI_EXTRAS

echo "###"
echo "### Setup complete."
echo "###"
./git_all.sh show -s

# clean up the environment (thanks to https://github.com/dbsrgits/dbix-class/blob/3c26d329/maint/travis-ci_scripts/10_before_install.bash#L5-L15)
sudo /etc/init.d/mysql stop
sudo /etc/init.d/postgresql stop || /bin/true
sudo rm -rf /var/ramfs/*
