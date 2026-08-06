# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md` (append-only
> ledger, newest block on top). Convention: docs/work-directory-conventions.md.

## Mission

All build slices are done. The work item is now in **wayfinder
work-through-the-map mode** (`map.md` + `issues/06–08`): resolve the
research §14.4 open questions one ticket per session (research tickets
exempt from the one-per-session rule). This session:

1. **Re-dispatch ticket 07 gen 2** (copilot child artifact location —
   research, AFK): gen 1 yielded ROLLOVER_NEEDED before any probe runs.
   `dispatch-open` gen 2, spawn a fresh research subagent with the emitted
   contract; it starts at the report's open item 1 (report is
   self-contained).
2. **While it runs, take ticket 06** (mid-flight hook injection into
   running claude children — task, AFK): empirical verification; method
   sketch is in the ticket.
3. Ticket 08 (per-role thresholds) is **HITL** — only if the user is live;
   never resolve it AFK.

On each resolution: answer under `## Answer`, `Status: resolved`, gist to
map's Decisions-so-far, graduate/close the matching fog patch in `map.md`.

## Read these, in order

1. `handoff.md` top block — session-23 record.
2. `map.md` — destination, notes, fog.
3. For 07: `issues/07-copilot-child-artifact-location.md` +
   `research/07-copilot-child-artifacts.md` (the gen-1 checkpoint — the
   subagent needs both; you only need the ticket).
4. For 06: `issues/06-midflight-hook-injection.md`; research §3/§8 only if
   the method sketch proves insufficient.

## Do NOT reload

- Research md/HTML beyond the sections named above — settled; distilled
  into ADR-0005/0006, plan files, `docs/context-budget.md`.
- `rollover-scenarios.md`, `plans/*` — build slices all COMPLETE.
- Issues 01–03/05 — 01 spun out, 02/03/05 resolved. Issue 04 parked by the
  user — do not schedule unprompted.
- Sessions ≤22 handoff blocks, `handoff-archive.md` — settled.
- All slice design debates — decided; see ADR-0005/0006 + plan files +
  `decisions.md`.

## Constraints already decided (do not re-litigate)

- Role schema final: primary / auxiliary / child / superseded (+
  `superseded_by`, `--takeover`). Register-time stale-primary sweep ships
  (session 23).
- Dispatch-time contract is the load-bearing parent→child channel; hook
  injection is accelerator-only (R2, ADR-0005) — ticket 06 tests
  feasibility, not this layering.
- Coordination state is repository-keyed (ADR-0006).
- R2/R3/R4 shipped (`dispatch-contract`/`-open`/`-close`/`-list`); R6
  drain mode stays deferred. Runtime state stays gitignored. Standing
  push-to-main approval applies.

## State snapshot (at session-23 rollover, 2026-08-06)

- `origin/main` at `52b94ea` (+ this rollover commit). If auto-relaunch
  ran, the main checkout was ff-pulled by the launcher; otherwise
  `git pull --ff-only`.
- All eight suites green: registry 68, attach 22, launcher 81, statusline
  16, vendor 37, children 27, dispatch-contract 24, dispatch-records 51
  (326 asserts).
- Dispatch record `work/automatic-session-rollover/.agent-dispatch/
  07-copilot-artifacts.json` (main checkout, gitignored): gen 1 closed
  ROLLOVER_NEEDED. Copilot CLI 1.0.78 installed locally.
- Worktrees (all pushed, disposable — prune when convenient):
  `session-23-registry-hygiene` (this session's), plus the six listed in
  the session-22 snapshot.
- `issues/04-in-place-clear-relaunch.md` untracked in the user's checkout
  — parked by user choice.
- No live background agents (ticket-07 gen 1 yielded and was closed).
- Sandbox gotcha (parked learning, 1st strike): worktree-isolated
  sessions must issue plain single commands — compound chains are
  refused.

## First actions

1. `scripts/context-budget.sh register --project automatic-session-rollover`
   — expect `role=primary`; session 23's record back-stamped with YOUR id.
2. Confirm checkout carries `52b94ea` (`git log --oneline -3`); pull if
   not.
3. `scripts/context-budget.sh dispatch-open --project
   automatic-session-rollover --task 07-copilot-artifacts --report
   work/automatic-session-rollover/research/07-copilot-child-artifacts.md
   --brief work/automatic-session-rollover/issues/07-copilot-child-artifact-location.md
   --agent-type general-purpose` → spawn the gen-2 research subagent with
   the emitted contract; mark ticket 07 claimed.
4. Work ticket 06 while it runs; fold both resolutions into map +
   tickets; `dispatch-close` at yield.

## At session end

Lock releases mechanically (launcher script or SessionEnd hook). Manual
fallback: `scripts/context-budget.sh release --project automatic-session-rollover`.
