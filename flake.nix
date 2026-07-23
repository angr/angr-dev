{
  description = "Development environment for the angr repositories";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/6368bc923cec55a5f78960ade0cb4dd99580e087";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
      forAllSystems =
        f:
        builtins.listToAttrs (
          map (system: {
            name = system;
            value = f system;
          }) systems
        );
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.callPackage ./nix/dev.nix {
            # angr-management's Qt dependencies are installed in the venv by
            # install-editables.sh. Avoid rebuilding PySide in the Nix store.
            enableGui = false;
            # Keep the interpreter stable across nixpkgs updates and match the
            # minimum supported by the core repositories.
            python3Packages = pkgs.python312Packages;
          };
        }
      );
    };
}
