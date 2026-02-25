# This shell script sets up a python virtual environment with all the necessary dependencies for angr to run.
# Its purpose is to generate an environment where you can DEVELOP angr, i.e. have all the code laid out in
# front of you and be able to edit it. For this end we do some very non-nix things to make it work, creating
# a python virtualenv in the current directory and shelling out to pip.
#
# This shell is meant to be run cloned from the angr-dev repository. You can then use the rest of the angr-dev
# niceties, such as git_all.sh

with import <nixpkgs> { };

stdenv.mkDerivation {
  name = "angr-env";

  nativeBuildInputs = [
    cmake
    pkg-config
    git
    #rustc
    #cargo
    rust_1_91.packages.stable.rustc
    rust_1_91.packages.stable.cargo
  ];

  buildInputs = [
    python312
    #python314FreeThreading
    #python314
    nasm
    libxml2
    libxslt
    libffi
    readline
    libtool
    glib
    debootstrap
    pixman
    openssl
    jdk8

    # pyside6 deps for binary patching
    # speechd
    # cups
    # gdk-pixbuf
    # cairo
    # at-spi2-atk
    # pango
    # gtk3
    # xcb-util-cursor
    # libpq
    # mysql80
    # unixODBC
    # pcsclite
    # libpulseaudio
    # alsa-lib
    # nspr
    # nss
    # xorg.libXrandr
    # xorg.libXdamage
    # xorg.libxkbfile
    # kdePackages.qtwayland
    # kdePackages.qt3d

    # needed for pure environments
    which
  ];

  # autoPatchelfIgnoreMissingDeps = [
  #   "libmimerapi.so"
  #   "libQt6EglFsKmsGbmSupport.so.6"
  # ];

  shellHook = ''
    #export LD_LIBRARY_PATH="${lib.makeLibraryPath [stdenv.cc.cc zstd glib libGL]}:$LD_LIBRARY_PATH"
    if ! [ -d ".venv" ]; then
      python -m venv .venv
      VIRTUAL_ENV="$(realpath .venv)"
      MY_NIX_LD="/${stdenv.hostPlatform.libDir}/${builtins.unsafeDiscardStringContext ( lib.last (lib.splitString "/" stdenv.cc.bintools.dynamicLinker) )}"
      SETUP_COMMAND=()
      if [[ -e "$NIX_LD" ]]; then
        mv "$VIRTUAL_ENV/bin/python" "$VIRTUAL_ENV/bin/.python-wrapped"
        echo "#!/bin/sh" >>"$VIRTUAL_ENV/bin/python"
        echo "exec \"$MY_NIX_LD\" --argv0 \"\$0\" \"$VIRTUAL_ENV/bin/.python-wrapped\" \"\$@\"" >>"$VIRTUAL_ENV/bin/python"
        chmod +x "$VIRTUAL_ENV/bin/python"
      else
        SETUP_COMMAND+=("NIX_ENFORCE_PURITY=")
      fi
      SETUP_COMMAND+=('./extremely-simple-setup.sh')
      echo '##'
      echo '##'
      echo '## Welcome!'" You may wish to run ''${SETUP_COMMAND[@]} in order to set up your new virtualenv."
      echo '##'
      echo '##'
    fi
    source .venv/bin/activate
  '';
}
