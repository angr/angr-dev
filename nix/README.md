## Pinned or unpinned?

By and large, the nix files in the repo root use nixtamal-pinned dependencies, while the nix files in this folder take parameters for ther dependencies.

The exception to this is pyproject.nix, which is imported directly when you just import the overlay. I figured it's a pretty stable dependency.

## Dev shell with editable installs

Just use shell.nix. It'll build a venv for you and make everything work just right.

e.g:
```shell
nix-shell
```

## Building a derivation with a pinned version of angr

Use overlay.nix. The parameters to it can be left blank to use the current checkout, or can be provided as a function which takes the nixpkgs pkgset and returns the source derivation for each repo.

e.g:
```nix
import <nixpkgs> { overlays = [ (import ./nix/overlay.nix {}) ]; }
```
