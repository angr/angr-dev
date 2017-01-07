#!/bin/bash -e

NAME=$1
DIR=$(dirname $0)
cd $DIR

#sudo apt-get install cmake libreadline-dev

# setup
mkdir -p pypy
cd pypy


if [ -f "/etc/arch-release" ]; then
    echo "This is an arch distro"
    ARCH=$(uname -m)
    SUBVERSION=$(pacman -Si pypy | grep "Version\s*:\s*[0-9.\-]*" | grep -o "[0-9.\-]*")
    VERSION=${2-pypy-$SUBVERSION-$ARCH}
    # get pypy
    [ ! -e $VERSION.pkg.tar.xz ] && wget https://mirrors.kernel.org/archlinux/community/os/$ARCH/$VERSION.pkg.tar.xz
    if [ ! -e $VERSION ]; then
        tar xf $VERSION.pkg.tar.xz
        mv ./opt/pypy ./$VERSION
    fi
else
    VERSION=${2-pypy2-v5.6.0-linux64}

    # get pypy
    [ ! -e $VERSION ] && wget https://bitbucket.org/pypy/pypy/downloads/$VERSION.tar.bz2 --local-encoding=utf-8 -O - | tar xj
fi


# virtualenv
set +e
source /etc/bash_completion.d/virtualenvwrapper
mkvirtualenv -p $PWD/$VERSION/bin/pypy $NAME
set -e
pip install -U setuptools

# readline
[ ! -e pyreadline-cffi ] && git clone https://github.com/yuyichao/pyreadline-cffi.git
cd pyreadline-cffi && cmake CMakeLists.txt && make && make install
rm -f $VIRTUAL_ENV/lib_pypy/readline.*
ln -s $VIRTUAL_ENV/site-packages/readline $VIRTUAL_ENV/lib_pypy/readline

echo "installed pypy in $NAME"
exit 0
