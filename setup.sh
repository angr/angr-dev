#!/bin/bash -e

SCRIPT_DIR=$(dirname $0)
cd $SCRIPT_DIR

function usage
{
	echo "Usage: $0 [-i] [-e ENV] [-p ENV] [-r REMOTE] [EXTRA_REPOS]"
	echo
	echo "    -i		install required packages"
	echo "    -C		don't do the actual installation (quit after cloning)"
	echo "    -w		use pre-built packages where available"
	echo "    -v		verbose (don't redirect installation logging)"
	echo "    -e ENV	create a cpython environment ENV"
	echo "    -E ENV	re-create a cpython environment ENV"
	echo "    -p ENV	create a pypy environment ENV"
	echo "    -P ENV	re-create a pypy environment ENV"
	echo "    -r REMOTE	use a different remote base (default: https://github.com/angr/)"
	echo "             	Can be specified multiple times."
	echo "    EXTRA_REPOS	any extra repositories you want to clone from the angr org."
	echo
	echo "This script clones all the angr repositories and sets up an angr"
	echo "development environment."

	exit 1
}

DEBS=${DEBS-virtualenvwrapper python2.7-dev build-essential libxml2-dev libxslt1-dev git libffi-dev cmake libreadline-dev libtool debootstrap debian-archive-keyring libglib2.0-dev libpixman-1-dev}

INSTALL_REQS=0
ANGR_VENV=
USE_PYPY=
RMVENV=0
REMOTES=
INSTALL=1
WHEELS=0
VERBOSE=0

while getopts "iCwve:E:p:P:r:h" opt
do
	case $opt in
		i)
			INSTALL_REQS=1
			;;
		v)
			VERBOSE=1
			;;
		e)
			ANGR_VENV=$OPTARG
			USE_PYPY=0
			;;
		E)
			ANGR_VENV=$OPTARG
			USE_PYPY=0
			RMVENV=1
			;;
		p)
			ANGR_VENV=$OPTARG
			USE_PYPY=1
			;;
		P)
			ANGR_VENV=$OPTARG
			USE_PYPY=1
			RMVENV=1
			;;
		r)
			REMOTES="$REMOTES $OPTARG"
			;;
		C)
			INSTALL=0
			;;
		w)
			WHEELS=1
			;;
		\?)
			usage
			;;
		h)
			usage
			;;
	esac
done

EXTRA_REPOS=${@:$OPTIND:$OPTIND+100}

if [ $VERBOSE -eq 1 ]
then
	OUTFILE=/dev/stdout
	ERRFILE=/dev/stderr
else
	OUTFILE=/tmp/pip-$$
	ERRFILE=/tmp/pip-$$
fi

function info
{
	echo "$(tput setaf 4 2>/dev/null)[+] $@$(tput sgr0 2>/dev/null)"
}

function warning
{
	echo "$(tput setaf 3 2>/dev/null)[!] $@$(tput sgr0 2>/dev/null)"
}

function debug
{
	echo "$(tput setaf 6 2>/dev/null)[-] $@$(tput sgr0 2>/dev/null)"
}

function error
{
	echo "$(tput setaf 1 2>/dev/null)[!!] $@$(tput sgr0 2>/dev/null)" >&2
	exit 1
}

if [ "$INSTALL_REQS" -eq 1 ]
then
	info Installing dependencies...
	[ -e /etc/debian_version ] && sudo apt-get install -y $DEBS
	[ ! -e /etc/debian_version ] && error "We don't know which dependencies to install for this sytem.\nPlease install the equivalents of these debian packages: $DEBS."
fi

info "Checking dependencies..."
[ -e /etc/debian_version -a $(dpkg --get-selections $DEBS | wc -l) -ne $(echo $DEBS | wc -w) ] && echo "Please install the following packages: $DEBS" && exit 1
[ ! -e /etc/debian_version ] && echo -e "WARNING: make sure you have dependencies installed.\nThe debian equivalents are: $DEBS.\nPress enter to continue." && read a

set +e
source /etc/bash_completion.d/virtualenvwrapper
set -e

if [ -n "$ANGR_VENV" ]
then
	set +e
	if [ -n "$VIRTUAL_ENV" ]
	then
		# We can't just deactivate, since those functions are in the parent shell.
		# So, we do some hackish stuff.
		PATH=${PATH/$VIRTUAL_ENV\/bin:/}
		unset VIRTUAL_ENV
	fi

	if [ "$RMVENV" -eq 1 ]
	then
		info "Removing existing virtual environment $ANGR_VENV..."
		rmvirtualenv $ANGR_VENV || error "Failed to remote virtualenv $ANGR_VENV."
	elif lsvirtualenv | grep -q "^$ANGR_VENV$"
	then
		error "Virtualenv $ANGR_VENV already exists."
	fi

	if [ "$USE_PYPY" -eq 1 ]
	then
		./pypy_venv.sh $ANGR_VENV
	else
		mkvirtualenv $ANGR_VENV
	fi

	set -e
	workon $ANGR_VENV || error "Unable to activate the virtual environment."
fi

if [ -z "$VIRTUAL_ENV" ]
then
	warning "You are installing angr outside of a virtualenv. This is NOT"
	warning "RECOMMENDED. Activate a virtualenv before running this script"
	warning "or use one of the following options: -e -E -p -P. Please type"
	warning "\"I know this is a bad idea.\" (without quotes) and press enter"
	warning "to continue."

	read ans
	if [ "$ans" != "I know this is a bad idea." ]
	then
		exit 1
	fi
fi

ORIGIN_REMOTE=$(git remote -v | grep origin | head -n1 | awk '{print $2}' | sed -e "s/\/angr-dev.*//")
REMOTES="$REMOTES ${ORIGIN_REMOTE/\/github.com/\/git:@github.com} https://git:@github.com/zardus https://git:@github.com/rhelmot"

function try_remote
{
	URL=$1
	debug "Trying to clone from $URL"
	rm -f /tmp/clone-$$
	git clone $URL >> /tmp/clone-$$ 2>> /tmp/clone-$$
	r=$?

	if grep -q -E "(ssh_exchange_identification: read: Connection reset by peer|ssh_exchange_identification: Connection closed by remote host)" /tmp/clone-$$
	then
		warning "Too many concurrent connections to the server. Retrying after sleep."
		sleep $[$RANDOM % 5]
		try_remote $URL
		return $?
	else
		[ $r -eq 0 ] && rm -f /tmp/clone-$$
		return $r
	fi
}

function clone_repo
{
	NAME=$1
	if [ -e $NAME ]
	then
		info "Skipping $NAME -- already cloned."
		return 0
	fi

	info "Cloning repo $NAME."
	for r in $REMOTES
	do
		URL="$r/$NAME"
		try_remote $URL && debug "Success!" && break
	done

	if [ ! -e $NAME ]
	then
		error "Failed to clone $NAME. Error was:"
		cat /tmp/clone-$$
		rm -f /tmp/clone-$$
		return 1
	fi

	return 0
}

function install_wheels
{
	LATEST_Z3=$(ls -tr wheels/angr_only_z3_custom-*)
	echo "Installing $LATEST_Z3..." >> $OUTFILE 2>> $ERRFILE
	pip install $LATEST_Z3 >> $OUTFILE 2>> $ERRFILE

	LATEST_VEX=$(ls -tr wheels/vex-*)
	echo "Extracting $LATEST_VEX..." >> $OUTFILE 2>> $ERRFILE
	tar xvzf $LATEST_VEX >> $OUTFILE 2>> $ERRFILE
}

REPOS=${REPOS-ana idalink cooldict mulpyplexer monkeyhex superstruct archinfo vex pyvex cle claripy simuvex angr angr-management angr-doc binaries $EXTRA_REPOS}
[ $WHEELS -eq 1 ] && REPOS="$REPOS wheels"

info "Cloning angr components!"
for r in $REPOS
do
	clone_repo $r || exit 1
	[ -e "$NAME/setup.py" ] && TO_INSTALL="$TO_INSTALL $NAME"
done

if [ $INSTALL -eq 1 ]
then
	info "Installing python packages (logging to $OUTFILE)!"

	[ $WHEELS -eq 1 ] && install_wheels

	# remove angr-management if running in pypy or in travis
	(python --version 2>&1| grep -q PyPy) && TO_INSTALL=${TO_INSTALL// angr-management/}
	[ -n "$TRAVIS" ] && TO_INSTALL=${TO_INSTALL// angr-management/}

	if pip install ${TO_INSTALL// / -e } >> $OUTFILE 2>> $ERRFILE
	then
		info "Success!"
		[ $VERBOSE -eq 1 ] || rm -f $OUTFILE
	else
		error "Something failed to install. Check $OUTFILE for details."
		exit 1
	fi

	info "Installing some other helpful stuff (logging to /tmp/pip-$$)."
	if pip install ipython pylint ipdb nose nose-timer coverage >> $OUTFILE 2>> $ERRFILE
	then
		info "Success!"
		[ $VERBOSE -eq 1 ] || rm -f $OUTFILE
	else
		error "Something failed to install. Check /tmp/pip-$$ for details."
		exit 1
	fi
fi

echo ''
info "All done! Execute \"workon $ANGR_VENV\" to use your new angr virtual"
info "environment. Any changes you make in the repositories will reflect"
info "immediately in the virtual environment, with the exception of things"
info "requiring compilation (i.e., pyvex). For those, you will need to rerun"
info "the install after changes (i.e., \"pip install -I -e pyvex\")."
