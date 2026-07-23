# Review follow-up checklist

## Read-only inventory

Start with the standard PR view:

```bash
gh pr view <number> --repo angr/<repo> \
  --json url,state,isDraft,mergeStateStatus,reviewDecision,comments,reviews,commits,statusCheckRollup
gh pr checks <number> --repo angr/<repo>
gh pr diff <number> --repo angr/<repo>
```

Use the GitHub GraphQL API when resolved/unresolved thread state matters; REST
review and comment lists do not expose it reliably. Query `reviewThreads` for
`isResolved`, `isOutdated`, `path`, `line`, `comments`, and `originalCommit`.

Repeat the inventory after every push and immediately before handoff. Check
linked fixture and dependency PRs too.

## Feedback ledger

Track at least:

| URL | Kind | Requested outcome | Evidence needed | Action | Reply/thread state |
| --- | --- | --- | --- | --- | --- |
| comment | blocker/question/suggestion/CI | behavior, not wording | repro/test/trace/measurement | commit or explanation | pending/done |

Keep top-level comments in the ledger even though they cannot become unresolved
review threads.

## Evidence standards

- Root-cause objection: show the actual caller/lifecycle and why the new layer
  owns the invariant.
- Reproducer request: provide a minimal binary/function/script or formula and a
  one-command test.
- Performance objection: provide the same workload, toolchain, elapsed time,
  and peak memory for both cases.
- Dependency objection: show resolution on each affected platform and run
  consumer tests.
- “Can this be removed/simplified?”: identify every consumer before defending
  the abstraction.
- Flake claim: reproduce repeatedly on the exact head, compare with master, and
  isolate the nondeterministic dimension.

## Reply form

Use a compact form:

```markdown
You were right that <original assumption> was wrong. The real path is
<short trace/root cause>.

Fixed in `<sha>` by <behavioral change>. The regression now <real-path
assertion>. `<command>` passes (<count/result>).
```

For a tested disagreement:

```markdown
I tested <suggestion> on <workload>. It <measured failure>. The minimized
reproducer points to <cause/link>, so this PR retains <safer behavior>.
<current validation>.
```

Do not reply “done” without enough information for the reviewer to verify the
head.

## Terminal handoff

Report:

- Exact head SHAs and PR URLs.
- Which comments changed code and which were answered with evidence.
- Focused and broad test results.
- Required CI totals and any non-required neutral checks.
- Unresolved threads and unanswered top-level requests.
- Clean worktree and pushed tracking state.
