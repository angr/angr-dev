#!/bin/bash

#while getopt "v" opt
#do
#	case $opt in
#		v)
#			VERSION=$OPTARG
#			;;
#	esac
#done

CMD=$1
shift

function today_version
{
	echo 4.$(($(date +%y)-10)).$(date +%d.%m | tr -d 0)
}

case $CMD in
	release)
		VERSION=$1
		shift
		[ -z "$VERSION" ] && VERSION=$(today_version)

		REPOS=$@
		[ -z "$REPOS" ] && REPOS="angr-management angr simuvex claripy cle pyvex archinfo"

		$0 version $VERSION $REPOS
		REPOS=$REPOS ./git_all.sh checkout master
		REPOS=$REPOS ./git_all.sh commit -m "ticked version number to $VERSION" setup.py
		REPOS=$REPOS ./git_all.sh push origin master
		REPOS=$REPOS ./git_all.sh push github master
		$0 register $REPOS
		$0 sdist $REPOS
		$0 wheel pyvex
		;;
	version)
		VERSION=$1
		shift
		[ -z "$VERSION" ] && VERSION=$(today_version)

		for i in $@
		do
			sed -i -e "s/version=['\"][^'\"]*['\"]/version='$VERSION'/g" $i/setup.py
		done
		;;
	register)
		for i in $@
		do
			cd $i
			python setup.py register
			cd ..
		done
		;;
	sdist)
		for i in $@
		do
			cd $i
			python setup.py sdist upload
			cd ..
		done
		;;
	wheel)
		for i in $@
		do
			cd $i
			python setup.py bdist_wheel upload
			cd ..
		done
		;;
esac
