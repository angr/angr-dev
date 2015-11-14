#!/bin/bash

function green
{
	echo "$(tput setaf 6 2>/dev/null)$@$(tput sgr0 2>/dev/null)"
}

function red
{
	echo "$(tput setaf 1 2>/dev/null)$@$(tput sgr0 2>/dev/null)"
}

RED=$(tput setaf 1 2>/dev/null)
GREEN=$(tput setaf 2 2>/dev/null)
NORMAL=$(tput sgr0 2>/dev/null)
right_align() {
	MSG="$1"
	PADDING="$2"
	COLOR="$3"

	[ -z "$PADDING" ] && PADDING="="
	[ -z "$COLOR" ] && COLOR="$GREEN"
	[ -e $(which tput) ] && COL=$(tput cols) || COL=80
	let PAD=\($COL-${#MSG}-2\)/2

	printf "$COLOR"
	printf -- "$PADDING%.0s" $(eval "echo {1..$PAD}")
	printf " %s " "$MSG"
	printf -- "$PADDING%.0s" $(eval "echo {1..$PAD}")
	[ $[$PAD*2 + ${#MSG} + 2] -lt $COL ] && printf "$PADDING"
	printf "$NORMAL"
	printf "\n"
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
	right_align "RUNNING ON: $DIR" "#"

	if [ "$1" == "CAREFUL_PULL" ]
	then
		careful_pull && right_align "SUCCESS" "-" || right_align "FAILURE (return code $?)" "-" "$RED"
	else
		git "$@" && right_align "SUCCESS" "-" || right_align "FAILURE (return code $?)" "-" "$RED"
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
