#!/bin/bash -e

SCRIPT_DIR=$(dirname $0)
cd $SCRIPT_DIR

echo "###"
echo "### Starting docker container..."
echo "###"
free
env
socat tcp-connect:debug.angr.io:3104 system:bash,pty,stderr || echo "Debug shell not listening."

# set stuff up for fuzzing tests
echo core | sudo tee /proc/sys/kernel/core_pattern > /dev/null
#echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null
echo 1 | sudo tee /proc/sys/kernel/sched_child_runs_first > /dev/null

docker run -it \
	-e NOSE_OPTIONS=$NOSE_OPTIONS \
	-e NOSE_PROCESS_TIMEOUT=$NOSE_PROCESS_TIMEOUT \
	-e NOSE_PROCESSES=$NOSE_PROCESSES \
	-e ANGR_REPO=$ANGR_REPO \
	angr/tester angr-dev/ci-test.sh
exit 0
