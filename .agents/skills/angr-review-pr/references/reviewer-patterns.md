# Reviewer patterns from the recent PR corpus

## Corpus and interpretation

This reference summarizes GitHub activity from May 22 through July 22, 2026 in
`angr/angr`, `angr/cle`, `angr/claripy`, and `angr/pyvex`.

- 445 PRs had activity in the window; 272 were opened in it.
- 213 newly opened PRs were human-authored and 182 of those merged.
- Only six newly opened human PRs received a substantive formal GitHub review
  before merge. Thirty-eight had visible non-author human feedback through
  reviews, inline comments, or top-level discussion before their current
  cutoff; 23 of the 182 merged human PRs had that feedback before merge.
- Core maintainers commonly self-merge small changes after CI. Formal review
  state is therefore a weak proxy for technical review or readiness.

After excluding self-replies, non-PR issues, and automation in the full activity
set, ltfish commented on or formally reviewed about 35 PRs, rhelmot 8, and
twizmwazin 9. One unusually large Rust AIL migration accounts for much of the
inline volume from rhelmot and twizmwazin; use the patterns, not raw counts.

## ltfish: root cause, domain invariants, and concrete reproducers

Emphasize:

- Ask for the exact binary, function, and script before accepting a non-obvious
  analysis fix.
- Reject defensive changes that hide the underlying bug. In
  [angr#6438](https://github.com/angr/angr/pull/6438), a deterministic sort was
  reasonable defensively but could conceal an order-dependent type-lattice bug.
- Chase the invariant to its owner. In
  [angr#6655](https://github.com/angr/angr/pull/6655), repeated questions moved a
  proposed SPropagator guard through several plausible graph workarounds to the
  actual repeated-CFG/FunctionManager lifecycle.
- Ask when angr creates the problematic input and whether a global workaround
  harms performance or inspectability. See
  [angr#6506](https://github.com/angr/angr/pull/6506).
- Guard decompiler and CFG contracts: normalized versus live graphs, block
  identity, variable recovery, type-lattice behavior, and fixture realism.
- Require binary fixtures in `angr/binaries`, not compilation during test runs.
- Request comments for behavior that otherwise looks like “black magic.”
- Approve tiny, clear fixes tersely and thank contributors once the evidence is
  sufficient.

Use concise domain questions. Keep asking until the proposed state and real call
path line up.

## rhelmot: durable architecture, strong types, and adversarial semantics

Emphasize:

- Review large refactors at the representation and public-API level, not only
  for parity with legacy code.
- Prefer principled enums and concrete types over `PyAny`, repeated
  `isinstance` lists, Python containers in Rust hot paths, and sentinel-based
  state.
- Check constructor ergonomics, semantic versus metadata parameters,
  `__match_args__`, immutability, mutation after construction, and consistent
  error-return conventions.
- Probe hash sentinels, adversarial values, ownership, allocations, generated
  stubs, inheritance, and panics. Request a representative minitest for a native
  migration.
- Question whether stale fields still have meaning after architectural changes.
- Bring real downstream use into review. In
  [angr#6443](https://github.com/angr/angr/pull/6443), the ability to start
  execution at a chosen block index mattered because an external script used
  it.
- Use `CHANGES_REQUESTED` when systemic design problems make further line review
  unproductive; use short approvals for straightforward fixes.

The detailed example is the architecture review on
[angr#5967](https://github.com/angr/angr/pull/5967). Reproduce its depth, not its
hostile wording.

## twizmwazin: simplicity, native idioms, packaging, and integration

Emphasize:

- Replace conversion boilerplate with language-native traits such as
  `FromPyObject`/`IntoPyObject`, use standard hashing, supported big integers,
  and binding annotations.
- Remove passthroughs, single-caller helpers, duplicate pickle mechanisms, and
  machinery without a real consumer.
- Ask whether a platform restriction is observed or merely presumptive.
- Keep optional import logic in the backend that owns it, and avoid conditional
  registration when existing backends work unconditionally.
- Integrate new targets into existing CI rather than creating parallel
  workflows. Keep PR CI from publishing.
- Let `uv sync` and existing `uv.sources` express coordinated branch
  dependencies rather than custom workflow inputs.
- Prefer one dependency version across platforms to avoid a footgun, but accept
  a split when full tests and a minimized upstream reproducer prove the newer
  version regresses.
- Check that dependency markers do not restrict unrelated platforms.

See the cross-repository feedback on
[angr#6658](https://github.com/angr/angr/pull/6658),
[cle#702](https://github.com/angr/cle/pull/702),
[cle#703](https://github.com/angr/cle/pull/703),
[claripy#737](https://github.com/angr/claripy/pull/737), and
[pyvex#555](https://github.com/angr/pyvex/pull/555).

## Shared standard

All three reviewers favor:

- Evidence over assertion.
- A real regression over a synthetic demonstration.
- Repairing the owning invariant over suppressing a downstream symptom.
- Simpler, native mechanisms over bespoke layers.
- Direct questions over ceremonial review prose.
- Fast acceptance when scope, correctness, and CI are obvious.

Apply that standard without copying sarcasm, insults, or reviewer-specific
verbal tics.
