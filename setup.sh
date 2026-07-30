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

QT_DEBS="libgl1 libegl1 libx11-xcb1 libxkbcommon-x11-0 libxcb-cursor0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 libxcb-shape0 libxcb-sync1 libxcb-util1 libxcb-xfixes0 libxcb-xkb1 libdbus-1-3 libfontconfig1"
QT_ARCHDEBS="libglvnd libx11 libxcb xcb-util-cursor xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-wm libxkbcommon-x11 dbus fontconfig"
QT_RPMS="mesa-libGL mesa-libEGL libX11-xcb libxcb xcb-util-cursor xcb-util-image xcb-util-keysyms xcb-util-renderutil xcb-util-wm libxkbcommon-x11 dbus-libs fontconfig"
QT_OPENSUSE_RPMS="Mesa-libGL1 Mesa-libEGL1 libX11-xcb1 libxcb1 libxcb-cursor0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 libxcb-shape0 libxcb-sync1 libxcb-util1 libxcb-xfixes0 libxcb-xkb1 libxkbcommon-x11-0 dbus-1 fontconfig"

DEBS=${DEBS-python3-pip python3-dev python3-venv build-essential libxml2-dev libxslt1-dev git libffi-dev cmake libreadline-dev libtool debootstrap debian-archive-keyring libglib2.0-dev libpixman-1-dev binutils-multiarch nasm libssl-dev $QT_DEBS}
HOMEBREW_DEBS=${HOMEBREW_DEBS-python3 libxml2 libxslt libffi cmake libtool glib binutils nasm patchelf}
ARCHDEBS=${ARCHDEBS-python-pip libxml2 libxslt git libffi cmake readline libtool debootstrap glib2 pixman binutils nasm $QT_ARCHDEBS}
ARCHCOMDEBS=${ARCHCOMDEBS}
RPMS=${RPMS-gcc gcc-c++ make python3-pip python3-devel libxml2-devel libxslt-devel git libffi-devel cmake readline-devel libtool debootstrap debian-keyring glib2-devel pixman-devel binutils-x86_64-linux-gnu nasm openssl-devel $QT_RPMS}
OPENSUSE_RPMS=${OPENSUSE_RPMS-gcc gcc-c++ make python3-pip python3-devel libxml2-devel libxslt-devel git libffi-devel cmake readline-devel libtool debootstrap glib2-devel libpixman-1-0-devel binutils nasm libopenssl-devel $QT_OPENSUSE_RPMS}

# virtualenvwrapper is only needed for -e/-E/-p/-P, so it is not part of the
# lists above. It is installed from the distro's package manager because the
# system pythons of most modern distros are externally managed (PEP 668) and
# refuse to be pip-installed into.
VENVWRAPPER_DEB=${VENVWRAPPER_DEB-virtualenvwrapper}
VENVWRAPPER_RPM=${VENVWRAPPER_RPM-python3-virtualenvwrapper}
VENVWRAPPER_BREW=${VENVWRAPPER_BREW-virtualenvwrapper}
# Where a private copy of virtualenvwrapper goes if the distro has none
VENVWRAPPER_HOME=${VENVWRAPPER_HOME-${XDG_DATA_HOME-$HOME/.local/share}/angr-dev/virtualenvwrapper}

# angr requires this python, and its native extension requires this rust (edition 2024)
MIN_PYTHON_VERSION=${MIN_PYTHON_VERSION-3.12}
MIN_RUST_VERSION=${MIN_RUST_VERSION-1.85}

REPOS=${REPOS-angr-data archinfo pyvex cle claripy angr angr-management binaries}
REPOS_CPYTHON=${REPOS_CPYTHON-angr-management}
# archr is Linux only because of shellphish-qemu dependency
if [ `uname` == "Linux" ]; then REPOS="${REPOS} archr"; fi
declare -A EXTRA_DEPS
EXTRA_DEPS["angr"]="sqlalchemy unicorn==2.1.4"
# angr's build imports the pyvex installed in this environment, so it is the one
# package that cannot be built in an isolated environment.
declare -A PIP_EXTRA_OPTIONS
PIP_EXTRA_OPTIONS["angr"]="--no-build-isolation"

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

# Is version $1 at least version $2? Trailing junk (1.90.0-nightly) is ignored.
function version_ge
{
	local IFS=.
	local -a have=($1) want=($2)
	local i x y
	for ((i = 0; i < ${#want[@]}; i++))
	do
		x=${have[i]:-0}; x=${x%%[!0-9]*}
		y=${want[i]:-0}; y=${y%%[!0-9]*}
		if [ ${x:-0} -gt ${y:-0} ]; then return 0; fi
		if [ ${x:-0} -lt ${y:-0} ]; then return 1; fi
	done
	return 0
}

function check_python_version
{
	local python=$1
	local version
	version=$("$python" -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>/dev/null) || error "Cannot run $python."
	version_ge "$version" "$MIN_PYTHON_VERSION" || error "angr requires python >= $MIN_PYTHON_VERSION, but $python is $version.\nInstall a newer python and make sure it comes first in your \$PATH."
}

# Print an interpreter that can import the virtualenvwrapper module backing the
# virtualenvwrapper.sh at $1, if there is one. The script and the module come
# from the same installation, which is frequently not the python3 in $PATH:
# distro packages install into the system python, homebrew into its own libexec.
function find_venvwrapper_python
{
	local script_dir=$(dirname "$1")
	local python
	for python in "$VIRTUALENVWRAPPER_PYTHON" "$script_dir/python3" "$script_dir/../libexec/bin/python3" /usr/bin/python3 "$(command -v python3)"
	do
		if [ -x "$python" ] && "$python" -c "import virtualenvwrapper.hook_loader" >/dev/null 2>&1
		then
			echo "$python"
			return 0
		fi
	done
	return 1
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
		if [ -n "$ANGR_VENV" ]
		then
			info "Installing virtualenvwrapper..."
			$SUDO apt-get install -y $VENVWRAPPER_DEB || warning "Could not install $VENVWRAPPER_DEB. A private copy will be used instead."
		fi
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
		if [ -n "$ANGR_VENV" ]
		then
			info "Installing virtualenvwrapper..."
			$SUDO dnf install -y $VENVWRAPPER_RPM || warning "Could not install $VENVWRAPPER_RPM. A private copy will be used instead."
		fi
	elif [ -e /etc/zypp ]
	then
		info "Installing dependencies..."
		$SUDO zypper install -y $OPENSUSE_RPMS
		if [ -n "$ANGR_VENV" ]
		then
			info "Installing virtualenvwrapper..."
			$SUDO zypper install -y $VENVWRAPPER_RPM || warning "Could not install $VENVWRAPPER_RPM. A private copy will be used instead."
		fi
	elif [ $IS_MACOS -eq 1 ]
	then
		if ! which brew > /dev/null;
		then
			error "Your system doesn't have homebrew installed, I don't know how to install the dependencies.\nPlease install homebrew: https://brew.sh/\nOr install the equivalent of these homebrew packages: $HOMEBREW_DEBS."
		fi
		brew install $HOMEBREW_DEBS
		if [ -n "$ANGR_VENV" ]
		then
			info "Installing virtualenvwrapper..."
			brew install $VENVWRAPPER_BREW || warning "Could not install $VENVWRAPPER_BREW. A private copy will be used instead."
		fi
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

# angr's native extension is compiled by cargo. Distro rust packages are usually
# too old for it, so this is not part of the package lists above.
if [ $INSTALL -eq 1 ] && [[ " $REPOS " == *" angr "* ]]
then
	command -v cargo >/dev/null || error "angr requires rust >= $MIN_RUST_VERSION to build its native extension, but cargo was not found.\nInstall a toolchain from https://rustup.rs/ (distro rust packages are often too old)."
	RUST_VERSION=$(cargo --version | awk '{print $2}')
	version_ge "$RUST_VERSION" "$MIN_RUST_VERSION" || error "angr requires rust >= $MIN_RUST_VERSION to build its native extension, but cargo is $RUST_VERSION.\nUpdate your toolchain, e.g. with \`rustup update stable\`."
fi

if [ -n "$ANGR_VENV" ]
then
	if [ -n "$VIRTUAL_ENV" ]
	then
		# We can't just deactivate, since those functions are in the parent shell.
		# So, we do some hackish stuff.
		PATH=${PATH/$VIRTUAL_ENV\/bin:/}
		unset VIRTUAL_ENV
	fi

	# The python the new virtualenv will be built on, as opposed to the python
	# running virtualenvwrapper itself -- they are not necessarily the same one.
	VENV_PYTHON=$(command -v python3) || error "No python3 found in your \$PATH."
	check_python_version "$VENV_PYTHON"

	info "Enabling virtualenvwrapper."
	# Use a preinstalled (usually distro-provided) virtualenvwrapper if there is
	# one, to minimize issues where there are conflicting distro and pip
	# versions. Otherwise install one into a private virtualenv: `pip install
	# --user` is rejected on distros whose python is externally managed.
	virtualenvwrapper_locations=( \
		$(command -v virtualenvwrapper.sh || true) \
		~/.local/bin/virtualenvwrapper.sh \
		/usr/share/virtualenvwrapper/virtualenvwrapper.sh \
		/usr/local/bin/virtualenvwrapper.sh \
		/etc/bash_completion.d/virtualenvwrapper \
	)
	venvwrapper_loc=
	for f in ${virtualenvwrapper_locations[@]}; do
		[ -e "$f" ] || continue
		if venvwrapper_python=$(find_venvwrapper_python "$f"); then
			venvwrapper_loc=$f
			export VIRTUALENVWRAPPER_PYTHON=$venvwrapper_python
			break
		fi
		warning "$f exists, but no python here can import virtualenvwrapper. Ignoring it."
	done

	if [ -z "$venvwrapper_loc" ]; then
		info "Could not find virtualenvwrapper preinstalled, installing a private copy in $VENVWRAPPER_HOME..."
		info "Install your distro's virtualenvwrapper package (or rerun with -i) to use a system-wide one instead."
		if [ ! -x "$VENVWRAPPER_HOME/bin/python" ]; then
			"$VENV_PYTHON" -m venv "$VENVWRAPPER_HOME" || error "Failed to create $VENVWRAPPER_HOME.\nOn debian-based systems, this needs the python3-venv package."
		fi
		"$VENVWRAPPER_HOME/bin/pip" install -qU pip virtualenvwrapper || error "Failed to install virtualenvwrapper."
		venvwrapper_loc="$VENVWRAPPER_HOME/bin/virtualenvwrapper.sh"
		export VIRTUALENVWRAPPER_PYTHON="$VENVWRAPPER_HOME/bin/python"
		export VIRTUALENVWRAPPER_VIRTUALENV="$VENVWRAPPER_HOME/bin/virtualenv"
	fi

	set +e
	source "$venvwrapper_loc"
	set -e
	command -v mkvirtualenv >/dev/null || error "Failed to enable virtualenvwrapper from $venvwrapper_loc."

	if [[ $venvwrapper_loc == "$HOME/.local/bin/virtualenvwrapper.sh" && ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
		info "\$HOME/.local/bin is not in your path, adding temporarily."
		info "To make this permanent, add $HOME/.local/bin to your \$PATH"
		export PATH=$HOME/.local/bin:$PATH
	fi

	set +e
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
		mkvirtualenv --python="$VENV_PYTHON" $ANGR_VENV
	fi

	set -e
	workon $ANGR_VENV || error "Unable to activate the virtual environment."

	# older versions of pip will fail to process the --find-links arg silently
	pip3 install -U 'pip>=20.0.2'
fi

# Must happen after virutalenv is enabled: this is the python angr gets installed into
PYTHON=$(command -v python || command -v python3) || error "No python found in your \$PATH."
check_python_version "$PYTHON"
implementation=$("$PYTHON" -c "import sys; print(sys.implementation.name)")
if [ "$implementation" == "cpython" ]; then REPOS="${REPOS} $REPOS_CPYTHON"; fi

# Everything but angr is built in an isolated environment, so only the tools used
# to drive the installs themselves are needed here. angr's own build dependencies
# are installed further down, straight out of its pyproject.toml.
pip install -U pip "setuptools>=77.0.0" wheel

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

	# angr is installed without build isolation, so its build dependencies (right
	# now: setuptools-rust, grpcio-tools and protobuf, which generate its native
	# extension and its protobuf modules) have to be in the environment already.
	# They are read out of angr's pyproject.toml rather than duplicated here, so
	# that adding one upstream does not break this script. The angr repos among
	# them are skipped: they are installed from these checkouts below, and their
	# development versions do not exist on PyPI.
	if [ -e angr/pyproject.toml ]
	then
		info "Installing angr's build dependencies."
		ANGR_BUILD_DEPS=$("$PYTHON" -c "
import re, tomllib
with open('angr/pyproject.toml', 'rb') as f:
    requirements = tomllib.load(f)['build-system']['requires']
local = set('''$REPOS'''.split())
print(' '.join(r for r in requirements if re.split('[^A-Za-z0-9._-]', r.strip())[0] not in local))
") || error "Could not read angr's build dependencies from angr/pyproject.toml."
		pip_install $ANGR_BUILD_DEPS
	fi

	info "Install list: $TO_INSTALL"
	for PACKAGE in $TO_INSTALL; do
		info "Installing $PACKAGE."
		[ -n "${EXTRA_DEPS[$PACKAGE]}" ] && pip_install ${EXTRA_DEPS[$PACKAGE]}
		pip_install ${PIP_EXTRA_OPTIONS[$PACKAGE]} -e $PACKAGE
	done

	info "Installing some other helpful stuff"
	pip3 install -U ipython pylint ipdb pytest pytest-xdist coverage flaky keystone-engine \
		|| warning "Failed to install some of the optional development packages. The angr environment itself is fine."

	echo ''
	if [ -n "$ANGR_VENV" ]
	then
		info "All done! Execute \"workon $ANGR_VENV\" to use your new angr virtual"
		info "environment. Any changes you make in the repositories will reflect"
	else
		info "All done! Any changes you make in the repositories will reflect"
	fi
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
