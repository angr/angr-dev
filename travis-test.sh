#!/bin/bash -e

./git_all.sh checkout master
./git_all.sh checkout $TRAVIS_BRANCH

if [ "$(basename $TRAVIS_REPO_SLUG)" == "$ANGR_REPO" ]
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
	nosetests $NOSE_OPTIONS tests/
else
	echo "### No tests for repository $ANGR_REPO?"
fi

[ "$(basename $TRAVIS_REPO_SLUG)" == "$ANGR_REPO" ] && ../lint.py
exit 0
