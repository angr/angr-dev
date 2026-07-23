---
name: angr-prepare-pr
description: Prepare, commit, push, and publish focused pull requests for the angr ecosystem, including cross-repository dependency chains and binary fixtures. Use when turning completed angr, cle, claripy, pyvex, archinfo, binaries, or angr-dev work into a reviewable branch or PR, refreshing an existing PR, or writing its description and validation record.
---

# Prepare an angr pull request

Read [pr-shape.md](references/pr-shape.md) before writing the PR body or
splitting cross-repository work.

## Preflight each repository

1. Resolve the exact repository, remote, base branch, head branch, and dependent
   PRs.
2. Fetch the current `origin/master`. Rebase or rebuild the branch only when it
   is safe for the branch owner and preserves reviewable history.
3. Inspect staged, unstaged, untracked, ignored, and committed changes. Exclude
   unrelated work rather than broadening the commit.
4. Verify that generated files, temporary diagnostics, plan/session references,
   local paths, and test artifacts are absent unless the project intentionally
   tracks them.
5. Re-run the focused regression and required lint/format checks on the exact
   head to publish.

## Shape the change

- Keep one root cause or coherent capability per PR.
- Split changes by repository ownership. Do not hide a required sibling change
  in an angr workaround.
- Put binary fixtures and reproducible fixture sources in `angr/binaries`.
  Reference the fixture PR from the consumer PR; do not compile a binary during
  the consumer's test run.
- Stage large migrations around explicit API and compatibility contracts. A
  100-commit draft without an agreed representation forces reviewers to
  re-litigate architecture throughout the implementation.
- Integrate with existing CI and dependency machinery. Add a new workflow only
  when it represents a lasting independent validation boundary.

## Commit and describe

Create focused commits with imperative subjects. Preserve useful logical
commits, but squash fixup noise when doing so does not disrupt active review.
Do not add AI attribution or session provenance automatically.

Write the PR description from verified evidence:

- Summarize the behavior change.
- Explain the observed failure and root cause, including the real code path.
- Explain why the chosen layer owns the fix and which workaround was avoided or
  removed.
- Describe the regression and why it represents production behavior.
- List exact validation commands, pass counts, skipped tests, environments, and
  measurements.
- Link issues, binaries, and dependent PRs. Add the repository's established
  `sync:` line when coordinated CI supports it.
- State remaining limitations without diluting them.

## Publish and verify

Push the exact head and set its upstream. Open or update the PR against
`master`. Re-read the rendered title, body, file list, and commit list.

Check that coordinated PRs point to the intended branches rather than released
or master packages during CI. Push in dependency order.

Follow required checks to terminal states. Report pending or failing checks
accurately; do not call the PR green while a required job is still running.
Invoke `angr-address-review` when feedback arrives.
