#!/bin/bash -e

./git_all.sh checkout master
./git_all.sh checkout $TRAVIS_BRANCH

if [ -z "$NO_COVERAGE" -a "$(basename $TRAVIS_REPO_SLUG)" == "$ANGR_REPO" ]
then
	NOSE_OPTIONS="--with-coverage --cover-package=$ANGR_REPO --cover-erase"
fi
export NOSE_PROCESSTIMEOUT=570
export NOSE_PROCESSES=2
export NOSE_OPTIONS="$NOSE_OPTIONS --with-timer"
cd $ANGR_REPO
../test.sh

if [ "$(basename $TRAVIS_REPO_SLUG)" == "$ANGR_REPO" ]; then
	echo
	echo -e "\e[31m### Running linting for repository $ANGR_REPO\e[0m"
	../lint.py
fi
exit 0
