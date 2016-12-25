#!/bin/bash -e

echo "###"
echo "### Starting CI tests..."
echo "###"
echo -n "MEM: "
free

# set stuff up for fuzzing tests - we'll move this somewhere else later
echo core | sudo tee /proc/sys/kernel/core_pattern > /dev/null
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
echo 1 | sudo tee /proc/sys/kernel/sched_child_runs_first > /dev/null

./git_all.sh checkout master
./git_all.sh checkout $TRAVIS_BRANCH

if [ -z "$NO_COVERAGE" -a "$(basename $TRAVIS_REPO_SLUG)" == "$ANGR_REPO" ]
then
	NOSE_OPTIONS="--with-coverage --cover-package=$ANGR_REPO --cover-erase $NOSE_OPTIONS"
fi
export NOSE_PROCESS_TIMEOUT=${NOSE_PROCESS_TIMEOUT-570}
export NOSE_PROCESSES=${NOSE_PROCESSES-2}
export NOSE_OPTIONS="-v --nologcapture --with-timer $NOSE_OPTIONS"
bash -ex ./test.sh $ANGR_REPO

cd $ANGR_REPO
if [ "$(basename $TRAVIS_REPO_SLUG)" == "$ANGR_REPO" ]; then
	echo
	echo -e "\e[31m### Running linting for repository $ANGR_REPO\e[0m"
	../lint.py
fi
exit 0
