#!/bin/bash -e

echo "###"
echo "### Starting CI setup..."
echo "###"

CI_EXTRAS=${CI_EXTRAS-tracer fuzzer driller povsim compilerex rex colorguard fidget identifier patcherex angr-bf}

# update apt
echo "Updating apt..."
sudo apt-get update >/dev/null || true

# install
[ "$TRAVIS_PULL_REQUEST" == "false" ] && BRANCH=$TRAVIS_BRANCH || BRANCH="master"
./setup.sh -i -w -b $BRANCH -$PY angr -c -C $CI_EXTRAS

echo "###"
echo "### Clone complete."
echo "###"

if [ $(basename $TRAVIS_BUILD_DIR) != "angr-dev" ]
then
	rm -rf $(basename $TRAVIS_BUILD_DIR)
	mv $TRAVIS_BUILD_DIR .
fi
./tests/shell.sh debug.angr.io 3106
./setup.sh -i -w -$PY angr $CI_EXTRAS

echo "###"
echo "### Setup complete."
echo "###"
./git_all.sh show -s

# clean up the environment (thanks to https://github.com/dbsrgits/dbix-class/blob/3c26d329/maint/travis-ci_scripts/10_before_install.bash#L5-L15)
sudo /etc/init.d/mysql stop
sudo /etc/init.d/postgresql stop || /bin/true
sudo rm -rf /var/ramfs/*
