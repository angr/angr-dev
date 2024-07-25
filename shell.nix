with import <nixpkgs> { };

stdenv.mkDerivation rec {
  name = "angr-env";

  nativeBuildInputs = [ cmake pkg-config git ];

  buildInputs = [
    python3
    python3Packages.pip
    python3Packages.virtualenvwrapper
    nasm
    libxml2
    libxslt
    libffi
    readline
    libtool
    glib
    debootstrap
    pixman
    qt5.qtdeclarative
    openssl
    jdk8

    # needed for pure environments
    which
  ];

  shellHook = ''
    source $(command -v virtualenvwrapper.sh)
    export LD_LIBRARY_PATH="${lib.getLib stdenv.cc.cc}/lib:$LD_LIBRARY_PATH"
    workon angr 2>/dev/null || { mkvirtualenv angr && NIX_ENFORCE_PURITY= ./extremely-simple-setup.sh; }
  '';
}
