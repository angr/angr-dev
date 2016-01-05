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
	echo 4.$(($(date +%y)-10)).$(date +%m.%d | sed -e "s/^0*//g" -e "s/\.0*/./g")
}

export REPOS=${REPOS-angr-management angr-doc angr simuvex claripy cle pyvex archinfo vex}

case $CMD in
	release)
		VERSION=$1
		shift || true
		[ -z "$VERSION" ] && VERSION=$(today_version)

		./git_all.sh checkout master
		$0 version $VERSION
		./git_all.sh commit --author "angr release bot <angr@lists.cs.ucsb.edu>" -m "ticked version number to $VERSION" setup.py
		./git_all.sh diff origin/master master | cat
		echo
		echo -n "Does the diff look good (y|n)? "
		read a
		[ "$a" == "y" ] || exit 1
		./git_all.sh push origin master
		./git_all.sh push github master
		./git_all.sh checkout @{-1}
		$0 register
		$0 sdist
		#[[ $REPOS == *pyvex* ]] && REPOS=pyvex $0 wheel pyvex
		;;
	sync)
		./git_all.sh checkout master
		./git_all.sh pull origin master
		./git_all.sh pull github master
		./git_all.sh push github master
		./git_all.sh push origin master
		./git_all.sh checkout @{-1}
		;;
	version)
		VERSION=$1
		shift || true
		[ -z "$VERSION" ] && VERSION=$(today_version)

		for i in $REPOS
		do
			[ ! -e $i/setup.py ] && continue

			cd $i
			if [ "$(git show --format="%aN" -s HEAD)" == 'angr release bot' ]
			then
				echo "Skipping $i -- no changes"
				cd ..
				continue
			fi

			echo "Ticking version number of $i to $VERSION"
			sed -i -e "s/version=['\"][^'\"]*['\"]/version='$VERSION'/g" setup.py
			cd ..
		done
		;;
	remote)
		NAME=$1
		shift

		PREFIX=$1
		shift

		for i in $REPOS
		do
			cd $i
			git remote rm $NAME || echo "no remote $NAME set for $i"
			git remote add $NAME $PREFIX/$i
			cd ..
		done
		;;
	register)
		for i in $REPOS
		do
			[ ! -e $i/setup.py ] && continue

			cd $i
			python setup.py register
			cd ..
		done
		;;
	sdist)
		for i in $REPOS
		do
			[ ! -e $i/setup.py ] && continue

			cd $i
			python setup.py sdist upload
			cd ..
		done
		;;
	wheel)
		for i in $REPOS
		do
			[ ! -e $i/setup.py ] && continue

			cd $i
			python setup.py bdist_wheel upload
			cd ..
		done
		;;
	*)
		echo "Unknown command."
		;;
esac
