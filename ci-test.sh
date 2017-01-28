#!/bin/bash -e

SCRIPT_DIR=$(dirname $0)
cd $SCRIPT_DIR

echo "###"
echo "### Starting CI tests..."
echo "###"
env
./git_all.sh status

# nosetests
if [ -z "$NO_COVERAGE" -a "$CI_CHANGED_REPO" == "$ANGR_REPO" ]
then
	NOSE_OPTIONS="--with-coverage --cover-package=$ANGR_REPO --cover-erase $NOSE_OPTIONS"
fi
export NOSE_PROCESS_TIMEOUT=${NOSE_PROCESS_TIMEOUT-570}
export NOSE_PROCESSES=${NOSE_PROCESSES-2}
export NOSE_OPTIONS="-v --nologcapture --with-timer $NOSE_OPTIONS"
source ~/.virtualenvs/$CI_VENV/bin/activate
bash -ex ./test.sh $ANGR_REPO

# run lint if necessary
cd $ANGR_REPO
if [ "$CI_CHANGED_REPO" == "$ANGR_REPO" ]; then
	echo
	echo -e "\e[31m### Running linting for repository $ANGR_REPO\e[0m"

	# in weird situations, travis will not properly fetch remote refs. We want to get master.
	git fetch origin +refs/heads/master:refs/remotes/origin/master
	../lint.py
fi
exit 0
