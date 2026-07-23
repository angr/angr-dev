{
    lib,
    stdenv,
    mkShell,
    python3Packages,
    rustc,
    cargo,
    zstd,
    cmake,
    pkg-config,
    git,
    libGL,
    nasm,
    libxml2,
    libxslt,
    libffi,
    readline,
    glib,
    pixman,
    openssl,
    jdk25,

    enableGui ? true,
    extraDeps ? [],
    extraNativeDeps ? [],
    extraVenvInstalls ? [ "ipython" "ipdb" "monkeyhex" ],
    venvName ? ".venv",
    rootMarker ? "shell.nix",
    extraEnv ? {},
    autoInstallEditables ? true,
    postShellHook ? "",
    postVenvCreation ? "",
}:
let
    commonSetup = ''
        # allow pip to install wheels
        unset SOURCE_DATE_EPOCH
        export LD_LIBRARY_PATH="${lib.makeLibraryPath [ stdenv.cc.cc zstd glib libGL ]}:$LD_LIBRARY_PATH"
    '';
in mkShell {
    name = "angr-dev";
    venvDir = "${venvName}";
    buildInputs = [
        python3Packages.python
        python3Packages.venvShellHook

        nasm
        libxml2
        libxslt
        libffi
        readline
        glib
        pixman
        openssl
        jdk25
    ] ++ lib.optionals enableGui [
        python3Packages.pyside6
        python3Packages.pyside6-qtads
    ] ++ extraDeps;

    nativeBuildInputs = [
        cmake
        pkg-config
        git
        rustc
        cargo
    ] ++ extraNativeDeps;

    preShellHook = lib.optionalString (rootMarker != null) ''
        ROOT="$(while true; do
          if [[ -d "$venvDir" || -f "${rootMarker}" ]]; then
            pwd
            break
          fi
          if [[ $(pwd) == "/" ]]; then
            break
          fi
          cd ..
        done)"
        if [[ -z "$ROOT" ]]; then
          ROOT="$PWD"
        fi
        venvDir="$ROOT/$venvDir"
    '';

    postVenvCreation = commonSetup + ''
        pip install ${lib.concatStringsSep " " extraVenvInstalls}

        echo "Welcome to your angr-dev environment."
        echo "You may wish to run ./extremely-simple-setup.sh to clone and install the angr repos."
    '' + postVenvCreation;

    postShellHook = commonSetup + lib.optionalString (autoInstallEditables && rootMarker != null) ''
        if [[ -x "$ROOT/nix/install-editables.sh" ]]; then
            "$ROOT/nix/install-editables.sh" "$ROOT"
        fi
    '' + postShellHook;

    env = extraEnv;
}
