#!/usr/bin/env bash
set -e

NAME=$1
DIR=$(dirname $0)
cd $DIR

#sudo apt-get install cmake libreadline-dev

if [ -z "$NAME" ]; then
	echo "use this script with ./pypy_venv <NAME>"
	exit
fi

# setup
mkdir -p pypy
cd pypy


if [ -f "/etc/NIXOS" ]; then
    echo "This is NixOS, using pypy from nix-shell"

    set +e
    source $(command -v virtualenvwrapper.sh)
    mkvirtualenv -p $(command -v pypy3) $NAME
    set -e

    echo "installed pypy in $NAME"
    exit 0
elif [ -f "/etc/arch-release" ]; then
    echo "This is an arch distro"
    ARCH=$(uname -m)
    SUBVERSION=$(pacman -Si pypy3 | grep "Version\s*:\s*[0-9.\-]*" | grep -o "[0-9.\-]*")
    VERSION=${2-pypy3-$SUBVERSION-$ARCH}
    # get pypy
    [ ! -e $VERSION.pkg.tar.xz ] && wget https://mirrors.kernel.org/archlinux/community/os/$ARCH/$VERSION.pkg.tar.xz
    if [ ! -e $VERSION ]; then
        tar xf $VERSION.pkg.tar.xz
        mv ./opt/pypy3 ./$VERSION
    fi

    set +e
    source /usr/bin/virtualenvwrapper.sh
    set -e
else
    if [ "$(uname)" == "Darwin" ]; then PYPY_OS=osx64; else PYPY_OS=linux64; fi
    DOWNLOAD_URL=$(wget -q -O - https://www.pypy.org/download.html | egrep -o 'https://downloads.python.org/pypy/pypy3[^"]+' | grep "$PYPY_OS" | head -n 1)

    # get pypy
    wget $DOWNLOAD_URL --local-encoding=utf-8 -O - | tar xj

    if [ -e /etc/pacman.conf ]
    then
        set +e
        source /usr/bin/virtualenvwrapper.sh >>$OUTFILE 2>>$ERRFILE
        set -e
    elif [ -e /etc/fedora-release ]
    then
        set +e
        source /usr/bin/virtualenvwrapper-3.sh
        set -e
    elif [ -e /etc/NIXOS ]
    then
        set +e
        source $(command -v virtualenvwrapper.sh) 
        set -e
    else
        python3 -m pip install virtualenvwrapper 
        set +e
        if [ -f /etc/bash_completion.d/virtualenvwrapper ]
        then
            source /etc/bash_completion.d/virtualenvwrapper 
        elif [ -f /usr/local/bin/virtualenvwrapper.sh ]
        then
            export VIRTUALENVWRAPPER_PYTHON=$(which python3)
            source /usr/local/bin/virtualenvwrapper.sh 
        elif [ -f  /usr/share/virtualenvwrapper/virtualenvwrapper.sh ]
        then
            export VIRTUALENVWRAPPER_PYTHON=$(which python3)
            source /usr/share/virtualenvwrapper/virtualenvwrapper.sh  
        fi
        set -e
    fi
fi


# virtualenv
set +e
mkvirtualenv -p "$PWD/"pypy3.6-*/bin/pypy3 $NAME
set -e
pip install -U setuptools

echo "installed pypy in $NAME"
exit 0
