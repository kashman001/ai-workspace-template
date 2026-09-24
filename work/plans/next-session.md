# Catchup prompt — plans (paste into a new agent session)

We're resuming `plans`. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (the ledger).
> Convention: docs/work-directory-conventions.md.

## Mission

Implement the tickets under `issues/` in dependency order, test-first, one
ticket per session unless a ticket is clearly small. Tickets 01–04 are done;
05's code is in (`plan.sh sync`, T18, commit `73e4752`) and only its **docs**
remain — a small unit. Finish 05 first, then take **06** (next on the
frontier; check its "Blocked by" line) in the same session if budget allows.

## Read these, in order

1. `handoff.md` top block → "Left for the successor" — the exact doc edits
   for ticket 05, and the position block's two-line shape.
2. `work/plans/issues/05-sync-and-markers.md` — boxes are ticked; set
   `**Status:** done` once the docs land.
3. `docs/plans.md` — the "`plan.sh`" table (add the `sync` row after
   `note`) and the Format paragraph (the launcher's `position` markers).
   Extend, don't restate.
4. `docs/work-directory-conventions.md` → "Required and optional files" —
   the marker convention goes in its own short section next to it. Write it
   once; `docs/plans.md` points at it.
5. `scripts/plan.sh` → the "generated blocks" section (`marker_check`,
   `marker_splice`, `cmd_sync`) — only to describe what it does, ~40 lines.
6. Then `work/plans/issues/06-*.md` for the next ticket, and the ledger
   block's "Choices made" for anything it leans on.

## Do NOT reload

- `decisions.md` in full — every note is settled (the newest, 2026-09-24,
  covers `sync`); open it only to append a new note.
- `concept.md`, `seams.md`, `spec.md` — the format is in `docs/plans.md`.
- The grill — closed. Do not re-open the verdict, the status set, HITL
  semantics, markers, node kind, or the integration list.
- The `create-work-item` launcher template — left alone on purpose (S22);
  S34's conditional "sync first" step is a later ticket, not 05.
- A runner, a Stop/SessionEnd hook, parallel checkouts, editing wayfinder
  (backlog L48) — all out of scope.

## Still binding

- Bash 3.2 + jq only; match `scripts/plan.sh`'s style. Exit codes 0/1/2 as
  documented. Text by default, `--json` on every read verb.
- `sync` derives, never decides; nothing outside the markers is generated;
  missing markers are reported (exit 1, naming file and marker), never
  invented.
- `plan.sh check` and `bash scripts/tests/test-plan.sh` (209) must stay
  green; `test-doc-consistency.sh` too after doc edits.
- Nothing pushed to origin; report how far ahead `main` is.

## State snapshot

Branch `main`, clean after this rollover's commit; nothing pushed. Tickets:
01–04 `done`; 05 code landed, docs pending; 06–11 `ready-for-agent`. Chain
supervised by `session-loop.sh` (seq 1 → … → 7 → 8). Budget at rollover:
WARN (~135K).

## First actions

1. `scripts/context-budget.sh register --project plans` (expect `seq=8`).
2. No question to pose. Proceed hands-off.
3. Ticket 05 docs: `docs/plans.md` `sync` row + `position` markers in the
   Format paragraph; the marker convention section in
   `docs/work-directory-conventions.md`; run `test-doc-consistency.sh`; set
   ticket 05 `done`; commit with a `Decision:` trailer if any choice was made.
4. `scripts/context-budget.sh record --label "ticket 05 docs"`.
5. `implement` ticket 06 with `tdd` (red cases in `test-plan.sh` first).
6. `record` at each step. At the end or at WARN/STOP: ledger block, rewrite
   this launcher (next ticket on the frontier), update the `work/README.md`
   row, commit. Do not push main; report how far ahead it is.
