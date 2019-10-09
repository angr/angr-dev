# This script fixes the dynamic libraries on macOS.
# Because of System Integrity measures, relative paths to libs are no longer valid, so we need to change those
# macOS brings a tool to do exactly that

# To get the correct results for the site packages, we want to be in the angr python context
if [ -z "$VIRTUAL_ENV" ]
then
	echo "Please activate your angr virtualenv before executing this script."
	echo "If you installed angr on your default python (bad idea) and want to continue, type 'continue'"
	read ans
	if ["$ans" != "continue"]
	then
		exit 1
	fi
fi
# To work for any setup, we get the paths to the relevant packages from python itself. (May not be in site packages)
PYVEX=`python -c 'import pyvex; print(pyvex.__path__[0])'`
echo "pyvex packate at $PYVEX"
UNICORN=`python -c 'import unicorn; print(unicorn.__path__[0])'`
echo "unicorn package at $UNICORN"
ANGR=`python -c 'import logging; logging.basicConfig(level=logging.CRITICAL); import angr; print(angr.__path__[0])'`
echo "angr package at $ANGR"

install_name_tool -change libunicorn.1.dylib "$UNICORN"/lib/libunicorn.dylib "$ANGR"/lib/angr_native.dylib
install_name_tool -change libpyvex.dylib "$PYVEX"/lib/libpyvex.dylib "$ANGR"/lib/angr_native.dylib
