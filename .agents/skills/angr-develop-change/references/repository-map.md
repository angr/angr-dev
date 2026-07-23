# Repository and environment map

## Ownership

| Repository | Primary contract |
| --- | --- |
| `archinfo` | Architecture descriptions, registers, ABI and calling-convention data |
| `pyvex` | LibVEX integration, lifting, guest/host widths, native wrapper and build |
| `cle` | Binary loading, formats, relocations, symbols and mapped memory |
| `claripy` | ASTs, constraints, simplification, solver frontends and backends |
| `angr` | State and execution, analyses, CFGs, AIL, decompiler and integration |
| `binaries` | Compiled test inputs plus reproducible fixture sources |
| `angr-dev` | Workspace setup and multi-repository developer tooling |

Start at the earliest broken contract. A crash in an angr analysis may originate
in a malformed CFG, loader metadata, lifter output, or solver behavior.

## Dependency direction

Use this rough order for coordinated work:

```text
archinfo ─┬─> pyvex ─> cle ─┐
          └─────────────────┼─> angr
claripy ────────────────────┘
binaries ───────────── tests in any consumer
```

Create separate PRs when more than one repository changes. Push and test
dependency branches before their consumers.

## Workspace mechanics

The root repository ignores most child directories because they are independent
clones. Always run status, diff, log, branch, and commit commands with
`git -C <repo>` or from inside the child repository.

Follow the root `README.md` to create the development environment:

```bash
./setup.sh -i -e angr
```

Use `nix-shell` when Nix-provided system dependencies are useful. Install
sibling packages editable in dependency order, and reinstall affected packages
after native, packaging, or file-set changes:

```bash
python -m pip install -e ./archinfo -e ./pyvex -e ./cle -e ./claripy -e ./angr
```

Confirm module origins before trusting results:

```bash
python -c 'import angr, cle, claripy, pyvex; print(angr.__file__); print(cle.__file__); print(claripy.__file__); print(pyvex.__file__)'
```

Use the repository's current CI configuration as the command authority.
Typical focused commands are:

```bash
uv run pytest path/to/test.py -q
uv run ruff check path/to/changed.py
uv run ruff format --check path/to/changed.py
```

Beware of a Python or Emscripten ABI mismatch between an existing environment
and the current toolchain. Recreate or repair the environment instead of
interpreting mixed wheel tags as a source failure.

## Lessons from recent local sessions

- Confirm the requested boundary early. “Support WASM” meant running angr on a
  WASM host, not analyzing WASM as a guest.
- Prove the highest-risk dependency gates before broad implementation. The
  browser port proved Z3 and PyVEX in Pyodide before changing the full stack.
- Validate the actual runtime. Wheel linking, importing, and native tests did
  not replace fresh Pyodide, symbolic execution, CFG recovery, and Chromium
  worker smoke tests.
- Keep unsupported features explicit, but do not assume they are unsupported.
  Measure or compile them first.
- Search for an existing capability by its underlying analysis and behavior, not
  only by the user's phrase. Full-program type recovery, for example, already
  exists through `CompleteCallingConventions`.
- Prefer a general upstream repair over a local shim. Remove the shim after the
  owning repository is fixed.
- Make correctness claims structurally honest. Random trials are evidence, not
  a symbolic proof; an SMT timeout is inconclusive, not equivalence.
- Repeat nondeterministic proofs and analyses under fresh processes and hash
  seeds. Stable output is part of correctness.
