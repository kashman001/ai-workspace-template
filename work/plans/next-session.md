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
the frontier is 05 and 06 (both blocked only by done tickets). Take **05**
(`sync` and the marker convention) — 07 and 08 need it. If it will not fit
one session, land the `plan.md` board first and leave the launcher block for
the successor.

## Read these, in order

1. `work/plans/issues/05-sync-and-markers.md` — the ticket.
2. `handoff.md` top block → "For ticket 05" — wave names live in no
   frontmatter (decide: number only, or omit); the board is spliced between
   markers, not appended to a section.
3. `docs/plans.md` — format, every verb, "State machine", "Check rules";
   extend, don't restate. The board's target shape is the fixture's
   `plan.md` between `<!-- plan:begin board -->` / `<!-- plan:end board -->`
   (`scripts/tests/fixtures/plan-01-concept/plan.md`).
4. `scripts/plan.sh` — read it whole (~450 lines): `load_nodes`,
   `DERIVE_JQ` (`ready`, `frontier`, `current_wave`), `section_append`
   (prose sections; the board needs a marker splice instead), `cmd_<verb>`
   + `case` arm per verb. Match the style.
5. `scripts/tests/test-plan.sh` — T8 fixture helpers (`reset`, `setf`,
   `addf`, `squeeze`), T12+ write-verb helpers (`fm`, `logs`, `lastlog`,
   `SS`). Append `T18…`; the ticket wants a byte-identical-outside-markers
   diff and an idempotence check.
6. `docs/work-directory-conventions.md` — where the marker convention gets
   its one write-up; find the launcher template the Position/Frontier
   block goes into (`skills/create-work-item/`).
7. `work/plans/spec.md` — only S2, S21.

## Do NOT reload

- `decisions.md` in full — every note is settled; open it only to append a
  new note or check one rejected alternative.
- `concept.md`, `seams.md` — the format is now in `docs/plans.md`.
- The grill — closed. Do not re-open the verdict, the status set, HITL
  semantics, markers, node kind, or the integration list.
- A runner, a Stop/SessionEnd hook, parallel checkouts, editing wayfinder
  (backlog L48) — all out of scope.

## Still binding

- Bash 3.2 + jq only; match `scripts/plan.sh`'s style. Exit codes 0/1/2 as
  documented. Text by default, `--json` on every read verb.
- `sync` derives, never decides; nothing outside the markers is generated;
  missing markers are reported (exit 1, naming file and marker), never
  invented.
- `plan.sh check` must still pass on the fixture after any fixture edit.
- Nothing pushed to origin; report how far ahead `main` is.

## State snapshot

Branch `main`, clean after this rollover's commit; nothing pushed. Tickets:
01–04 `done`; 05–11 `ready-for-agent`; frontier = 05, 06. Chain
supervised by `session-loop.sh` (seq 1 → … → 6 → 7). Budget at rollover:
WARN (~126K, hit right after ticket 04's suite went green).

## First actions

1. `scripts/context-budget.sh register --project plans` (expect `seq=7`).
2. No question to pose. Proceed hands-off.
3. `implement` ticket 05 with `tdd`: red cases first in `test-plan.sh`
   (board rendered between markers on the fixture; twice → byte-identical;
   outside text untouched; launcher block; missing markers → exit 1 naming
   file + marker), then `plan.sh sync` green.
4. Extend `docs/plans.md` → "`plan.sh`" table with `sync`; write the marker
   convention once in `docs/work-directory-conventions.md`.
5. Tick the ticket's boxes as each lands; `Decision:` trailer on the commit.
6. `scripts/context-budget.sh record --label "<unit done>"` at each step.
   At the end or at WARN/STOP: ledger block, rewrite this launcher (next
   ticket on the frontier), update the `work/README.md` row, commit. Do not
   push main; report how far ahead it is.
