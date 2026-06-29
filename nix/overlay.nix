{
  angr ? pkgs: ../angr,
  pyvex ? pkgs: ../pyvex,
  claripy ? pkgs: ../claripy,
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
              version = "${devVersion}-${commitShort}";
            };
          in final'.buildPythonPackage (pyprojectAttrs // extraAttrs // attrs);
        in {
            angr = (angrRepo angr {
              pythonRelaxDeps = [ "capstone" "lmdb" "angr-data" ];
              nativeBuildInputs = [
                final.rustPlatform.cargoSetupHook
                final.cargo
                final.rustc
              ];
            }).overrideAttrs (prev: {
              cargoDeps = final.rustPlatform.importCargoLock {
                lockFile = "${prev.src}/Cargo.lock";
                outputHashes = {
                  # well this is a nightmare
                  "icicle-cpu-0.1.0" = "sha256-dF4ic0r+Z4WXqVIkKpxYfLiBg+i6Ohxy6rAgikJMZew=";
                };
              };
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
            claripy = angrRepo claripy {
              # z3 does not provide a dist-info, so python-runtime-deps-check will fail
              pythonRemoveDeps = [ "z3-solver" ];
            };
            cle = angrRepo cle {
              pythonRelaxDeps = [ "arpy" ];
            };
            archinfo = angrRepo archinfo {};
            angr-data  = angrRepo angr-data {
              pname = "angr_data";
            };
            pyxdia = final'.callPackage ./pyxdia.nix { };
            uefi-firmware = final'.uefi-firmware-parser;
            rust-demangler = final'.callPackage ./rust-demangler.nix { };
            scikit-build-core = prev'.scikit-build-core.overrideAttrs {
              version = "0.12.2";
              src = final.fetchFromGitHub {
                owner = "scikit-build";
                repo = "scikit-build-core";
                rev = "v0.12.2";
                hash = "sha256-JE6z44u1FLfI+Gguhd2rVUvY8tyEoo/WviGJmPRT8kc=";
              };
              patches = [];
              disabledTestPaths = [
                "tests/test_editable.py"
                "tests/test_builder.py"
              ];
            };
            pypcode = prev'.pypcode.overrideAttrs {
              version = "4.0.0";
              src = final.fetchFromGitHub {
                owner = "angr";
                repo = "pypcode";
                tag = "v4.0.0";
                hash = "sha256-OwnwgN2/MElH7SOwauS/hfVkgwAd0uMH0y00Ydkq+8I=";
              };
            };
        })
    ];
}
