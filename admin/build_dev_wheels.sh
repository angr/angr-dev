#!/bin/bash -e

REPO_ROOT="$(realpath "$(dirname $0)/..")"

# if you edit this or specify a new value make sure the packages are in dependency order!
REPOS=${REPOS-archinfo pyvex claripy cle ailment angr}

OUTDIR=${OUTDIR-./build}
mkdir -p "$OUTDIR"

python -m pip install -U setuptools wheel build
export PIP_FIND_LINKS=$OUTDIR

for REPO in $REPOS; do
	python -m build --outdir "$OUTDIR" "$REPO_ROOT/$REPO"
done

echo 'All done!'
echo "Wheels for $REPOS can be found in $OUTDIR"
