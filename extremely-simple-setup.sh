#!/usr/bin/env bash

git clone https://github.com/angr/archinfo.git
git clone --recursive https://github.com/angr/pyvex.git
git clone https://github.com/angr/cle.git
git clone https://github.com/angr/claripy.git
git clone https://github.com/angr/angr.git
git clone https://github.com/angr/angr-management.git
git clone https://github.com/angr/binaries.git

python -m pip install -U pip wheel setuptools setuptools-rust cffi "unicorn==2.0.1.post1"

pip install -e ./archinfo --config-settings editable_mode=strict
pip install -e ./pyvex
pip install -e ./cle --config-settings editable_mode=strict
pip install -e ./claripy --config-settings editable_mode=strict
pip install --no-build-isolation -e ./angr --config-settings editable_mode=compat
pip install -e ./angr-management --config-settings editable_mode=strict
