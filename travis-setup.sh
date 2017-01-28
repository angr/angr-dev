#!/bin/bash -e

echo "###"
echo "### Starting CI setup..."
echo "###"

CI_EXTRAS=${CI_EXTRAS-tracer fuzzer driller povsim compilerex rex colorguard fidget identifier patcherex}

# install
[ "$TRAVIS_PULL_REQUEST" == "false" ] && BRANCH=$TRAVIS_BRANCH || BRANCH="master"
mv $TRAVIS_BUILD_DIR .
VENV=angr-cpython
[ "$PY" -eq "e" ] && VENV=angr-pypy
docker build \
	--build-arg CI_BRANCH=$BRANCH \
	--build-arg CI_PR=$TRAVIS_PULL_REQUEST \
	--build-arg CI_CHANGED_REPO=$(basename $TRAVIS_BUILD_DIR) \
	--build-arg CI_NO_COVERAGE=$NO_COVERAGE \
	--build-arg CI_VENV=$VENV \
	-t angr/tester -f $PWD/Dockerfile-test .

# clean up the environment (thanks to https://github.com/dbsrgits/dbix-class/blob/3c26d329/maint/travis-ci_scripts/10_before_install.bash#L5-L15)
sudo /etc/init.d/mysql stop
sudo /etc/init.d/postgresql stop || /bin/true
sudo rm -rf /var/ramfs/*
