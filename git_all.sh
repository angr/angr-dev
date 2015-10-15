#!/bin/bash

function green
{
	echo "$(tput setaf 6 2>/dev/null)$@$(tput sgr0 2>/dev/null)"
}

function red
{
	echo "$(tput setaf 1 2>/dev/null)$@$(tput sgr0 2>/dev/null)"
}

function careful_pull
{
	rm -f /tmp/pull-$$
	git pull >> /tmp/pull-$$ 2>> /tmp/pull-$$
	r=$?

	if grep -q "ssh_exchange_identification: read: Connection reset by peer" /tmp/pull-$$
	then
		red "Too many concurrent connections to the server. Retrying after sleep."
		sleep $[$RANDOM % 5]
		careful_pull
		return $?
	else
		[ $r -eq 0 ] && rm -f /tmp/pull-$$
		return $r
	fi
}

function doit
{
	DIR=$1
	shift

	cd $DIR
	green "================================================================================"
	green "=== Running on $DIR."

	if [ "$1" == "CAREFUL_PULL" ]
	then
		careful_pull && green "=== SUCCESS" || red "=== FAILURE"
	else
		git "$@" && green "=== SUCCESS" || red "=== FAILURE"
	fi
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
