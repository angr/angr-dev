#!/bin/bash -e

echo "###"
echo "### Cloning angr-dev..."
echo "###"

sudo apt-get update && sudo apt-get install -y socat gdbserver gdb

cd
git clone -q https://github.com/angr/angr-dev && cd angr-dev
# Restore it later
# git checkout ${Build.SourceBranchName} || echo "No branch ${Build.SourceBranchName} in angr-dev. Using default test scripts."
./tests/shell.sh debug.angr.io 3105
./tests/azure-setup.sh
