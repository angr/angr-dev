#!/bin/bash -e

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
	echo 4.$(($(date +%y)-10)).$(date +%m.%d | tr -d 0)
}

case $CMD in
	release)
		VERSION=$1
		shift || true
		[ -z "$VERSION" ] && VERSION=$(today_version)

		REPOS=$@
		[ -z "$REPOS" ] && REPOS="angr-management angr simuvex claripy cle pyvex archinfo"

		REPOS=$REPOS ./git_all.sh checkout master
		$0 version $VERSION $REPOS
		REPOS=$REPOS ./git_all.sh commit --author "angr release bot <angr@lists.cs.ucsb.edu>" -m "ticked version number to $VERSION" setup.py
		REPOS=$REPOS ./git_all.sh show HEAD | cat
		echo
		echo -n "Does the diff look good (y|n)? "
		read a
		[ "$a" == "y" ] || exit 1
		REPOS=$REPOS ./git_all.sh push origin master
		REPOS=$REPOS ./git_all.sh push github master
		REPOS=$REPOS ./git_all.sh checkout @{-1}
		$0 register $REPOS
		$0 sdist $REPOS
		$0 wheel pyvex
		;;
	sync)
		REPOS=$@
		[ -z "$REPOS" ] && REPOS="angr-management angr simuvex claripy cle pyvex archinfo"

		REPOS=$REPOS ./git_all.sh checkout master
		REPOS=$REPOS ./git_all.sh pull origin master
		REPOS=$REPOS ./git_all.sh pull github master
		REPOS=$REPOS ./git_all.sh push github master
		REPOS=$REPOS ./git_all.sh push origin master
		REPOS=$REPOS ./git_all.sh checkout @{-1}
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
	*)
		echo "Unknown command."
		;;
esac
