#!/usr/bin/env bash

if [ -z "$VIRTUAL_ENV" ]; then
  echo "Are you sure you want to install angr outside a python virtual environment?"
  echo "It is highly recommended to use a virtualenv when working with angr."
  echo -n "y/N "
  read choice
  if ! [ "$choice" = y -o "$choice" = Y ]; then
    exit 1
  fi
fi

## BEGIN VERY COMPLICATED INSTALL PROCEDURE

git clone https://github.com/angr/archinfo.git
git clone --recursive https://github.com/angr/pyvex.git
git clone https://github.com/angr/claripy.git
git clone https://github.com/angr/cle.git
git clone https://github.com/angr/angr.git
git clone https://github.com/angr/ailment.git
git clone https://github.com/angr/angr-doc.git
git clone https://github.com/angr/binaries.git

python -m pip install -U pip wheel setuptools "unicorn==1.0.2rc4"

pip install -e ./ailment
pip install -e ./archinfo
pip install -e ./pyvex
pip install -e ./claripy
pip install -e ./cle
pip install --no-build-isolation -e ./angr

## END VERY COMPLICATED INSTALL PROCEDURE

