# Decisions — devex-review

Tier-2 decision notes (see CLAUDE.md → Decision Records). Newest on top.

## 2026-08-11 — Fix program: one work item, day-1 state first

**What:** The 7 filed fix cards (M19–M24, L34) run as sequenced work packages
inside `work/devex-review/`, one package per session, ordered:
(a) clean day-1 state M19 → (c) setup correctness M24 → (b) spec workflow +
QA seat M20–M22 → (d) PM entry point M23 → (e) minimal mode L34.
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
