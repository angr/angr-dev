---
name: angr-develop-change
description: Implement and debug changes in the angr ecosystem with repository selection, real-path reproduction, root-cause analysis, focused regressions, and layered validation. Use for bug fixes, features, refactors, performance work, platform ports, or coordinated changes involving angr, cle, claripy, pyvex, archinfo, or binaries.
---

# Develop an angr change

## Establish the boundary

Read the root and closest `AGENTS.md`. Read
[repository-map.md](references/repository-map.md) before selecting a repository
or environment.

Restate the requested behavior as an execution boundary, inputs, outputs,
invariants, and unsupported cases. Resolve ambiguous nouns before designing. In
particular, distinguish a target architecture from the host on which angr must
run, and distinguish importability from useful runtime behavior.

Inspect the current implementation, history, tests, working tree, installed
module paths, and relevant sibling revisions. Treat session summaries and issue
descriptions as leads to verify, not ground truth.

## Isolate and reproduce

1. Identify the repository that owns the first broken contract. Split genuine
   cross-repository work at ownership boundaries.
2. Preserve existing changes. Use a fresh branch or worktree from current
   `origin/master` when the checkout is dirty, stale, or serving another task.
3. Reproduce the failure through the real public or production path. Reduce it
   to the smallest binary, function, script, formula, or package set that still
   fails.
4. Capture a falsifiable before-state: exception, wrong output, graph shape,
   performance measurement, dependency resolution, or unsupported-operation
   result.

Do not build a regression around a state that production never creates. Trace
who creates the state and in what lifecycle phase.

## Repair the owner of the invariant

Walk upstream from the symptom:

- Ask why the invalid state exists, not only where it crashes.
- Fix the earliest layer with enough information to preserve the invariant.
- Remove superseded guards, shims, fallbacks, and tests when the real fix makes
  them unnecessary.
- Keep target-specific observations in tests or reproducer notes; make the
  production rule apply to every target in its class.
- Add a capability gate only for a demonstrated platform limitation. Put
  optional-import complexity in the module that owns the optional feature.
- Prefer standard language/library traits and existing project abstractions over
  custom conversion, hashing, dispatch, CI, or packaging layers.
- Preserve documented flags and caller-visible behavior. Test the negative or
  disabled configuration explicitly.

Treat reviewer questions as invariant probes. A plausible workaround can still
be at the wrong layer; retrace the actual call path when the question exposes
that.

## Validate by increasing fidelity

Run the narrowest useful ladder:

1. Demonstrate that the regression fails before the fix and passes after it, or
   explain why an irreversible environment prevents the before-run.
2. Run nearby tests for the invariant, including disabled modes, serialization,
   copy/fork behavior, widths, aliasing, and repeated-analysis lifecycle where
   relevant.
3. Run lint, format, type, native-language, and broader Python suites
   proportional to the change.
4. For nondeterminism, repeat in fresh processes and vary relevant hash seeds.
5. For performance or dependency claims, compare measured A/B results and
   retain peak memory as well as elapsed time.
6. For native or browser ports, build a clean artifact set, install it into a
   fresh runtime, and execute a representative end-to-end analysis. A successful
   link or import is not sufficient.
7. For cross-repository work, test both the coordinated branches and native
   master-compatible behavior.

Report exact commands, counts, exclusions, and residual risks. Never upgrade
“tested,” “sampled,” or “inconclusive” into a stronger claim.

## Hand off

Review the final diff and status in every touched repository. State which
repository owns each change, what was verified, and what remains. Invoke
`angr-prepare-pr` when the task includes committing, pushing, or opening PRs.
