# ADR-0012: Runtime contract — one adapter table, a probe-gated support matrix, fleet machinery isolated

- Status: accepted
- Date: 2026-09-21
- Deciders: Kashif + Claude Code sessions 8–16 of `template-improvement-review`

## Context

Six agent runtimes (Claude Code, Codex, Copilot CLI, Copilot in VS Code,
Gemini CLI, opencode) each had a hand-written hook wrapper, and the facts about
a runtime — where its transcript is, which event fires when, what a logout
looks like — were spread across those wrappers, the measurer and the docs.
Only Claude Code had ever run a supervised chain, yet the docs read as if every
runtime did. The sub-agent fleet verbs (child sweeps, dispatch records) lived
inside the measurer, sharing its state and its suites with the daily loop they
never take part in.

## Decision

Each runtime is one row in `scripts/hooks/context-budget-adapters.conf` —
session id source, transcript, how to count tokens, who registers, which hook
measures a turn and with what envelope, which hook ends a turn and how, what a
logout looks like — and one dispatcher, `scripts/hooks/context-budget-hook.sh
<runtime> <event>`, produces every vendor's payload from it. The per-vendor
files stay as one-line shims so committed vendor wiring needs no edit.

A runtime is *supported* for a mode (attended rollover, supervised chain) only
after the corresponding probe has passed on it and the support matrix in
`docs/context-budget.md` says so; today that is Claude Code for both. Codex and
Copilot CLI are unverified; Gemini and Copilot VS Code are attended-only. A
runtime with no hooks is unsupported — there is no polling layer.

Fleet machinery (`children`, `dispatch-contract`, `dispatch-open`,
`dispatch-close`, `dispatch-list`) lives in `scripts/fleet.sh` with its own
state (`work/<item>/.agent-dispatch/`), liveness rule, suites and doc section,
and is never called by the daily loop.

## Alternatives considered

- **A `verified` flag gating code paths per runtime** — rejected: speculative
  configurability; the matrix is a doc row and the probe is the evidence.
- **Folding per-child measurement into the session record** — rejected: wrong
  grain (a record per work item, children per session) and a fourth writer.
- **Keeping the transitive child-lock hierarchy in the launcher and `release`**
  — rejected: no incident ever needed it, and it depended on the roles
  ADR-0010 removes.
- **Deleting the opencode and Copilot VS Code rows as "non-goals"** —
  rejected: both ship with committed wiring that works; a row costs one line
  (integrations must stay agent-agnostic).
- **Repointing every vendor config at the dispatcher and deleting the shims**
  — deferred: Codex re-prompts its hook-trust hash on any command change, for
  no behavioural gain.

## Consequences

- Adding a runtime is one table row plus a probe run; drift in a vendor's
  payload breaks one row, not six files.
- The matrix is honest: a chain on Codex or Copilot CLI is an experiment until
  someone captures its logout shape and runs the supervised probe there.
- `scripts/fleet.sh` can change without touching the session suites, and vice
  versa.

## Provenance

- Promoted from: `work/template-improvement-review/decisions.md` (Stage 2
  design points 5 and 7, Stage 3 amendments); `plans/phase-2.md` (fleet move);
  `plans/phase-6.md` decisions 1–2, 8 (the table as data; rows kept; shims);
  `plans/phase-7.md` (probes and the support matrix).
- Commits: Stage 4 phases 2, 6 and 7 on `stage4`.
- Refs: `work/template-improvement-review/evaluation/stage3-design-v2.md`
  ("Runtimes", "Tests", "Non-goals").
