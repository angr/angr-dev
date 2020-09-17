#!/bin/bash
set -ex

# MAJOR.MINOR.gitrolling
# MAJOR and MINOR are semver-like, they should indicate breaking changes and
# significant new features. The gitrolling is neccesary to keep the version
# different than whatever is released on PyPI. The gitrolling will be
# substituted for a different value in the release pipeline.
VERSION="9.0.gitrolling"
# omitting vex and binaries since they don't have versions
REPOS="angr-management angr-doc angr claripy cle pyvex archinfo angrop ailment"

BASE_DIR=$(realpath $(dirname $0)/..)

function version_to_tuple {
	awk -F '.' '{ printf "(%d, %d, \"%s\")\n", $1, $2, $3}' <<<"$1"
}

for repo in $REPOS; do
    pushd $BASE_DIR/$repo
    if [ "$repo" == "angr-doc" ]; then
		sed -i -e "s/version = u['\"][^'\"]*['\"]/version = u'$VERSION'/g" api-doc/source/conf.py
		sed -i -e "s/release = u['\"][^'\"]*['\"]/release = u'$VERSION'/g" api-doc/source/conf.py
    else
        sed -i -e "s/version=['\"][^'\"]*['\"]/version='$VERSION'/g" setup.py
        sed -i -e "s/^__version__ = .*/__version__ = $(version_to_tuple $VERSION)/g" */__init__.py
        for dep in $REPOS; do
            if [ "$dep" != "$repo" ]; then
                sed -i -e "s/'$dep\(\(==[^']*\)\?\)',\$/'$dep==$VERSION',/" setup.py
            fi
        done
    fi
    if ! git diff --exit-code &> /dev/null; then
        git add -A
        git commit --author "angr bot <angr-dev@asu.edu>" -m "[ci skip] Update version to $VERSION"
        git push
    fi
    popd
done
