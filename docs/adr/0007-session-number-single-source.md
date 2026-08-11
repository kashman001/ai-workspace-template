# ADR-0007: Make `.session-seq` (via the bootstrap prompt) the single source of session numbers

- Status: accepted
- Date: 2026-08-06
- Deciders: Kashif (user) + agent, session 30 of automatic-session-rollover

## Context

A work item's session lineage number appears in three places, each written by a
different actor: machine-local `work/<proj>/.session-seq` (maintained by
`scripts/launch-next-session.sh`, feeds the bootstrap prompt's "session #N" and
claude `--name`), `handoff.md` ledger block titles (agent-written prose), and
worktree/branch names (agent-chosen). Nothing tied them together, and they
drifted: the session launched by prompt "#28" was ledger-#29, because an
earlier session was started from a hand-pasted prompt (launcher bypassed, no
seq increment). The user hit the confusion live. Any fix had to hold without
humans or agents hand-repairing the counter.

## Decision

We use `.session-seq`, as surfaced through each session's bootstrap prompt, as
the canonical session number. A session takes the number from its own prompt
verbatim for ledger block titles and worktree names — never re-derived from
ledger prose. Ledger/counter disagreement is repaired in the ledger note; the
counter wins. Drift self-heals mechanically: at `session-rollover` step 6 the
dying session writes its own prompt number to `.session-seq` before emitting
or launching the successor, so a launcher-bypassing launch corrects the
counter within one rollover. A session whose prompt carries no number (ad-hoc
start) takes counter + 1 as its number; its rollover sync counts it in.

## Alternatives considered

- **Ledger block titles as source** — rejected: deriving the next number means
  parsing agent-written prose; fragile by construction.
- **Committing `.session-seq`** — rejected: it is per-machine runtime state;
  clones and multiple machines would conflict on every rollover.
- **`register`-time warning when ledger title ≠ counter** — rejected: it
  reintroduces the same prose parsing as a checker, and the step-7 sync
  already closes the only observed drift vector (YAGNI).

## Consequences

- Numbering stays correct with zero standing maintenance; the cost is one
  `echo` in the rollover skill's step 6, executed every rollover.
- Drift from an ad-hoc/hand-pasted launch persists until that session's
  *next* rollover (self-heal is eventual, one-rollover-lagged, not instant).
- The number is machine-local by design: two machines working the same item
  can still disagree until one launches from the other's pushed state — an
  accepted limitation of not committing the counter.
- No mechanical validator exists; a session that ignores the verbatim rule
  reintroduces prose drift until its successor's sync.

## Provenance

- Promoted from: `work/automatic-session-rollover/decisions.md` — 2026-08-06
  "Session numbers: `.session-seq` + bootstrap prompt canonical"
- Refs: `work/automatic-session-rollover/issues/10-session-number-single-source.md`
