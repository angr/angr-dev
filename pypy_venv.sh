#!/bin/bash -e

NAME=$1
DIR=$(dirname $0)
cd $DIR

#sudo apt-get install cmake libreadline-dev

# setup
mkdir -p pypy
cd pypy

# get pypy
[ ! -e pypy-2.6.0-linux64 ] && wget https://bitbucket.org/pypy/pypy/downloads/pypy-2.6.0-linux64.tar.bz2 --local-encoding=utf-8 -O - | tar xvj

# virtualenv
set +e
source /etc/bash_completion.d/virtualenvwrapper
mkvirtualenv -p $PWD/pypy-2.6.0-linux64/bin/pypy $NAME
set -e
pip install -U setuptools

# readline
[ ! -e pyreadline-cffi ] && git clone https://github.com/yuyichao/pyreadline-cffi.git
cd pyreadline-cffi && cmake CMakeLists.txt && make && make install
rm -f $VIRTUAL_ENV/lib_pypy/readline.*
ln -s $VIRTUAL_ENV/site-packages/readline $VIRTUAL_ENV/lib_pypy/readline

echo "installed pypy in $NAME"
exit 0
