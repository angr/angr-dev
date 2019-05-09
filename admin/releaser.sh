#!/usr/bin/env bash
set -e

VERSION_MAJOR=8

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

# If you want to enable TestPyPI, please make sure you have the following
# setup in your .pypirc:
#
# [distutils]
# index-servers=
#     pypi
#     testpypi
#
# [testpypi]
# repository: https://test.pypi.org/legacy/
# username: your testpypi username
# password: your testpypi password
#
TESTPYPI=$1
if [ ! -z "$TESTPYPI" ]; then
	if [[ "$TESTPYPI" == "yes" ]] || [[ "$TESTPYPI" == "no" ]]; then
		shift || true
	else
		TESTPYPI=""
	fi
fi
[ -z "$TESTPYPI" ] && TESTPYPI="no"

[ $TESTPYPI == "yes" ] && echo "Using the TestPyPI for testing."

function today_version
{
	echo $VERSION_MAJOR$(date +.%y.%m.%d | sed -e "s/\.0*/./g")
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

	cd angr.github.io
	git pull
	cd - >/dev/null

	make -C angr-doc/api-doc html
	rm -rf angr.github.io/api-doc
	cp -r angr-doc/api-doc/build/html angr.github.io/api-doc

	cd angr.github.io
	git commit --author "angr release bot <angr@lists.cs.ucsb.edu>" -m "updated api-docs for version $VERSION" api-doc
	git push github master
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

function version_to_tuple
{
	awk -F '.' '{ printf "(%d, %d, %d, %d)\n", $1, $2, $3, $4}' <<<"$1"
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

export REPOS=${REPOS-angr-management angr-doc angr claripy cle pyvex archinfo vex binaries angrop ailment}

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
		$0 version $TESTPYPI $VERSION
		$0 update_dep $TESTPYPI $VERSION
		MESSAGE="ticked version number to $VERSION"
		ANGRDOC_MESSAGE="updated api-docs for version $VERSION"
		./git_all.sh commit --author "angr release bot <angr@lists.cs.ucsb.edu>" -am "$MESSAGE"
		./git_all.sh diff --color=always github/master master | cat
		echo
		echo -n "Does the diff look good (y|n)? "
		read a
		if [[ ! "$a" == "y" ]]; then
			# roll back
			for repo in $REPOS; do
				cd $repo
				if [[ "$(git show -s --oneline)" == *"$MESSAGE"* ]]; then
					git reset --hard HEAD~
				elif [[ "$(git show -s --oneline)" == *"${ANGRDOC_MESSAGE}"* ]]; then
					git reset --hard HEAD~
				fi
				cd - >/dev/null

			done
			exit 1
		fi
		./git_all.sh push both master
		./git_all.sh checkout @{-1}
		$0 sdist $TESTPYPI
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
			#if [ "$(git show --format="%aN" -s HEAD)" == 'angr release bot' ]
			#then
			#	echo "Skipping $i -- no changes"
			#	cd ..
			#	continue
			#fi

			set -x
			echo "Ticking version number of $i to $VERSION"
			sed -i -e "s/version=['\"][^'\"]*['\"]/version='$VERSION'/g" setup.py
			sed -i -e "s/^__version__ = .*/__version__ = $(version_to_tuple $VERSION)/g" */__init__.py
			set +x
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

		REPO_LIST=( angr angr-management angrop cle pyvex archinfo claripy ailment )
		for i in "${REPO_LIST[@]}"
		do
			[ ! -e $i/setup.py ] && continue

			#cd $i
			#if [ "$(git show --format="%aN" -s HEAD)" == 'angr release bot' ]
			#then
			#	echo "Dependency version number of $i has already been updated."
			#	cd ..
			#	continue
			#fi
			#cd ..

			for j in "${REPO_LIST[@]}"
			do
				[ "$i" == "$j" ] && continue

				version=$(extract_version $j)
				[ -z $version ] && echo "Cannot determine version of $j. Skip" && continue

				cd $i
				echo "Updating dependency version number for $j"
				sed -i -e "s/'$j\(\(==[^']*\)\?\)',\$/'$j==$version',/" setup.py
				cd ..
			done
		done
		;;
	sdist)
        if [ "$TESTPYPI" == "yes" ]
        then
            # Use TestPyPI
            PYPI_REPO_URL="--repository testpypi"
        else
            # Use the default PyPI
            PYPI_REPO_URL=""
            echo -n "You are about to release angr to PyPI (not TestPyPI). Proceed? (y|n)? "
            read a
            if [[ ! "$a" == "y" ]]; then
                echo "Aborted."
                exit 1
            fi
        fi
		for i in $REPOS
		do
			[ ! -e $i/setup.py ] && continue

			cd $i
			python setup.py sdist
			SDIST_EXTENSION=.tar.gz
			python setup.py rotate -m $SDIST_EXTENSION -k 1 -d dist
			twine upload $PYPI_REPO_URL dist/*$SDIST_EXTENSION || echo "!!!!! FAILED TO UPLOAD $i"
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
