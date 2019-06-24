#!/usr/bin/env bash
set -e

INTERNAL_PYTHON=/opt/python/cp27-cp27mu/bin/python
INTERNAL_PIP=/opt/python/cp27-cp27mu/bin/pip
DEST=$1
if [ -z "$DEST" ]; then
	echo "Usage: $0 dest_dir repo1 repo2 ..."
	exit 1
fi

if [ -z "$2" ]; then
	exec "$0" "$DEST" angr-z3 pyvex capstone unicorn simuvex
fi

mkdir -p $DEST
shift

cat > $DEST/build.sh <<EOF
#!/usr/bin/env bash
set -e

yum install -y libffi libffi-devel

EOF

while [ "$1" ]; do
	REPO="$1"
	shift

	DIST_FOLDER=dist
	if [[ "$REPO" == "angr-z3" ]]; then
		DIST_FOLDER=src/api/python/dist
	elif [[ "$REPO" == "unicorn" ]]; then
		DIST_FOLDER=bindings/python/dist
	elif [[ "$REPO" == "capstone" ]]; then
		DIST_FOLDER=bindings/python/dist
	fi

	cat >> $DEST/build.sh <<EOF
	echo "Working on $REPO"
	git clone https://github.com/angr/$REPO
	cd $REPO
	$INTERNAL_PYTHON setup.py bdist_wheel
	cp $DIST_FOLDER/* /output
	$INTERNAL_PIP install $DIST_FOLDER/*
	cd -

EOF

	if [[ "$REPO" == "pyvex" ]]; then
		cat >> $DEST/build.sh <<EOF
	if [ "\$(uname -p)" == "x86_64" ]; then
		echo "Archiving vex static library"
		cd pyvex
		mv vex-master vex
		tar -czf /output/vex-$(date "+%Y.%m.%d").tar.gz vex/libvex.a vex/priv/*.o
		cd -
	fi

EOF
	fi
done

chmod +x $DEST/build.sh

sudo docker run -it --rm -v $(realpath $DEST):/output quay.io/pypa/manylinux1_x86_64 /output/build.sh
sudo docker run -it --rm -v $(realpath $DEST):/output quay.io/pypa/manylinux1_i686 /output/build.sh
sudo chown $(id -un):$(id -un) $(realpath $DEST)/*
rm $DEST/build.sh
