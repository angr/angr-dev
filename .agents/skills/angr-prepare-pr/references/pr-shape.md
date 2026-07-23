# PR shape and template

## What the recent corpus shows

From May 22 through July 22, 2026, 272 PRs were opened across angr, cle,
claripy, and pyvex. Of 213 human-authored PRs, 182 merged. The median time to
merge across the full cohort was about 1.2 hours; 211 of 240 merged PRs,
including automation, landed within 24 hours.

This is a low-ceremony, high-trust process. Core maintainers frequently
self-merge small changes after CI. External, cross-repository, architectural,
and hard-to-reproduce changes receive much more discussion. Optimize for a PR
that a maintainer can validate quickly; do not add ceremony for its own sake.

## Recommended body

```markdown
## Summary

- <observable behavior change>
- <important compatibility or scope point>

## Root cause

<What failed, why it failed, and the real production call path.>

## Fix

<Why this layer owns the invariant and what obsolete workaround was removed.>

## Regression

<The binary/function/formula/package setup, before-state, and assertions.>

## Validation

- `<exact command>` — <result>
- `<exact command>` — <result>

<Known skips, platform limits, performance measurements, or dependent PRs.>

sync: <owner/repo#number>
```

Omit empty sections and `sync:` when they do not apply.

## Reviewability checks

- Make the title describe the behavior, not the implementation session.
- Keep code comments about enduring invariants, not phases, plans, prompts, or
  spikes.
- Show a reproducer for non-obvious bugs. Name the binary and function when
  relevant.
- Prefer one strong regression over many assertions on a fabricated internal
  state.
- Include negative configurations when preserving a flag or optional feature.
- Report focused tests as focused tests. Name exclusions from wider runs.
- Report performance with workload, elapsed time, and peak memory when the fix
  depends on a performance claim.
- For browser or native packaging, include a clean install and useful runtime
  operation, not just a built wheel.
- Keep the branch based on current master. Keep unrelated workspace work out.

## Cross-repository chains

Give every repository its own branch and PR. Link both directions where useful.
For an angr test that needs a new binary, land or synchronize the binaries PR
instead of adding a runtime compiler or weakening the test when CI cannot find
the fixture.

Use branch dependency overrides only for coordinated validation. Avoid leaving
temporary branch URLs or custom workflow inputs in the final merged state.
