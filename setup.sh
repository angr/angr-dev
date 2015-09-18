#!/bin/bash -e

SCRIPT_DIR=$(dirname $0)
cd $SCRIPT_DIR

function usage
{
	echo "Usage: $0 [-i] [-e ENV] [-p ENV] [-r REMOTE] [EXTRA_REPOS]"
	echo
	echo "    -i		install required packages"
	echo "    -C		don't do the actual installation (quit after cloning)"
	echo "    -e ENV	create a cpython environment ENV"
	echo "    -E ENV	re-create a cpython environment ENV"
	echo "    -p ENV	create a pypy environment ENV"
	echo "    -p ENV	create a pypy environment ENV"
	echo "    -r REMOTE	use a different remote base (default: https://github.com/angr/)"
	echo "             	Can be specified multiple times."
	echo "    EXTRA_REPOS	any extra repositories you want to clone from the angr org."
	echo
	echo "This script clones all the angr repositories and sets up an angr"
	echo "development environment."

	exit 1
}

DEBS="virtualenvwrapper python2.7-dev build-essential libxml2-dev libxslt1-dev git libffi-dev cmake libreadline-dev"

INSTALL_REQS=0
ANGR_VENV=
USE_PYPY=
RMVENV=0
REMOTES=
INSTALL=1

while getopts "iCe:E:p:P:r:h" opt
do
	case $opt in
		i)
			INSTALL_REQS=1
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
		\?)
			usage
			;;
		h)
			usage
			;;
	esac
done

EXTRA_REPOS=${@:$OPTIND:$OPTIND+100}

function info
{
	echo "$(tput setaf 4)[+] $@$(tput sgr0)"
}

function warning
{
	echo "$(tput setaf 3)[!] $@$(tput sgr0)"
}

function debug
{
	echo "$(tput setaf 6)[-] $@$(tput sgr0)"
}

function error
{
	echo "$(tput setaf 1)[!!] $@$(tput sgr0)"
	exit 1
}

if [ "$INSTALL_REQS" -eq 1 ]
then
	info Installing dependencies...
	[ -e /etc/debian_version ] && sudo apt-get install -y $DEBS
	[ ! -e /etc/debian_version ] && error "We don't know which dependencies to install for this sytem.\nPlease install the equivalents of these debian packages: $DEBS."
fi

info "Checking dependencies..."
[ -e /etc/debian_version -a $(dpkg -l $DEBS | wc -l) -ne 14 ] && echo "Please install the following packages: $DEBS" && exit 1
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

REMOTES="$REMOTES https://git:@github.com/angr https://git:@github.com/zardus https://git:@github.com/rhelmot"
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
		debug "Trying to clone from $URL"
		( git clone $URL >> /tmp/angr-$$ 2>> /tmp/angr-$$ ) && debug "Success!" && break
	done

	if [ ! -e $NAME ]
	then
		error "Failed to clone $NAME. Error was:"
		cat /tmp/angr-$$
		rm -f /tmp/angr-$$
		return 1
	fi

	rm -f /tmp/angr-$$
	return 0
}

REPOS="ana idalink cooldict mulpyplexer monkeyhex superstruct vex pyvex archinfo cle claripy simuvex angr angr-management $EXTRA_REPOS"

info "Cloning angr components!"
for r in $REPOS
do
	clone_repo $r || exit 1
	[ -e "$NAME/setup.py" ] && TO_INSTALL="$TO_INSTALL $NAME"
done

if [ $INSTALL -eq 1 ]
then
	info "Deploying links into virtual environment!"
	(python --version 2>&1| grep -q PyPy) && TO_INSTALL=${TO_INSTALL// angr-management/}
	pip install ${TO_INSTALL// / -e }

	info "Installing some other helpful stuff."
	pip install ipython pylint ipdb nose
fi

echo ''
info "All done! Execute \"workon $ANGR_VENV\" to use your new angr virtual"
info "environment. Any changes you make in the repositories will reflect"
info "immediately in the virtual environment, with the exception of things"
info "requiring compilation (i.e., pyvex). For those, you will need to rerun"
info "the install after changes (i.e., \"pip install -I -e pyvex\")."
