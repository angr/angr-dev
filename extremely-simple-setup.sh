#!/usr/bin/env bash

git clone https://github.com/angr/archinfo.git
git clone --recursive https://github.com/angr/pyvex.git
git clone https://github.com/angr/cle.git
git clone https://github.com/angr/claripy.git
git clone https://github.com/angr/angr.git
git clone https://github.com/angr/angr-management.git
git clone https://github.com/angr/binaries.git

python -m pip install -U pip wheel setuptools setuptools-rust cffi "unicorn==2.1.4" nanobind scikit_build_core

pip install ${PIP_OPTIONS-} -e ./archinfo --config-settings editable_mode=strict
pip install ${PIP_OPTIONS-} -e ./pyvex
pip install ${PIP_OPTIONS-} -e ./cle --config-settings editable_mode=strict
pip install ${PIP_OPTIONS-} -e ./claripy --config-settings editable_mode=strict
pip install ${PIP_OPTIONS-} --no-build-isolation -e ./angr --config-settings editable_mode=compat
pip install ${PIP_OPTIONS-} -e ./angr-management --config-settings editable_mode=strict
