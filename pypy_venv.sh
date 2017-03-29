#!/bin/bash -e

### THIS FILE IS SOURCED BY setup.sh in order get its env vars!
PYPY_INSTALL_DIR="pypy"
DIR=$(dirname $0)
cd $DIR

#sudo apt-get install cmake libreadline-dev

# setup
if [ ! -e $PYPY_INSTALL_DIR ]; then
    mkdir -p $PYPY_INSTALL_DIR
else
    rm -rf $PYPY_INSTALL_DIR/*
fi

cd $PYPY_INSTALL_DIR

if [ $DISTRO_ARCH -eq 1 ]; then
    ARCH=$(uname -m)
    SUBVERSION=$(pacman -Si pypy | grep "Version\s*:\s*[0-9.\-]*" | grep -o "[0-9.\-]*")
    VERSION=${2-pypy-$SUBVERSION-$ARCH}
    # get pypy
    [ ! -e $VERSION.pkg.tar.xz ] && wget https://mirrors.kernel.org/archlinux/community/os/$ARCH/$VERSION.pkg.tar.xz
    if [ ! -e $VERSION ]; then
        mkdir $VERSION && tar xf $VERSION.pkg.tar.xz -C $VERSION
    fi
else
    VERSION=${2-pypy2-v5.6.0-linux64}

    # get pypy
    [ ! -e $VERSION ] && mkdir $VERSION && wget https://bitbucket.org/pypy/pypy/downloads/$VERSION.tar.bz2 --local-encoding=utf-8 -O - | tar xj -C $VERSION
fi

# hackish fix to make pypy actually start
if [ ! -e $PWD/$VERSION/opt/pypy/bin/libpypy-c.so ]; then
    ln -s $PWD/$VERSION/usr/lib/libpypy-c.so $PWD/$VERSION/opt/pypy/bin/
fi

# virtualenv
set +e
mkvirtualenv -p $PWD/$VERSION/opt/pypy/bin/pypy $ANGR_VENV
set -e
pip install -U setuptools

# readline
[ ! -e pyreadline-cffi ] && git clone https://github.com/yuyichao/pyreadline-cffi.git
cd pyreadline-cffi && cmake CMakeLists.txt && make && make install && cd ..
rm -f $VIRTUAL_ENV/lib_pypy/readline.*
ln -s $VIRTUAL_ENV/site-packages/readline $VIRTUAL_ENV/lib_pypy/readline

cd ..
info "Installed pypy in $ANGR_VENV"
exit 0