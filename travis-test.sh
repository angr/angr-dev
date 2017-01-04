#!/bin/bash -e

echo "###"
echo "### Starting CI tests..."
echo "###"
free

# set stuff up for fuzzing tests - we'll move this somewhere else later
echo core | sudo tee /proc/sys/kernel/core_pattern > /dev/null
#echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
echo 1 | sudo tee /proc/sys/kernel/sched_child_runs_first > /dev/null

# clean up the environment (thanks to https://github.com/dbsrgits/dbix-class/blob/3c26d329/maint/travis-ci_scripts/10_before_install.bash#L5-L15)

sudo /etc/init.d/mysql stop
sudo /etc/init.d/postgresql stop || /bin/true
rm -rf /var/ramfs/*

if [ -z "$NO_COVERAGE" -a "$(basename $TRAVIS_REPO_SLUG)" == "$ANGR_REPO" ]
then
	NOSE_OPTIONS="--with-coverage --cover-package=$ANGR_REPO --cover-erase $NOSE_OPTIONS"
fi
export NOSE_PROCESS_TIMEOUT=${NOSE_PROCESS_TIMEOUT-570}
export NOSE_PROCESSES=${NOSE_PROCESSES-2}
export NOSE_OPTIONS="-v --nologcapture --with-timer $NOSE_OPTIONS"
bash -ex ./test.sh $ANGR_REPO

# run lint if necessary
cd $ANGR_REPO
if [ "$(basename $TRAVIS_REPO_SLUG)" == "$ANGR_REPO" ]; then
	echo
	echo -e "\e[31m### Running linting for repository $ANGR_REPO\e[0m"
	../lint.py
fi
exit 0
