#!/usr/bin/env bash

git clone https://github.com/angr/archinfo.git
git clone --recursive https://github.com/angr/pyvex.git
git clone https://github.com/angr/cle.git
git clone https://github.com/angr/claripy.git
git clone https://github.com/angr/angr.git
git clone https://github.com/angr/angr-management.git
git clone https://github.com/angr/binaries.git

python -m pip install -U pip wheel setuptools setuptools-rust scikit-build-core cffi "unicorn==2.0.1.post1"

pip install -e ./archinfo --config-settings editable_mode=strict
# LOAD BEARING NOP: --no-build-isolation should do nothing here. however what actually happens is that on the first install it will fail to install one of the headers into the source tree and then subsequent installs will be just fine. whatever state controls this behavior is totally unknown and I have never managed to "clear" this state other than completely nuking the container I'm running the install in.
pip install --no-build-isolation -e ./pyvex
pip install -e ./cle --config-settings editable_mode=strict
pip install -e ./claripy --config-settings editable_mode=strict
pip install --no-build-isolation -e ./angr --config-settings editable_mode=compat
pip install -e ./angr-management --config-settings editable_mode=strict
