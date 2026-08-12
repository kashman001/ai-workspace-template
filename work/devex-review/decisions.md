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

## 2026-08-11 — Hooks dependency check: committed wiring satisfies it (M24)

**What:** `check-dependencies.sh`'s required "hooks" item now passes when any
runtime's context-budget wiring is present (committed Codex/Gemini/OpenCode/
Copilot files count); the Claude Code settings copy is required only when
`claude` is on PATH.

**Why:** A pristine clone's first documented command must succeed; the old
Claude-only grep broke the template's agent-agnostic promise (dev 4).

**Rejected:** (1) keeping the hard Claude-only requirement — the bug itself;
(2) requiring every installed runtime's wiring — hard to detect installs
portably, and committed wiring already covers the non-Claude runtimes.

## 2026-08-12 — Spec workflow conventions (M20–M22, grilled with user)

**What:** (1) Minimal spec.md skeleton — Status/Approved-by header, stable
S<n> IDs, non-goals — in docs/agents/issue-tracker.md "Spec conventions".
(2) In-file approval default; branch-review loop documented for multi-person
specs. (3) Spec required when "done" is debatable + create-work-item asks at
scaffold time; an external tracker ticket with real acceptance criteria can
be the spec of record (referenced, mirrored read-only when agents lack
tracker access). (4) Both SPEC.md names kept, cross-referenced. (5)
Spec:/Covers: ticket fields, advisory. (6) One verification.md (plan +
evidence), Severity:/Repro: on bugs, no-spec → README ## Success criteria.
(7) to-spec/to-tickets/triage vendored at upstream 8b36d4f (MIT);
tdd/diagnosing-bugs/grilling/domain-modeling stay global-only with
point-of-use pointers.

**Why:** User decisions from the package-(b) grilling session (Q1–Q7); the
dependency line drawn: skills the conventions route through must ship;
engineering-practice skills are personal toolchain.

**Rejected:** full-PRD skeleton (empty-heading filler); mandatory branch/PR
approval (ceremony for single-human efforts); always-require-spec (ceremony
for ops work); renaming either spec file (churn, paths already
disambiguate); mandatory traceability fields (no enforcement mechanism);
separate test-plan.md + verification.md (doubles the skip chance); vendoring
all five skills / declaring all as prerequisites.
