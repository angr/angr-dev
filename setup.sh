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
	echo "    -e ENV	create or reuse a cpython environment ENV"
	echo "    -E ENV	re-create a cpython environment ENV"
	echo "    -p ENV	create or reuse a pypy environment ENV"
	echo "    -P ENV	re-create a pypy environment ENV"
	echo "    -r REMOTE	use a different remote base (default: https://github.com/angr/)"
	echo "             	Can be specified multiple times."
	echo "    -b BRANCH     Check out a given branch across all the repositories."
	echo "    -D            Ignore the default repo list."
	echo "    EXTRA_REPOS	any extra repositories you want to clone from the angr org."
	echo
	echo "This script clones all the angr repositories and sets up an angr"
	echo "development environment."

	exit 1
}

DEBS=${DEBS-virtualenvwrapper python2.7-dev build-essential libxml2-dev libxslt1-dev git libffi-dev cmake libreadline-dev libtool debootstrap debian-archive-keyring libglib2.0-dev libpixman-1-dev libqt4-dev graphviz-dev binutils-multiarch nasm libc6:i386 libgcc1:i386 libstdc++6:i386 libtinfo5:i386 zlib1g:i386}
REPOS=${REPOS-ana idalink cooldict mulpyplexer capstone monkeyhex superstruct archinfo vex pyvex cle claripy simuvex angr angr-management angrop angr-doc binaries}

ORIGIN_REMOTE=$(git remote -v | grep origin | head -n1 | awk '{print $2}' | sed -e "s|angr/angr-dev.*||")
REMOTES=${REMOTES-${ORIGIN_REMOTE}angr ${ORIGIN_REMOTE}shellphish ${ORIGIN_REMOTE}mechaphish https://git:@github.com/zardus https://git:@github.com/rhelmot https://git:@github.com/salls}


INSTALL_REQS=0
ANGR_VENV=
USE_PYPY=
RMVENV=0
INSTALL=1
CONCURRENT_CLONE=0
WHEELS=0
VERBOSE=0
BRANCH=

while getopts "iCcwDve:E:p:P:r:b:h" opt
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
		b)
			BRANCH=$OPTARG
			;;
		r)
			REMOTES="$OPTARG $REMOTES"
			;;
		C)
			INSTALL=0
			;;
		c)
			CONCURRENT_CLONE=1
			;;
		w)
			WHEELS=1
			;;
		D)
			REPOS=""
			;;
		\?)
			usage
			;;
		h)
			usage
			;;
	esac
done

if [ $WHEELS -eq 1 ]
then
	REPOS="$REPOS wheels"
	REPOS=${REPOS// capstone/}
fi

EXTRA_REPOS=${@:$OPTIND:$OPTIND+100}
REPOS="$REPOS $EXTRA_REPOS"

if [ $VERBOSE -eq 1 ]
then
	OUTFILE=/dev/stdout
	ERRFILE=/dev/stderr
else
	OUTFILE=/tmp/pip-$$
	ERRFILE=/tmp/pip-$$
	touch $OUTFILE
fi

function info
{
	echo "$(tput setaf 4 2>/dev/null)[+] $@$(tput sgr0 2>/dev/null)" | tee -a $OUTFILE
}

function warning
{
	echo "$(tput setaf 3 2>/dev/null)[!] $@$(tput sgr0 2>/dev/null)" | tee -a $OUTFILE
}

function debug
{
	echo "$(tput setaf 6 2>/dev/null)[-] $@$(tput sgr0 2>/dev/null)" | tee -a $OUTFILE
}

function error
{
	echo "$(tput setaf 1 2>/dev/null)[!!] $@$(tput sgr0 2>/dev/null)" >&2 | tee -a $ERRFILE
	cat $OUTFILE
	cat $ERRFILE
	exit 1
}

trap 'error "An error occurred on line $LINENO. Saved output:"' ERR

if [ "$INSTALL_REQS" -eq 1 ]
then
	if [ -e /etc/debian_version ]
	then
		if ! (dpkg --print-foreign-architectures | grep -q i386)
		then
			info "Adding i386 architectures..."
			sudo dpkg --add-architecture i386 >>$OUTFILE 2>>$ERRFILE
			sudo apt-get update >>$OUTFILE 2>>$ERRFILE
		fi
		info "Installing dependencies..."
		sudo apt-get install -y $DEBS >>$OUTFILE 2>>$ERRFILE
	else
		error "We don't know which dependencies to install for this sytem.\nPlease install the equivalents of these debian packages: $DEBS."
	fi
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
	fi

	if lsvirtualenv | grep -q "^$ANGR_VENV$"
	then
		info "Virtualenv $ANGR_VENV already exists, reusing it. Use -E instead of -e if you want to re-create the environment."
	elif [ "$USE_PYPY" -eq 1 ]
	then
		info "Creating pypy virtualenv $ANGR_VENV..."
		./pypy_venv.sh $ANGR_VENV >>$OUTFILE 2>>$ERRFILE
	else
		info "Creating cpython virtualenv $ANGR_VENV..."
		mkvirtualenv --python=$(which python2) $ANGR_VENV >>$OUTFILE 2>>$ERRFILE
	fi

	set -e
	workon $ANGR_VENV || error "Unable to activate the virtual environment."

	# older versions of pip will fail to process the --find-links arg silently
	pip install -U pip
fi

function try_remote
{
	URL=$1
	debug "Trying to clone from $URL"
	rm -f $CLONE_LOG
	git clone $URL >> $CLONE_LOG 2>> $CLONE_LOG
	r=$?

	if grep -q -E "(ssh_exchange_identification: read: Connection reset by peer|ssh_exchange_identification: Connection closed by remote host)" $CLONE_LOG
	then
		warning "Too many concurrent connections to the server. Retrying after sleep."
		sleep $[$RANDOM % 5]
		try_remote $URL
		return $?
	else
		[ $r -eq 0 ] && rm -f $CLONE_LOG
		return $r
	fi
}

function clone_repo
{
	NAME=$1
	CLONE_LOG=/tmp/clone-$BASHPID
	if [ -e $NAME ]
	then
		info "Skipping $NAME -- already cloned. Use ./git_all.sh pull for update."
		return 0
	fi

	info "Cloning repo $NAME."
	for r in $REMOTES
	do
		URL="$r/$NAME"
		try_remote $URL && debug "Success - $NAME cloned!" && break
	done

	if [ ! -e $NAME ]
	then
		error "Failed to clone $NAME. Error was:"
		cat $CLONE_LOG
		rm -f $CLONE_LOG
		return 1
	fi

	return 0
}

function install_wheels
{
	#LATEST_Z3=$(ls -tr wheels/angr_only_z3_custom-*)
	#echo "Installing $LATEST_Z3..." >> $OUTFILE 2>> $ERRFILE
	#pip install $LATEST_Z3 >> $OUTFILE 2>> $ERRFILE

	LATEST_VEX=$(ls -tr wheels/vex-*)
	echo "Extracting $LATEST_VEX..." >> $OUTFILE 2>> $ERRFILE
	tar xvzf $LATEST_VEX >> $OUTFILE 2>> $ERRFILE
	touch vex/*/*.o vex/libvex.a

	#LATEST_QEMU=$(ls -tr wheels/shellphish_qemu-*)
	#echo "Installing $LATEST_QEMU" >> $OUTFILE 2>> $ERRFILE
	#pip install $LATEST_QEMU >> $OUTFILE 2>> $ERRFILE

	#LATEST_AFL=$(ls -tr wheels/shellphish_afl-*)
	#echo "Installing $LATEST_AFL" >> $OUTFILE 2>> $ERRFILE
	#pip install $LATEST_AFL >> $OUTFILE 2>> $ERRFILE
}

info "Cloning angr components!"
if [ $CONCURRENT_CLONE -eq 0 ]
then
	for r in $REPOS
	do
		clone_repo $r || exit 1
		[ -e "$NAME/setup.py" ] && TO_INSTALL="$TO_INSTALL $NAME"
	done
else
	declare -A CLONE_PROCS
	for r in $REPOS
	do
		clone_repo $r &
		CLONE_PROCS[$r]=$!
	done

	for r in $REPOS
	do
		#echo "WAITING FOR: $r (PID ${CLONE_PROCS[$r]})"
		if wait ${CLONE_PROCS[$r]}
		then
			#echo "... SUCCESS"
			[ -e "$NAME/setup.py" ] && TO_INSTALL="$TO_INSTALL $NAME"
		else
			#echo "... FAIL"
			exit 1
		fi
	done
fi

if [ -n "$BRANCH" ]
then
	info "Checking out branch $BRANCH."
	./git_all.sh checkout $BRANCH >> $OUTFILE 2>> $ERRFILE
fi

if [ $INSTALL -eq 1 ]
then
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

	if [ $VERBOSE -eq 1 ]
	then
		info "Installing python packages!"
	else
		info "Installing python packages (logging to $OUTFILE)!"
	fi

	if [ $WHEELS -eq 1 ]
	then
		install_wheels
		PIP_OPTIONS="$PIP_OPTIONS --find-links=$PWD/wheels"
	fi

	# remove angr-management if running in pypy or in travis
	#(python --version 2>&1| grep -q PyPy) && 
	info "NOTE: removing angr-management until we sort out the pyside packaging"
	TO_INSTALL=${TO_INSTALL// angr-management/}
	[ -n "$TRAVIS" ] && TO_INSTALL=${TO_INSTALL// angr-management/}

    for PACKAGE in $TO_INSTALL; do
        if pip install $PIP_OPTIONS -v -e $PACKAGE >> $OUTFILE 2>> $ERRFILE; then
            info "Installed $PACKAGE."
        else
            error "$PACKAGE failed to install. Check $OUTFILE for details, or read it here:"
            exit 1
        fi
    done

    [ $VERBOSE -eq 1 ] || rm -f $OUTFILE

	info "Installing some other helpful stuff (logging to $OUTFILE)."
	if pip install ipython pylint ipdb nose nose-timer coverage sphinx sphinx_rtd_theme recommonmark >> $OUTFILE 2>> $ERRFILE
	then
		info "Success!"
		[ $VERBOSE -eq 1 ] || rm -f $OUTFILE
	else
		error "Something failed to install. Check $OUTFILE for details, or read it here:"
		exit 1
	fi
fi

echo ''
info "All done! Execute \"workon $ANGR_VENV\" to use your new angr virtual"
info "environment. Any changes you make in the repositories will reflect"
info "immediately in the virtual environment, with the exception of things"
info "requiring compilation (i.e., pyvex). For those, you will need to rerun"
info "the install after changes (i.e., \"pip install -e pyvex\")."
