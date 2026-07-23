---
name: angr-review-pr
description: Review pull requests and diffs in angr, cle, claripy, pyvex, archinfo, and related repositories using the technical priorities and feedback patterns of angr maintainers. Use for code review, design review, regression assessment, merge-readiness evaluation, or requests to emulate how ltfish, rhelmot, and twizmwazin review changes.
---

# Review an angr pull request

Read [reviewer-patterns.md](references/reviewer-patterns.md) before reviewing.
Apply the maintainers' technical priorities, not their personal phrasing.

## Build the evidence

1. Resolve the repository, base, exact head, PR intent, issue, dependent PRs,
   commit list, comments, review threads, and CI state.
2. Read the complete diff and the surrounding implementation. Inspect callers,
   lifecycle, flags, sibling implementations, and tests; do not review isolated
   hunks as if they were the whole contract.
3. Reproduce or run the smallest relevant test when feasible. Treat claims in
   the body as unverified until code or results support them.
4. Separate pre-existing behavior from regressions introduced by the PR.

## Review in priority order

### 1. Root cause and realism

- Ask for a binary, function, script, traceback, formula, or benchmark when the
  motivation is not reproducible.
- Trace how the state is created. Reject a defensive guard or downstream
  normalization when an upstream invariant is broken.
- Verify that the regression uses a state the production algorithm actually
  reaches.
- Ask “why is this fix useful?” when the test and real path do not connect.

### 2. Correctness and preserved contracts

Check widths, signedness, hashes versus equality, serialization round trips,
copy/fork isolation, graph and cache lifecycle, aliases, nulls, mutation,
optional dependencies, target/host differences, and disabled modes as
applicable. Follow data across repository boundaries.

Treat a public flag or API as a contract. Flag unconditional behavior that
bypasses it.

### 3. Representation and API

Prefer types and representations that make invalid states difficult:

- Use real enums and specific native types instead of unstructured `Any`
  payloads where practical.
- Put semantic constructor arguments first and incidental metadata in clear
  keyword parameters.
- Keep hash/equality, mutability, pickle/serde, and type-checker behavior
  coherent.
- Use a large migration as an opportunity to settle the durable API before
  mechanically porting legacy warts.

### 4. Simplicity and native idioms

Look for passthrough functions, one-call wrappers, duplicate serialization
hooks, custom hashing/conversion where standard traits exist, unnecessary
single-dispatch, broad platform matrices with no consumer, and new CI workflows
that duplicate existing ones.

Keep optional complexity in the owning backend or loader. Prefer removal over a
new abstraction when only a test consumes it.

### 5. Validation and integration

Require a regression for behavioral fixes. Ask for a minitest or broad
representative run for large native refactors. Check lint, type checking,
packaging, cross-platform dependency resolution, performance, and dependent
repositories according to risk.

Do not accept presumptive platform exclusions or performance claims. Request a
measurement. Prefer consistent dependency versions across platforms unless
tests demonstrate a real incompatibility.

## Write actionable feedback

Anchor each finding to the narrowest file and line. State:

1. The violated behavior or invariant.
2. The concrete consequence.
3. The evidence or reproducer.
4. The required outcome; offer an implementation idea only when useful.

Use direct questions to expose missing reasoning. Mark blockers separately from
suggestions. Stay concise, factual, and respectful; do not reproduce historical
insults or profanity.

Choose `CHANGES_REQUESTED` when correctness, architecture, or required
validation blocks merging. Use a comment for questions and non-blocking
improvements. Approve only after checking that previous blockers are resolved.

Report findings first, ordered by severity. If no blocking issue remains, say
so and name residual risks or tests not run. Do not infer readiness solely from
an approval count: much angr review occurs in top-level PR discussion.
