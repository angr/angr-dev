with import <nixpkgs> { };

stdenv.mkDerivation rec {
  name = "angr-env";

  nativeBuildInputs = [ cmake pkgconfig git ];

  buildInputs = [
    python3Packages.virtualenvwrapper
    python2   # To build unicorn
    python3   # For CPython install
    pypy3     # for PyPy install
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
  '';
}
