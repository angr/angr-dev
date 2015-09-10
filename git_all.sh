#!/bin/bash

function green
{
	echo "$(tput setaf 6)$@$(tput sgr0)"
}

function red
{
	echo "$(tput setaf 1)$@$(tput sgr0)"
}

function doit
{
	DIR=$1
	shift

	cd $DIR
	green "================================================================================"
	green "=== Running on $DIR."
	git "$@" && green "=== SUCCESS" || red "=== FAILURE"
	cd ..
}

if [ -n "$REPOS" ]
then
	for i in $REPOS
	do
		doit $i "$@"
	done
else
	for i in */.git/
	do
		i=${i/\/.git\//}
		doit $i "$@"
	done
fi
