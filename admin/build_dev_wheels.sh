#!/bin/bash -e

# you may want to run this script in a manylinux docker image: e.g. set MANYLINUX=cp38-cp38
MANYLINUX=${MANYLINUX-}

QUIET=${QUIET-}

REPO_ROOT="$(realpath "$(dirname $0)/..")"

# if you edit this or specify a new value make sure the packages are in dependency order!
REPOS=${REPOS-archinfo pyvex claripy cle angr}

OUTDIR=$(realpath "${OUTDIR-./build}")
mkdir -p "$OUTDIR"

if [[ -n "$MANYLINUX" ]]; then
	docker run -it --rm -v "$REPO_ROOT:/angr" -v "$OUTDIR:/output" -e REPOS="$REPOS" -e OUTDIR=/output -e PYTHON="/opt/python/$MANYLINUX/bin/python" -e QUIET=1 quay.io/pypa/manylinux2014_x86_64 sh -c "/angr/admin/build_dev_wheels.sh; chown $(id -u):$(id -g) /output/*"
else
	PYTHON=${PYTHON-$(which python3)}

	$PYTHON -m pip install -U setuptools wheel build
	export PIP_FIND_LINKS=$OUTDIR

	for REPO in $REPOS; do
		$PYTHON -m build --outdir "$OUTDIR" "$REPO_ROOT/$REPO"
	done
fi

if [[ -z "$QUIET" ]]; then
	echo 'All done!'
	echo "Wheels for $REPOS can be found in $OUTDIR"
fi
