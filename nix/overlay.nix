{
  angr ? pkgs: ../angr,
  pyvex ? pkgs: ../pyvex,
  cle ? pkgs: ../cle,
  archinfo ? pkgs: ../archinfo,
  angr-data ? pkgs: ../angr-data,
}:
final: prev:
let
  lib = prev.lib;
  tamal = import ./tamal { };
  pyproject-nix = import tamal.pyproject-nix { inherit lib; };
in {
    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (final': prev': let
          angrRepo = srcSpec: attrs: let
            path = srcSpec final;
            project = pyproject-nix.lib.project.loadPyproject { projectRoot = path; };
            devVersion = builtins.elemAt (builtins.match ".*__version__ = \"([^\"]*)\".*" (builtins.readFile "${path}/${attrs.pname or project.pyproject.project.name}/__init__.py")) 0;
            commit = lib.sources.commitIdFromGitRepo "${path}/.git";
            commitShort = lib.strings.substring 0 10 commit;
            pyprojectAttrs = project.renderers.buildPythonPackage {
              inherit (final') python;
            };
            extraAttrs = {
              name = "${project.pyproject.project.name}-${devVersion}+${commitShort}";
              version = devVersion;
              postUnpack = ''
                ${lib.getExe final.git} -C $sourceRoot clean -Xdf
              '';
            };
          in final'.buildPythonPackage (pyprojectAttrs // extraAttrs // attrs);
        in {
            angr = ((angrRepo angr {
              pythonRelaxDeps = [
                "capstone"
                "lmdb"
                "angr-data"
                "grpcio-tools"
              ];
              nativeBuildInputs = [
                final.rustPlatform.cargoSetupHook
                final.cargo
                final.rustc
              ];
            }).overridePythonAttrs (prev: {
              build-system = with final'; [
                protobuf6
                grpcio-tools-180
                setuptools
                setuptools-rust
              ];
            })).overrideAttrs (prev: {
              cargoDeps = final.rustPlatform.importCargoLock {
                lockFile = "${prev.src}/Cargo.lock";
                outputHashes = {
                  # well this is a nightmare
                  "icicle-cpu-0.1.0" = "sha256-p2tO1nFOA+RQ3XYyOuYvFrxz7DRebGChswxFdBkUApk=";
                };
              };
              pypaBuildFlags = (prev.pypaBuildFlags or []) ++ [ "--skip-dependency-check" ];
              dontCheckRuntimeDeps = true;
            });
            pyvex = angrRepo pyvex {
              build-system = with final'; [
                setuptools
                scikit-build-core
              ];

              nativeBuildInputs = with final; [
                cmake
                ninja
              ];

              dontUseCmakeConfigure = true;
            };
            cle = angrRepo cle {
              pythonRelaxDeps = [ "arpy" ];
            };
            archinfo = angrRepo archinfo {};
            angr-data  = angrRepo angr-data {
              pname = "angr_data";
            };
            pyxdia = final'.callPackage ./pyxdia.nix { };
            rust-demangler = final'.callPackage ./rust-demangler.nix { };
            pypcode = prev'.pypcode.overrideAttrs {
              version = "4.0.1";
              src = final.fetchFromGitHub {
                owner = "angr";
                repo = "pypcode";
                tag = "v4.0.1";
                hash = "sha256-qQgOtz8TRbP6LkGehSJM8ig6TsmwTz7gy8aA4dozwoc=";
              };
            };
            grpcio-tools-180 = prev'.grpcio-tools.overrideAttrs {
              version = "1.80.0";
              src = final.fetchPypi {
                pname = "grpcio_tools";
                version = "1.80.0";
                hash = "sha256-JgUrGcbODc9S0QJElq6j4r36hkFZ8G3HuXsi0EGpSyY=";
              };
            };
            pydemumble = prev'.pydemumble.overrideAttrs {
              version = "0.1.3";
              src = final.fetchFromGitHub {
                owner = "angr";
                repo = "pydemumble";
                tag = "v0.1.3";
                hash = "sha256-Po19NXY4I97Aj1SY1KqpspEqYpVGIsAirOo6iAjBrbk=";
                fetchSubmodules = true;
              };
            };
            cxxheaderparser = prev'.cxxheaderparser.overrideAttrs {
              version = "2.0.1";
              src = final.fetchFromGitHub {
                owner = "robotpy";
                repo = "cxxheaderparser";
                tag = "2.0.1";
                hash = "sha256-YF7ImKD+QsGb6IxntySHSYQafrDJw9fFD5TwShs5Q18=";
              };
            };
        })
    ];
}
