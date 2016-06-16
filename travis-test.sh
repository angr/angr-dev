#!/bin/bash -e

./git_all.sh checkout master
./git_all.sh checkout $TRAVIS_BRANCH

if [ "$(basename $TRAVIS_REPO_SLUG)" == "$ANGR_REPO" ]
then
	COVERAGE="--with-coverage --cover-package=$ANGR_REPO --cover-erase"
fi

cd $ANGR_REPO
if [ -f "test.py" ]
then
	nosetests -v --nologcapture --with-timer $COVERAGE test.py
elif [ -d "tests" ]
then
	nosetests -v --nologcapture --with-timer $COVERAGE tests/
else
	echo "### No tests for repository $ANGR_REPO?"
fi

[ "$(basename $TRAVIS_REPO_SLUG)" == "$ANGR_REPO" ] && ../lint.py
exit 0
