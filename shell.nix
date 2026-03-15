let
  inputs = import ./nix/tamal {};
  pkgs = import inputs.nixpkgs {};
in
  pkgs.callPackage ./nix/dev.nix {}
