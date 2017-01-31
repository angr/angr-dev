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
center_align() {
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
	git pull 2>&1 | tee /dev/stderr | grep -q "ssh_exchange_identification:"
	CMD_STATUS=${PIPESTATUS[0]} GREP_MATCH=${PIPESTATUS[2]}

	if [ "$GREP_MATCH" -eq 0 ]
	then
		red "Too many concurrent connections to the server. Retrying after sleep."
		sleep $[$RANDOM % 5]
		careful_pull
		return $?
	else
		return $CMD_STATUS
	fi
}

function checkup
{
	# http://stackoverflow.com/questions/1593051/how-to-programmatically-determine-the-current-checked-out-git-branch
	branch_name="$(git symbolic-ref HEAD 2>/dev/null)" ||
	branch_name="(unnamed branch)"     # detached HEAD
	branch_name=${branch_name##refs/heads/}

	git status --porcelain | egrep '^(M| M)' >/dev/null 2>/dev/null
	is_dirty=$?

	[ "$branch_name" != "master" ]
	isnt_master=$?

	if [ $is_dirty == 0 -o $isnt_master == 0 ]; then
		center_align $1 "-"
	fi

	if [ $isnt_master == 0 ]; then
		echo "On branch $RED$branch_name$NORMAL"
	fi

	if [ $is_dirty == 0 ]; then
		echo "Uncommitted files:"
		git status --porcelain | egrep --color=always '^(M| M)'
	fi
}

function success
{
	center_align "SUCCESS" "-"
	SUCCESSFUL="$SUCCESSFUL $1"
}

function fail
{
	center_align "FAILURE (return code $2)" "-" "$RED"
	FAILED="$FAILED $1"
}

function do_one
{
	DIR=$1
	shift

	cd $DIR
	if ! [ "$1" == "CHECKUP" ]; then
		center_align "RUNNING ON: $DIR" "#"
	fi

	if [ "$1" == "CAREFUL_PULL" ]; then
		careful_pull && success $DIR || fail $DIR $?
	elif [ "$1" == "CHECKUP" ]; then
		checkup $DIR
	else
		git "$@" && success $DIR || fail $DIR $?
	fi
	cd ..
}

function do_all
{
	for i in $REPOS
	do
		do_one $i "$@"
	done

	echo ""
	if [ -n "$SUCCESSFUL" ]
	then
		green "# Succeeded:"
		echo $SUCCESSFUL
	fi
	echo ""
	if [ -n "$FAILED" ]
	then
		red "# Failed:"
		echo $FAILED
		if [ -n "$EXIT_FAILURE" ]
		then
			echo "Exiting due to EXIT_FAILURE option..."
			exit 1
		fi
	fi
}

function do_screen
{
	SESSION=git-all-$$
	screen -S $SESSION -d -m sleep 2
	for i in $REPOS
	do
		screen -S $SESSION -X screen -t $i bash -c "REPOS=$i EXIT_FAILURE=1 CONCURRENT=0 ./git_all.sh $@ || bash"
	done
	screen -rd $SESSION

}

[ -z "$REPOS" ] && REPOS=$(ls -d */.git | sed -e "s/\/\.git//")

if [ "$CONCURRENT" == "1" ]
then
	do_screen "$@"
else
	do_all "$@"
fi
