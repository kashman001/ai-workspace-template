# Catchup prompt — jev-integration (paste into a new agent session)

We're resuming `jev-integration`. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Research is closed; the fit decision is approved (`decisions.md`, second
note): **integrate Jev at the `rlm` leaf-classification seam, gated on
access** — active only where `jev-api-key` is in the OS keychain; without one,
`rlm` behaves exactly as today. The requirements are `spec.md` (S1–S21, with
`## Testability`) and the six tickets under `issues/`. Plan
`01-gated-integration` now carries the implementation: waves 4–7 (nodes
07–16), one node per ticket, a reconcile node last in each wave, node 13 a
`hitl` UAT. This item is also the `plans` item's dogfood: findings go to
`work/plans/decisions.md`.

## Position

<!-- plan:begin position -->
Position: plan 01-gated-integration, open, wave 4 of 7, done 6/16, doing 0, todo 10, blocked 0, dropped 0, sessions 2.
Frontier: 07-gate-cli-test. Remaining: 10 of 16 — wave 4: 07-gate-cli-test todo, 08-reconcile-w4 todo.
<!-- plan:end position -->

## First actions

1. `scripts/context-budget.sh register --project jev-integration` (expect `seq=9`).
2. `scripts/plan.sh frontier --project jev-integration` → `07-gate-cli-test`
   (ticket `issues/01-gate-cli-and-offline-test.md`, spec S3/S4/S6/S8/S19).
   `start` it, read the node file and the ticket, then read `spec.md` →
   "Implementation Decisions" and "Testing Decisions" (not the stories).
   Build it test-first (`tdd`): `scripts/tests/test-jev.sh` (stub HTTP server,
   fake `security` on `PATH`, fixtures under `scripts/tests/fixtures/jev/`),
   then `scripts/jev.sh` (Choice only; key order `JEV_API_KEY` → macOS
   `security` → Linux `secret-tool`; `JEV_ENDPOINT` override; exit 0/2/3/4;
   never prints the key). Prior art: `scripts/tests/test-plan.sh` (harness
   shape), `research/spike.py` (wire shape — read, never run). Tick verified
   boxes, `done` (the node's `check` runs the test from `work/jev-integration/`
   with `WORKSPACE_ROOT` set).
3. `08-reconcile-w4`: verify on disk, record, `check`, `sync`, `done`.
4. Wave 5 while budget allows: `09-rlm-classify` (ticket 02, the seam),
   `10-credentials-docs` (ticket 03, tier cheap — a subagent candidate via the
   plans skill's prompt template), `11-cli-skill-rule` (ticket 04). Then
   `12-reconcile-w5`. Node 13 is `hitl` (UAT by the user): when it becomes the
   frontier, roll over with `--loop-mode interactive` so the successor poses it.
5. Overruns: `block`/split (Replan rule 1); record which as a finding.
6. At WARN/STOP: ledger block (insert after the header's `-->`; blocks are
   `# Session Handoff — N`; keep two, archive the rest newest-on-top, no
   duplicate N), `plan.sh sync`, commit with a `Decision:` trailer, then
   `session-rollover` (supervised chain → `--emit`). Do not push `main`.
7. `plan.sh` flags are separate words (`--project jev-integration`); a
   variable holding both is rejected. `frontier` exits 1 while a reconcile
   node is `doing` — do not chain it with `&&`.

## Do NOT reload

- `research/` beyond claim ids by grep; `spike.md` only if a number is needed.
- `rulings.md`, `sweep.md`, `seam-inventory.md`, the corrections — settled.
- `spec.md` "User Stories" in full — the tickets and the node bodies carry
  what each node needs; grep an `S<n>` when a box cites one.
- `work/plans/` beyond `decisions.md` (append) and `issues/11-dogfood.md`.
- `handoff.md` — the top block only if something above is unclear.

## Constraints already decided (do not re-litigate)

- Template rules: agent-agnostic, CLI-first, credentials in the keychain,
  documented as a first-class addition, a test that proves it without a live
  key. `scripts/jev.sh` is the only code that knows the endpoint or the key.
- The `rlm` swap is a new `classify()` helper beside `llm_query`; `llm_query`
  is byte-for-byte untouched (third note in `decisions.md`).
- Gated on access; `rlm` first; Q1 (c), Q2 narrow, Q5 (a) widened to (b) by
  the spec; `Promote?: maybe` on the fit note.
- Raw `pass/*.md`, `fact-check.md`, `record.md`, every brief, and
  `spike.{md,py}` are provenance — never edited. Do not re-run the spike.
  The key stays in the keychain: never print it, never write it to a file.
- No concrete model name in plan files (tiers only). Do not edit `plan.sh`,
  `session-loop.sh`, or the plans skill from this item.
- Vendor TypeSafe's SKILL.md from `typesafe-ai/skills` at `65a39f3` (v0.5.7);
  re-checked 2026-09-27, nothing newer.

## State snapshot

- Branch `main`, not pushed. Plan `01-gated-integration` open: wave 3 of 7
  done, nodes 01–06 `done`, frontier `07-gate-cli-test`.
- `decisions.md`: three notes (R0.4 lift; fit decision, approved; typed helper).
- `spec.md` Status: draft (the user may flip it to approved; the tickets are
  `ready-for-agent`, 05 `ready-for-human`).
- Chain: supervised; session 8 staged session 9 hands-off at WARN.
