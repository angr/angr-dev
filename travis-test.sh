#!/bin/bash -e

SCRIPT_DIR=$(dirname $0)
cd $SCRIPT_DIR

echo "###"
echo "### Starting CI tests..."
echo "###"
free
env
socat tcp-connect:debug.angr.io:3104 system:bash,pty,stderr || echo "Debug shell not listening."

# set stuff up for fuzzing tests
echo core | sudo tee /proc/sys/kernel/core_pattern > /dev/null
#echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
echo 1 | sudo tee /proc/sys/kernel/sched_child_runs_first > /dev/null

# nosetests
if [ -z "$NO_COVERAGE" -a "$(basename $TRAVIS_REPO_SLUG)" == "$ANGR_REPO" ]
then
	NOSE_OPTIONS="--with-coverage --cover-package=$ANGR_REPO --cover-erase $NOSE_OPTIONS"
fi
export NOSE_PROCESS_TIMEOUT=${NOSE_PROCESS_TIMEOUT-570}
export NOSE_PROCESSES=${NOSE_PROCESSES-2}
export NOSE_OPTIONS="-v --nologcapture --with-timer $NOSE_OPTIONS"
source ~/.virtualenvs/angr/bin/activate
bash -ex ./test.sh $ANGR_REPO

# run lint if necessary
cd $ANGR_REPO
if [ "$(basename $TRAVIS_REPO_SLUG)" == "$ANGR_REPO" ]; then
	echo
	echo -e "\e[31m### Running linting for repository $ANGR_REPO\e[0m"
	../lint.py
fi
exit 0
