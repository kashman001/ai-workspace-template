# Decisions — devex-review

Tier-2 decision notes (see CLAUDE.md → Decision Records). Newest on top.

## 2026-08-11 — M19 ledger move ships a migration shim, not a manual move

**What:** `context-budget.sh` folds any legacy
`work/context-decay/context-ledger.jsonl` into the new
`.context-budget/context-ledger.jsonl` at script load (`cat old >> new && rm
old`), instead of a one-off manual `mv` on the maintainer's machine.

**Why:** The ledger is not regenerable, and multiple live deployments of this
template exist (the heavy Insight workspace among them); a manual move fixes
one machine and silently splits history everywhere else. The shim is 3 lines,
idempotent, self-cleaning (no-op once the old file is gone), and covered by
regression asserts G3a–c in `test-context-budget-registry.sh`. Adopters are
unaffected (no legacy file).

**Rejected:** (1) manual move only — splits ledgers on every other
deployment; (2) documenting the move without automation — same problem plus
a doc burden that outlives its usefulness.

## 2026-08-11 — Fix program: one work item, day-1 state first

**What:** The 7 filed fix cards (M19–M24, L35 — filed as L34, renumbered after an ID collision with the insight clone) run as sequenced work packages
inside `work/devex-review/`, one package per session, ordered:
(a) clean day-1 state M19 → (c) setup correctness M24 → (b) spec workflow +
QA seat M20–M22 → (d) PM entry point M23 → (e) minimal mode L35.
Toolchain vendoring (M22) folds into package (b).

**Why:** Most packages are mechanical execution, not open design decisions —
only the spec workflow needs real user collaboration, and it gets a dedicated
session. M19 is the review's #1 priority ("single biggest trust repair") and
needs no design input, so it leads.

**Rejected:** (1) wayfinder map — decision-ticket overhead without enough open
decisions to justify it; (2) separate work items per package — 5× launcher/
ledger overhead for mostly single-session packages; (3) spec-workflow-first
ordering — deferred so the collaborative package doesn't block the mechanical
trust repairs. (User confirmed all three 2026-08-11.)

## 2026-08-11 — ROLLOVER_RELAUNCH=auto (user directive)

**What:** `context-budget.env` knob flipped manual → auto; successors now
background-launch at rollover without a consent ask.

**Why:** User directive: "Going forward make the session roll over automatic."

**Rejected:** staying `manual` (consent-gated) — explicitly superseded.
