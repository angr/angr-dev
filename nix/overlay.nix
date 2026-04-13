{
  angr ? pkgs: ../angr,
  pyvex ? pkgs: ../pyvex,
  claripy ? pkgs: ../claripy,
  cle ? pkgs: ../cle,
  archinfo ? pkgs: ../archinfo,
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
            devVersion = builtins.elemAt (builtins.match ".*__version__ = \"([^\"]*)\".*" (builtins.readFile "${path}/${project.pyproject.project.name}/__init__.py")) 0;
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
              pythonRelaxDeps = [ "capstone" "lmdb" ];
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
                  "icicle-cpu-0.1.0" = "sha256-WGh9U9fOo2VrQS7BFDqJ5TSEyMejZii1v6OuVJqixag=";
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
            pyxdia = final'.callPackage ./pyxdia.nix { };
            uefi-firmware = final'.uefi-firmware-parser;
        })
    ];
}
