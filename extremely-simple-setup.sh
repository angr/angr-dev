#!/usr/bin/env bash

git clone https://github.com/angr/archinfo.git
git clone --recursive https://github.com/angr/pyvex.git
git clone https://github.com/angr/cle.git
git clone https://github.com/angr/claripy.git
git clone https://github.com/angr/ailment.git
git clone https://github.com/angr/angr.git
git clone https://github.com/angr/angr-management.git
git clone https://github.com/angr/binaries.git

python -m pip install -U pip wheel setuptools cffi "unicorn==2.0.1.post1"

pip install -e ./archinfo
pip install -e ./pyvex
pip install -e ./cle
pip install -e ./claripy
pip install -e ./ailment
pip install --no-build-isolation -e ./angr
pip install -e ./angr-management

