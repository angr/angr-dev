## Pinned or unpinned?

By and large, the nix files in the repo root use nixtamal-pinned dependencies, while the nix files in this folder take parameters for ther dependencies.

The exception to this is pyproject.nix, which is imported directly when you just import the overlay. I figured it's a pretty stable dependency.

## Dev shell with editable installs

Run:

```shell
nix develop
```

The shell creates a persistent `.venv` and editable-installs each checked-out
core package it finds (`angr-data`, `archinfo`, `pyvex`, `cle`, `claripy`,
`angr`, and `angr-management`). Re-entering the shell only verifies the editable
install paths, so it does not rebuild the packages each time.

To rebuild the editable installs after changing native code, run
`./nix/install-editables.sh --force` from inside the development shell.

The non-flake `nix-shell` entry point remains supported.

## Building a derivation with a pinned version of angr

Use overlay.nix. The parameters to it can be left blank to use the current checkout, or can be provided as a function which takes the nixpkgs pkgset and returns the source derivation for each repo.

e.g:
```nix
import <nixpkgs> { overlays = [ (import ./nix/overlay.nix {}) ]; }
```
