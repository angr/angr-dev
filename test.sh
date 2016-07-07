#!/bin/bash -e

if [ "$1" == '-h' ]
then
	echo "Usage:"
	echo ""
	echo "  $0 REPO_A REPO_B REPO_C         Test repos REPO_A, REPO_B, and REPO_C."
	echo "  $0                              Test all repositories."
	echo ""
	echo "Relevant environment variables:"
	echo ""
	echo "    NOSE_OPTIONS    Passed to nosetests (default: -v --nologcapture)"
	echo "    NOSE_PROCESSES  Number of tests run in parallel (default: # cores)"
	echo "    NOSE_PROCESS_RESTARTWORKER  Restart the nose worker every N tests (default: 1)"
	echo "    NOSE_PROCESS_TIMEOUT  Timeout, in seconds, for each test (default: 600)"
	exit
fi

WHERE=${@-.}
TEST_FILES=$(find $WHERE -iname 'test*.py' | egrep -v '^./(capstone|pypy|python|qemu|unicorn|shellphish-)')

export NOSE_PROCESSES=${NOSE_PROCESSES-$(nproc)}
export NOSE_PROCESS_TIMEOUT=${NOSE_PROCESS_TIMEOUT-600}
export NOSE_PROCESS_RESTARTWORKER=${NOSE_PROCESS_RESTARTWORKER-1}
NOSE_OPTIONS=${NOSE_OPTIONS--v --nologcapture}

nosetests $NOSE_OPTIONS $TEST_FILES
