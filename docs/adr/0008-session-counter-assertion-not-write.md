# ADR-0008: Rollover step 6 asserts the session counter rather than writing it

- Status: accepted
- Date: 2026-08-25
- Deciders: Kashif + Claude Code session 5 (session-loop-automation project)

> **Amendment (2026-08-29).** The first Decision consequence
> below prescribes a hand-run `git rev-parse --path-format=absolute
> --git-common-dir` recipe for the correction write. That recipe is superseded:
> the write moved behind the validating script mode this ADR anticipated
> (`scripts/context-budget.sh seq-sync --project <p> --session <N>`), which is
> now the counter's single writer and resolves the workspace root itself — the
> hand-run recipe resolves to the *git* root, the wrong directory whenever the
> workspace is nested inside the repository. Agents never hand-write
> `.session-seq`; step 1's `.rollover-options` hand-edit likewise moved behind
> `opts-sync`. The decision itself (assert, write only to correct) stands.

Amends ADR-0007. That ADR's core ruling stands unchanged: `.session-seq`, as
surfaced through each session's bootstrap prompt, is the canonical session
number, and on disagreement the ledger note is repaired, never the counter. What
this ADR changes is the **mechanism** ADR-0007 chose to keep the counter honest —
the unconditional `echo <N> >` in `session-rollover` step 6.

## Context

ADR-0007 closed a drift vector in which the *ledger* disagreed with the counter,
and it closed it by having the dying session write its own prompt number to
`.session-seq` at every rollover. Its final consequence line conceded the
remaining exposure: *"No mechanical validator exists."*

The exposure turned out to run the other way. On 2026-08-25, session 3 of
`session-loop-automation` reached step 6, wrote `4`, and
`launch-next-session.sh` launched **`#5`**. There was no session 4. **The counter
drifted, not the ledger** — the case ADR-0007 did not anticipate, since it treats
the counter as the thing that corrects prose.

Three properties made a one-character slip permanent:

1. **The write is redundant.** When `launch-next-session.sh` starts session N it
   has already written N to `.session-seq` (`:196`). Step 6 asks session N to
   re-derive and rewrite a value the file already holds.
2. **Re-derivation is biased toward the wrong number.** At step 6 the agent is
   about to launch its successor, so the successor's number is the salient one.
   The counter wants the writer's own.
3. **The error cannot be undone.** Cross-checkout reconciliation is numeric
   max-wins (`:194`), needed only because step 6's bare relative path strands
   copies in worktrees. Max-wins cannot decrease, so an over-count is absorbed
   and ratified: every later session writes its own inflated number, still the
   max. ADR-0007's self-heal is one-directional — it recovers a counter set too
   *low* by a launcher-bypassing start, and has no path back from one set too
   high.

Under a human-driven chain the cost is a heading repair, which is what ADR-0007
prescribes. Under the supervisor designed in
`docs/superpowers/specs/2026-08-21-session-loop-design.md` nobody reads the
prompt, so the drift is silent and compounding, and the number stops being usable
as evidence about the chain.

## Decision

**Step 6 becomes an assertion, and writes only to correct.** The dying session
compares `.session-seq` against the number in its own bootstrap prompt: equal ⇒
write nothing (the launcher already synced it); different ⇒ it started ad-hoc,
so it corrects the counter to its own number and records the correction in its
handoff block. A write that is not a correction is a defect.

Three consequences follow:

- **Any write resolves through the repository's common dir**, per ADR-0006 —
  `git rev-parse --path-format=absolute --git-common-dir` — never a bare
  relative path. Step 6 was the workspace's last agent-hand write at a bare
  relative path in the rollover path, and therefore the reason the counter
  strands at all. The same caution attaches to step 1's permitted hand-edit of
  `.rollover-options`.
- **Max-wins is retained for now and retired later.** It is load-bearing while
  stranded copies still exist. Once step 6 no longer strands — ideally once the
  write moves behind a validating script mode (`seq-sync --project <p>
  --session <N>`) — reconciliation should become last-write-wins with
  validation, which *can* correct downward.
- **Provenance goes in a sidecar, not in the counter.** `.session-seq` stays a
  bare integer.

## Alternatives considered

- **Keep the unconditional write, add a validator.** Rejected: ADR-0007 already
  rejected a `register`-time checker for reintroducing prose parsing, and a
  checker leaves both the redundancy and the stranding in place. Removing the
  write removes the defect class; checking it only reports the class.
- **Derive the number from the ledger.** Rejected by ADR-0007 as parsing
  agent-written prose. That ruling stands and is not reopened here.
- **Make `.session-seq` a JSON record carrying provenance.**
  `launch-next-session.sh:191` parses the file with `tr -cd '0-9'`, which would
  concatenate every digit in a JSON body into a garbage number — and would do so
  *silently*, producing exactly the class of failure this ADR exists to remove.
  Provenance belongs in a sidecar.
- **Retire max-wins immediately.** Rejected: it is the only thing currently
  rescuing a counter stranded in a worktree. Removing it before the stranding is
  closed trades a recoverable error for an unrecoverable one.
- **Supersede ADR-0007 outright.** Rejected: its canonical-source ruling is
  correct and still governs. Only the step-6 mechanism was wrong, and the
  workspace convention is to amend by forward-linked ADR (as ADR-0006 amends
  ADR-0004 and ADR-0005).

## Consequences

- The common case costs nothing: a launcher-launched session performs a
  comparison and no write at all. Every rollover does strictly less work.
- ADR-0007's eventual, one-rollover-lagged self-heal for ad-hoc starts is
  preserved verbatim — the correction branch is exactly that self-heal, now
  fired conditionally instead of unconditionally.
- The failure this ADR removes is *silent by construction*, so its absence is
  not observable. It needs a regression test rather than vigilance: prompt "#3"
  writing `4` must not be able to produce a `#5` successor.
- The counter becomes usable as a chain-integrity signal — exactly one increment
  per rollover — which the session-loop supervisor adopts as a guard (failure
  mode 10 in the design spec).
- Until the write moves behind a script mode, correctness still depends on an
  agent following prose. The residual risk is smaller (a comparison, not a
  derivation) but not zero.
- **The 2026-08-25 over-count is not repaired.** Per ADR-0007 the counter wins;
  `session-loop-automation` has no session 4 and its lineage stays as launched.

## Provenance

- Promoted from: `work/session-loop-automation/decisions.md` — 2026-08-25
  "Rollover step 6 becomes an assertion; the agent stops hand-writing the counter"
- Amends: ADR-0007 (canonical-source ruling retained; step-6 mechanism replaced)
- Refs: ADR-0006 (common-dir resolution this depends on);
  `skills/session-rollover/SKILL.md` step 6 + Verification;
  `docs/superpowers/specs/2026-08-21-session-loop-design.md` →
  "Session number progression", failure mode 10;
  `scripts/launch-next-session.sh:191`, `:194`, `:196`
