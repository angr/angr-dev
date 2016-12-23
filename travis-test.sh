#!/bin/bash -e

./git_all.sh checkout master
./git_all.sh checkout $TRAVIS_BRANCH

if [ -z "$NO_COVERAGE" -a "$(basename $TRAVIS_REPO_SLUG)" == "$ANGR_REPO" ]
then
	COVERAGE="--with-coverage --cover-package=$ANGR_REPO --cover-erase"
fi

NOSE_OPTIONS="-v --nologcapture --with-timer $COVERAGE --processes=2 --process-timeout=570 --process-restartworker"

cd $ANGR_REPO
if [ -f "test.py" ]
then
	nosetests $NOSE_OPTIONS test.py
elif [ -d "tests" ]
then
	echo
	echo -e "\e[31m### Running tests for repository $ANGR_REPO\e[0m"
	nosetests $NOSE_OPTIONS tests/
else
	echo
	echo -e "\e[31m### No tests for repository $ANGR_REPO?\e[0m"
fi

if [ "$(basename $TRAVIS_REPO_SLUG)" == "$ANGR_REPO" ]; then
	echo
	echo -e "\e[31m### Running linting for repository $ANGR_REPO\e[0m"
	../lint.py
fi
exit 0
