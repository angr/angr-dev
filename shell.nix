with import <nixpkgs> { };

let python_pkgs = py_pkgs: with py_pkgs; [
  pip
  setuptools
];
in
  stdenv.mkDerivation rec {
    name = "angr-env";

    nativeBuildInputs = [ cmake pkgconfig git ];

    buildInputs = [
      bash
      nasm
      (python3.withPackages python_pkgs)
      python2   # To build unicorn
      python3Packages.virtualenvwrapper
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
