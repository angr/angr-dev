#!/bin/bash -e

VERSION_MAJOR=7

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
	echo $VERSION_MAJOR.$(($(date +%y)-10)).$(date +%m.%d | sed -e "s/^0*//g" -e "s/\.0*/./g")
}

function build_docs
{
	VERSION=$(extract_version angr)
	cd pyvex
	python setup.py build
	cd - >/dev/null

	cd angr-doc
	git checkout master
	git push github master
	cd - >/dev/null

	make -C angr-doc/api-doc html
	rm -rf angr.github.io/api-doc
	cp -r angr-doc/api-doc/build/html angr.github.io/api-doc

	cd angr.github.io
	git commit --author "angr release bot <angr@lists.cs.ucsb.edu>" -m "updated api-docs for version $VERSION" api-doc
	git push origin master
	cd - >/dev/null
}

function extract_version
{
	[ ! -d $1 ] && echo "$1 does not exist.">2 && return
	cd $1
	ver=$(sed -n -e "s/.*version='\(.\+\)'.*/\1/p" setup.py)
	cd ..
	echo $ver
}

function check_uncommitted
{
	out=0
	for repo in $REPOS; do
		cd $repo
		if ! git diff-index --quiet HEAD --; then
			echo "Untracked changes in $repo"
			out=$((out + 1))
		fi
		cd - >/dev/null
	done
	return $out
}

export REPOS=${REPOS-angr-management angr-doc angr simuvex claripy cle pyvex archinfo vex binaries angrop}

case $CMD in
	release)
		if [ -z "$VIRTUAL_ENV" ]; then
			echo "Must be in the angr virtualenv to do a release!"
			exit 1
		fi
		if ! check_uncommitted; then
			echo ""
			echo "Commit or stash your changes!"
			exit 1
		fi
		VERSION=$1
		shift || true
		[ -z "$VERSION" ] && VERSION=$(today_version)

		./git_all.sh checkout master
		$0 version $VERSION
		$0 update_dep
		MESSAGE="ticked version number to $VERSION"
		./git_all.sh commit --author "angr release bot <angr@lists.cs.ucsb.edu>" -m "$MESSAGE" setup.py requirements.txt
		./git_all.sh diff --color=always origin/master master | cat
		echo
		echo -n "Does the diff look good (y|n)? "
		read a
		if [[ ! "$a" == "y" ]]; then
			# roll back
			for repo in $REPOS angr-doc; do
				cd $repo
				if [[ "$(git show -s --oneline)" == *"$MESSAGE"* ]]; then
					git reset --hard HEAD~
				fi
				cd - >/dev/null

			done
			exit 1
		fi
		./git_all.sh push both master
		./git_all.sh checkout @{-1}
		$0 sdist
		build_docs
		#[[ $REPOS == *pyvex* ]] && REPOS=pyvex $0 wheel pyvex
		;;
	docs)
		build_docs
		;;
	sync)
		admin/remotes.sh
		./git_all.sh checkout master
		./git_all.sh pull gitlab master
		./git_all.sh pull github master
		./git_all.sh push both
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

		cd angr-doc
		sed -i -e "s/version = u['\"][^'\"]*['\"]/version = u'$VERSION'/g" api-doc/source/conf.py
		sed -i -e "s/release = u['\"][^'\"]*['\"]/release = u'$VERSION'/g" api-doc/source/conf.py
		git commit --author "angr release bot <angr@lists.cs.ucsb.edu>" -m "updated api-docs for version $VERSION" api-doc || true
		cd ..

		;;
	update_dep)
		VERSION=$1
		shift || true
		[ -z "$VERSION" ] && VERSION=$(today_version)

		REPO_LIST=( angr simuvex angr-management angrop cle pyvex archinfo claripy )
		for i in "${REPO_LIST[@]}"
		do
			[ ! -e $i/setup.py ] && continue

			cd $i
			if [ "$(git show --format="%aN" -s HEAD)" == 'angr release bot' ]
			then
				echo "Dependency version number of $i has already been updated."
				cd ..
				continue
			fi
			cd ..

			for j in "${REPO_LIST[@]}"
			do
				[ "$i" == "$j" ] && continue

				version=$(extract_version $j)
				[ -z $version ] && echo "Cannot determine version of $j. Skip" && continue

				cd $i
				echo "Updating dependency version number for $j"
				sed -i -e "s/'$j\(\(>=[^']*\)\?\)',\$/'$j>=$version',/" setup.py
				sed -i -e "s/$j\(\(>=.*\)\?\)\$/$j>=$version/" requirements.txt
				cd ..
			done
		done
		;;
	sdist)
		for i in $REPOS
		do
			[ ! -e $i/setup.py ] && continue

			cd $i
			python setup.py sdist
			SDIST_EXTENSION=.tar.gz
			python setup.py rotate -m $SDIST_EXTENSION -k 1 -d dist
			twine upload dist/*$SDIST_EXTENSION || echo "!!!!! FAILED TO UPLOAD $i"
			cd ..
		done
		;;
	wheel)
		echo "WRONG"
		;;
	*)
		echo "Unknown command."
		;;
esac
