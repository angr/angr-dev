# angr development workspace

This repository is a workspace for the angr ecosystem. Most child directories
(`angr/`, `cle/`, `claripy/`, `pyvex/`, `archinfo/`, `binaries/`, and others)
are independent Git repositories. The root `angr-dev` repository does not track
their source files.

## Choose the owning repository

- Put symbolic AST, constraint, frontend, simplification, and solver behavior in
  `claripy`.
- Put VEX lifting, guest/host architecture handling, and the native VEX wrapper
  in `pyvex`.
- Put binary formats, loading, relocations, symbols, and memory mapping in `cle`.
- Put architecture descriptions and calling-convention data in `archinfo`.
- Put execution, state, analyses, CFG recovery, AIL, and decompilation in `angr`.
- Put compiled regression fixtures and their reproducible sources in `binaries`.
- Put only workspace setup and multi-repository developer tooling in `angr-dev`.

When a change crosses these boundaries, use one focused branch and PR per
repository. Link dependent PRs and land them in dependency order.

## Work safely

1. Read the closest `AGENTS.md` and inspect `git status`, the current branch, and
   remotes in every repository that may change. Use `git -C <repo> ...`; root
   status does not report changes in child repositories.
2. Preserve unrelated work. Prefer a fresh worktree and a branch based on the
   current `origin/master` when an existing checkout is dirty or on another
   task.
3. Reproduce the reported behavior before editing. Record the smallest real
   input, code path, and command that demonstrate it.
4. Trace the failure to the earliest layer that owns the violated invariant.
   Do not hide malformed state with a downstream guard, special-case one target,
   or add a silent fallback when the source invariant can be repaired.
5. Add a regression that exercises the real production path. Avoid synthetic
   states that the real system cannot create. For binary fixtures, add the
   binary and reproducible source to `angr/binaries`; do not compile fixtures
   during an angr test run.
6. Implement the smallest coherent general fix. Follow existing abstractions,
   dependency declarations, CI workflows, and language-native idioms.
7. Validate in layers: the focused regression, neighboring invariant tests,
   lint/format/type checks, and broader suites proportional to the risk. Test
   native extensions and cross-repository behavior in the actual target
   runtime, not merely at build or import time.
8. Review the final diff and repository status. Commit only the intended files.
   By default, create a focused commit and push the branch to its configured
   upstream. Report any commit or push blocker instead of including unrelated
   changes.

## Development environment

Follow `README.md` to bootstrap the workspace:

```bash
./setup.sh -i -e angr
```

The existing `nix-shell` entry point can provide system dependencies, but it
does not replace editable Python installs. Install the checked-out packages in
dependency order and rebuild affected packages after native or packaging
changes:

```bash
python -m pip install -e ./archinfo -e ./pyvex -e ./cle -e ./claripy -e ./angr
```

Verify that imports resolve to these checkouts before trusting a test result.
From an individual repository, prefer its CI-shaped commands:

```bash
uv run pytest path/to/test.py -q
uv run ruff check path/to/changed.py
uv run ruff format --check path/to/changed.py
```

Adapt the scope to the repository and changed language. Do not claim a full
suite passed when only a focused selection ran.

## Pull requests and review

- Keep each PR about one root cause or coherent capability. State the observed
  failure, root cause, fix, regression, and exact validation.
- Treat the lack of a formal GitHub approval as neither approval nor rejection.
  This project often reviews through top-level discussion and direct technical
  questions. Resolve every substantive objection before declaring a PR ready.
- Ask for a concrete binary, function, script, traceback, or benchmark when a
  change lacks a reproducible reason.
- Prefer the source invariant over a defensive workaround, simple existing
  structure over a parallel abstraction, and measured evidence over a
  presumptive platform or performance claim.
- Keep feedback direct and technical. Do not imitate personal jabs or profanity
  from historical reviews.
- Follow CI to a terminal result. Distinguish a real failure from infrastructure
  or a demonstrated flake; never weaken a regression merely to make a matrix
  green.

## Repository skills

Use the matching workflow in `.agents/skills/`:

- `angr-develop-change` for implementation and root-cause debugging.
- `angr-prepare-pr` for branch, commit, PR, and cross-repository packaging.
- `angr-review-pr` for reviewing a diff or pull request.
- `angr-address-review` for resolving comments and shepherding CI.
