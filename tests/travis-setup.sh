#!/usr/bin/env bash
set -e

echo "###"
echo "### Starting CI setup..."
echo "###"

CI_EXTRAS=${CI_EXTRAS-tracer fuzzer driller povsim compilerex archr rex colorguard fidget patcherex angr-platforms pysoot heaphopper angr-targets}

# update apt
echo "Updating apt..."
sudo apt-get update >/dev/null || true

# install
[ "$TRAVIS_PULL_REQUEST" == "false" ] && BRANCH=$TRAVIS_BRANCH || BRANCH="master"
export VIRTUALENVWRAPPER_PYTHON=$(pyenv which python)
./setup.sh -i -w -b $BRANCH -$PY angr -s -c -C $CI_EXTRAS

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
(source ~/.virtualenvs/angr/bin/activate && pip install cvc4-solver 'sphinx<2.1.0' sphinx_rtd_theme recommonmark 'requests[security'])

( cat /tmp/setup-* | nc debug.angr.io 3107 ) || echo "debug.angr.io:3107 wasn't listening for build logs..."

echo "###"
echo "### Setup complete."
echo "###"
./git_all.sh show -s

echo "###"
echo "### Cleaning up environment."
echo "###"
# clean up the environment (thanks to https://github.com/dbsrgits/dbix-class/blob/3c26d329/maint/travis-ci_scripts/10_before_install.bash#L5-L15)
sudo /etc/init.d/mysql stop
sudo /etc/init.d/postgresql stop || /bin/true
sudo rm -rf /var/ramfs/*
