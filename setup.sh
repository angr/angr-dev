#!/usr/bin/env bash
set -e

SCRIPT_DIR=$(dirname $0)
cd $SCRIPT_DIR

function usage
{
	echo "Usage: $0 [-i] [-e ENV] [-p ENV] [-r REMOTE] [EXTRA_REPOS]"
	echo
	echo "    -i		install required packages"
	echo "    -C		don't do the actual installation (quit after cloning)"
	echo "    -c		clone repositories concurrently in the background"
	echo "    -s            Use shallow clones (pull just the latest commit from each branch)."
	echo "    -e ENV	create or reuse a cpython environment ENV"
	echo "    -E ENV	re-create a cpython environment ENV"
	echo "    -p ENV	create or reuse a pypy environment ENV"
	echo "    -P ENV	re-create a pypy environment ENV"
	echo "    -r REMOTE	use a different remote base (default: https://github.com/)"
	echo "             	Can be specified multiple times."
	echo "    -b BRANCH     Check out a given branch across all the repositories."
	echo "    -D            Ignore the default repo list."
	echo "    -u 		Unattended, skip all prompts."
	echo "    EXTRA_REPOS	any extra repositories you want to clone from the angr org."
	echo
	echo "This script clones all the angr repositories and sets up an angr"
	echo "development environment."

	exit 1
}

# We must do this check before the `declare`, because MacOS ships with bash version 3
[ "$(uname)" == "Darwin" ] && IS_MACOS=1 || IS_MACOS=0

if ((BASH_VERSINFO[0] < 4));
then
	echo "This script requires bash version >= 4.0, and you have bash verison $BASH_VERSION." >&2
	if [ $IS_MACOS -eq 1 ];
	then
		echo -e "To install a newer bash version, use homebrew https://brew.sh/:\nbrew install bash\nYou don't need to link it or change the shell, it just needs to be installed." >&2
	else
		echo "Install a bash version >= 4.0 using your favorite package manager." >&2
	fi
	exit 1;
fi


DEBS=${DEBS-python3-pip python3-dev python3-setuptools build-essential libxml2-dev libxslt1-dev git libffi-dev cmake libreadline-dev libtool debootstrap debian-archive-keyring libglib2.0-dev libpixman-1-dev qtdeclarative5-dev binutils-multiarch nasm libssl-dev}
HOMEBREW_DEBS=${HOMEBREW_DEBS-python3 libxml2 libxslt libffi cmake libtool glib binutils nasm patchelf}
ARCHDEBS=${ARCHDEBS-python-pip libxml2 libxslt git libffi cmake readline libtool debootstrap glib2 pixman qt5-base binutils nasm}
ARCHCOMDEBS=${ARCHCOMDEBS}
RPMS=${RPMS-gcc gcc-c++ make python3-pip python3-devel python3-setuptools libxml2-devel libxslt-devel git libffi-devel cmake readline-devel libtool debootstrap debian-keyring glib2-devel pixman-devel qt5-qtdeclarative-devel binutils-x86_64-linux-gnu nasm openssl-devel}
OPENSUSE_RPMS=${OPENSUSE_RPMS-gcc gcc-c++ make python3-pip python3-devel python3-setuptools libxml2-devel libxslt-devel git libffi-devel cmake readline-devel libtool debootstrap glib2-devel libpixman-1-0-devel libQt5Core5 libqt5-qtdeclarative-devel binutils nasm libopenssl-devel}
REPOS=${REPOS-archinfo pyvex cle claripy ailment angr angr-doc binaries}
REPOS_CPYTHON=${REPOS_CPYTHON-angr-management}
# archr is Linux only because of shellphish-qemu dependency
if [ `uname` == "Linux" ]; then REPOS="${REPOS} archr"; fi
declare -A EXTRA_DEPS
EXTRA_DEPS["angr"]="sqlalchemy unicorn==2.0.1.post1"
EXTRA_DEPS["pyvex"]="--pre capstone"

ORIGIN_REMOTE=${ORIGIN_REMOTE-$(git remote -v | grep origin | head -n1 | awk '{print $2}' | sed -e "s|[^/:]*/angr-dev.*||")}
REMOTES=${REMOTES-${ORIGIN_REMOTE}angr ${ORIGIN_REMOTE}shellphish ${ORIGIN_REMOTE}mechaphish https://git:@github.com/zardus https://git:@github.com/rhelmot https://git:@github.com/salls https://git:@github.com/lukas-dresel https://git:@github.com/mborgerson}


INSTALL_REQS=0
ANGR_VENV=
USE_PYPY=
RMVENV=0
INSTALL=1
CONCURRENT_CLONE=0
BRANCH=
UNATTENDED=0


while getopts "iCcwDvsue:E:p:P:r:b:h" opt
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
		D)
			REPOS=""
			;;
		s)
			GIT_OPTIONS="$GIT_OPTIONS --depth 1 --no-single-branch"
			;;
		u)
			UNATTENDED=1
			;;
		\?)
			usage
			;;
		h)
			usage
			;;
	esac
done

# Hacky way to prevent http username/password prompts (ssh should not be affected)
export GIT_ASKPASS=true

EXTRA_REPOS=${@:$OPTIND:$OPTIND+100}
REPOS="$REPOS $EXTRA_REPOS"

function debug
{
	echo -e "$(tput setaf 6 2>/dev/null)[-] $(date +%H:%M:%S) $@$(tput sgr0 2>/dev/null)"
}

function info
{
	echo -e "$(tput setaf 4 2>/dev/null)[+] $(date +%H:%M:%S) $@$(tput sgr0 2>/dev/null)"
}

function warning
{
	echo -e "$(tput setaf 3 2>/dev/null)[!] $(date +%H:%M:%S) $@$(tput sgr0 2>/dev/null)"
}

function error
{
	echo -e "$(tput setaf 1 2>/dev/null)[!!] $(date +%H:%M:%S) $@$(tput sgr0 2>/dev/null)"
	exit 1
}

if [ "$INSTALL_REQS" -eq 1 ]
then
	if [ $EUID -eq 0 ]
	then
		export SUDO=
	else
		export SUDO=sudo
	fi
	if [ -e /etc/debian_version ]
	then
		if ! (dpkg --print-foreign-architectures | grep -q i386)
		then
			info "Adding i386 architectures..."
			$SUDO dpkg --add-architecture i386
			$SUDO apt-get update
		fi
		info "Installing dependencies..."
		$SUDO apt-get install -y $DEBS
	elif [ -e /etc/pacman.conf ]
	then
		if ! grep --quiet "^\[multilib\]" /etc/pacman.conf;
		then
			info "Adding i386 architectures..."
			$SUDO sed 's/^\(#\[multilib\]\)/\[multilib\]/' </etc/pacman.conf >/tmp/pacman.conf
			$SUDO sed '/^\[multilib\]/{n;s/^#//}' </tmp/pacman.conf >/etc/pacman.conf
			$SUDO pacman -Syu
		fi
		info "Installing dependencies..."
		$SUDO pacman -S --noconfirm --needed $ARCHDEBS
	elif [ -e /etc/fedora-release ]
	then
		info "Installing dependencies..."
		$SUDO dnf install -y $RPMS
	elif [ -e /etc/zypp ]
	then
		info "Installing dependencies..."
		$SUDO zypper install -y $OPENSUSE_RPMS
	elif [ $IS_MACOS -eq 1 ]
	then
		if ! which brew > /dev/null;
		then
			error "Your system doesn't have homebrew installed, I don't know how to install the dependencies.\nPlease install homebrew: https://brew.sh/\nOr install the equivalent of these homebrew packages: $HOMEBREW_DEBS."
		fi
		brew install $HOMEBREW_DEBS
	elif [ -e /etc/NIXOS ]
	then
		info "Doing nothing about dependencies installation for NixOS, as they are provided via shell.nix..."
	else
		error "We don't know which dependencies to install for this sytem.\nPlease install the equivalents of these debian packages: $DEBS."
	fi
fi

info "Checking dependencies..."
if [ -e /etc/debian_version ]
then
	INSTALLED_DEBS=$(dpkg --get-selections $DEBS 2>/dev/null)
	MISSING_DEBS=""
	for REQ in $DEBS; do
		if ! grep "$REQ" <<<$INSTALLED_DEBS >/dev/null 2>/dev/null; then
			MISSING_DEBS="$REQ $MISSING_DEBS"
		fi
	done
	[ -n "$MISSING_DEBS" ] && error "Please install the following packages: $MISSING_DEBS"
elif [ -e /etc/pacman.conf ]
then
	[ $(pacman -Qi $ARCHDEBS  2>&1 | grep "was not found" | wc -l) -ne 0 ] && error "Please install the following packages: $ARCHDEBS"
	[ $(pacman -Qi $ARCHCOMDEBS  2>&1 | grep "was not found" | wc -l) -ne 0 ] && error "Please install the following packages from AUR (yaourt -S <package_name>)): $ARCHCOMDEBS"
elif [ -e /etc/fedora-release ]
then
	[ $(rpm -q $RPMS  2>&1 | grep "is not installed" | wc -l) -ne 0 ] && error "Please install the following packages: $RPMS"
elif [ -e /etc/zypp ]
then
	[ $(rpm -q $OPENSUSE_RPMS 2>&1 | grep "is not installed" | wc -l) -ne 0 ] && error "Please install the following packages: $OPENSUSE_RPMS"
elif [ -e /etc/NIXOS ]
then
	[ -z "$IN_NIX_SHELL" ] && error "Please run in the provided shell.nix"
elif [ $IS_MACOS -eq 1 ]
then
	[ $(brew ls --versions $HOMEBREW_DEBS | wc -l) -ne $(echo $HOMEBREW_DEBS | wc -w) ] && error "Please install the following packages from homebrew: $HOMEBREW_DEBS"
else
	warning "WARNING: make sure you have dependencies installed.\nThe debian equivalents are: $DEBS."
fi

if [ -n "$ANGR_VENV" ]
then
	info "Enabling virtualenvwrapper."
	# The idea here is to attpempt to use a preinstalled version of
	# virtualenvwrapper. If we can't we'll install it using pip3. This should
	# minimize issues where there are conflicting distro and pip versions.
	virtualenvwrapper_locations=( \
		$(command -v virtualenvwrapper.sh || true) \
		~/.local/bin/virtualenvwrapper.sh \
		/usr/share/virtualenvwrapper/virtualenvwrapper.sh \
		/etc/bash_completion.d/virtualenvwrapper \
	)
	export VIRTUALENVWRAPPER_PYTHON=$(which python3)
	for f in ${virtualenvwrapper_locations[@]}; do
		if [ -e $f ]; then
			set +e
			source $f
			set -e
			venvwrapper_loc=$f
			break
		fi
	done
	if ! command -v workon &> /dev/null; then
		info "Could not find virtualenvwrapper preinstalled, installing via pip3..."
		pip3 install --user virtualenvwrapper
		set +e
		source ~/.local/bin/virtualenvwrapper.sh
		set -e
		venvwrapper_loc=~/.local/bin/virtualenvwrapper.sh
	fi
	if [[ $venvwrapper_loc == "~/.local/bin/virtualenvwrapper.sh" && ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
		info "\$HOME/.local/bin is not in your path, adding temporarily."
		info "To make this permanent, add $HOME/.local/bin to your \$PATH"
		export PATH=$HOME/.local/bin:$PATH
	fi

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
		./pypy_venv.sh $ANGR_VENV
	else
		info "Creating cpython virtualenv $ANGR_VENV..."
		mkvirtualenv --python=$(which python3) $ANGR_VENV
	fi

	set -e
	workon $ANGR_VENV || error "Unable to activate the virtual environment."

	# older versions of pip will fail to process the --find-links arg silently
	# setuptools<64.0.1 is needed for editable installs for now, see angr/angr#3487
	pip3 install -U 'pip>=20.0.2'
fi

# Must happen after virutalenv is enabled to correctly detect python implementation
implementation=$(python -c "import sys; print(sys.implementation.name)")
if [ "$implementation" == "cpython" ]; then REPOS="${REPOS} $REPOS_CPYTHON"; fi

# Install build dependencies until build isolation can be enabled
pip install -U pip "setuptools==64.0.1" wheel cffi unicorn==2.0.1.post1 cmake ninja

function try_remote
{
	URL=$1
	debug "Trying to clone from $URL"
	rm -f $CLONE_LOG
	git clone --recursive $GIT_OPTIONS $URL >> $CLONE_LOG 2>> $CLONE_LOG
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
		set +e
		error "Failed to clone $NAME. Error was:"
		set -e
		cat $CLONE_LOG
		rm -f $CLONE_LOG
		return 1
	fi

	return 0
}

function pip_install
{
        debug "pip-installing: $@."
        if ! pip3 install $PIP_OPTIONS $@
        then
            	error "pip failure ($@)."
        fi
}

info "Cloning angr components!"
if [ $CONCURRENT_CLONE -eq 0 ]
then
	for r in $REPOS
	do
		clone_repo $r || exit 1
		[ -e "$NAME/setup.py" -o -e "$NAME/pyproject.toml" ] && TO_INSTALL="$TO_INSTALL $NAME"
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
		if wait ${CLONE_PROCS[$r]}
		then
			[ -e "$r/setup.py" -o -e "$r/pyproject.toml" ] && TO_INSTALL="$TO_INSTALL $r"
		else
			exit 1
		fi
	done
fi

if [ -n "$BRANCH" ]
then
	info "Checking out branch $BRANCH."
	./git_all.sh checkout $BRANCH
fi

if [ $INSTALL -eq 1 ]
then
	if [ -z "$VIRTUAL_ENV" ] && [ -z "$CONDA_DEFAULT_ENV" ] && [ $UNATTENDED != 1 ]
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

	info "Installing python packages!"

	# the angr environment on macos hides the python2 from us, so we'll used the installed version in /usr/bin/python
	if [ $IS_MACOS -eq 1 ]
	then
		python2=/usr/bin/python
	else
		python2=$(which python2 || echo)
	fi
	if [ ! -z "$python2" ]
	then
		export UNICORN_QEMU_FLAGS="--python=$python2 $UNICORN_QEMU_FLAGS"
	fi

	# capstone and/or unicorn need this environment variables for MacOS
	# https://github.com/trailofbits/manticore/issues/110#issuecomment-438262142
	if [ $IS_MACOS -eq 1 ]
	then
		export MACOS_UNIVERSAL=no
	fi

	info "Install list: $TO_INSTALL"
	for PACKAGE in $TO_INSTALL; do
		info "Installing $PACKAGE."
		[ -n "${EXTRA_DEPS[$PACKAGE]}" ] && pip_install ${EXTRA_DEPS[$PACKAGE]}
		pip_install --no-build-isolation -e $PACKAGE
	done

	info "Installing some other helpful stuff"
	# we need the pyelftools from upstream
	pip3 install -U ipython pylint ipdb nose nose-timer coverage flaky keystone-engine 'git+https://github.com/eliben/pyelftools#egg=pyelftools'

	echo ''
	info "All done! Execute \"workon $ANGR_VENV\" to use your new angr virtual"
	info "environment. Any changes you make in the repositories will reflect"
	info "immediately in the virtual environment, with the exception of things"
	info "requiring compilation (i.e., pyvex). For those, you will need to rerun"
	info "the install after changes (i.e., \"pip install -e pyvex\")."
	if [ $IS_MACOS -eq 1 ]
	then
		info "You'll need to setup your virtualenv correctly on MacOS."
		info "Here's what I use:"
		info "\`export VIRTUALENVWRAPPER_PYTHON=$(which python3); source /usr/local/bin/virtualenvwrapper.sh\`"
	fi
fi
