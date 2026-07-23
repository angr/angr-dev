---
name: angr-address-review
description: Address review comments and shepherd CI for angr ecosystem pull requests with a complete feedback inventory, evidence-backed fixes, concise replies, cross-repository coordination, and terminal status checks. Use when asked to address comments, resolve review threads, update a PR after maintainer feedback, investigate CI failures, request re-review, or monitor related angr, cle, claripy, pyvex, archinfo, or binaries PRs.
---

# Address angr review feedback

Read [review-checklist.md](references/review-checklist.md) before mutating a
reviewed branch.

## Inventory before editing

Resolve the exact PR and every dependent or consumer PR. Collect:

- Top-level conversation, submitted reviews, inline comments, and unresolved
  threads.
- Comments added after the last push or prior sweep.
- The commit each inline comment reviewed.
- Current head SHA, merge state, required checks, and failed logs.
- Dependent branch revisions and synchronized fixture PRs.

Build a ledger with the comment URL, requested behavior, classification, planned
evidence, action, and reply status. Do not treat “zero unresolved threads” as
“zero actionable comments”; maintainers frequently use top-level discussion.

## Classify and investigate

Classify each item as:

- Correctness or architecture blocker.
- Request for a reproducer, test, measurement, or explanation.
- Simplicity or maintainability change.
- Non-blocking suggestion.
- Outdated after a later commit.
- Incorrect premise that needs evidence, not deference.
- CI, dependency, or infrastructure issue.

Reproduce the concern and trace the real path before editing. Treat the
reviewer's proposed implementation as a clue, not necessarily the required
solution. If a reviewer exposes that the patch is at the wrong layer, remove
the workaround and repair the owning invariant.

When a suggestion fails full tests, do not quietly ignore it. Produce a minimal
reproducer or A/B measurement, find the upstream cause when practical, and
retain the safer design with that evidence.

## Implement and reply

Keep fixes scoped to the reviewed PR. Add or strengthen the regression and run
focused plus neighboring tests before pushing. Rebase on current master when
needed, but do not rewrite an active shared branch without authority.

Reply to each substantive item with:

1. What investigation established.
2. What changed, including the commit when pushed.
3. What regression or measurement now covers it.
4. Exact validation results or the remaining blocker.

Lead with an admission when the original patch was wrong. Keep replies concise
enough to review; link detailed artifacts instead of pasting an investigation
transcript. Resolve inline threads only after the answer is present on the
published head.

## Shepherd the PRs

Push dependency repositories before consumers. Verify that CI checks out the
intended dependent heads.

Follow all required checks to terminal states:

- Reproduce a red job locally or in an equivalent environment before changing
  source.
- Distinguish deterministic regressions, platform-specific failures,
  infrastructure failures, and flakes with evidence.
- Rerun only a demonstrated flake. Do not dismiss a failure because it is
  unrelated to the latest edit.
- Do not add a skip or fallback that weakens the regression merely to unblock a
  matrix.
- Continue scanning for new comments while long jobs run.

Finish with a fresh sweep over every linked PR. Require no unanswered
actionable top-level comment, no unresolved substantive thread, a clean pushed
worktree, and green required checks. A formal approval is not mandatory in this
project, but unresolved technical objections are.
