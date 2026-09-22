# Catchup prompt — session-management-followups (paste into a new agent session)

We're resuming `session-management-followups`. Works in any runtime (Claude
Code, Codex, Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Position: ticket 2 of 3 (01 done in e7c2356). Objective: work the tickets
under `issues/` in order, one per session, test-first, each landing on main
with its backlog card and a Decision note where an alternative was rejected.
When all three are `done`, close the item through the stop door.

1. `scripts/context-budget.sh register --project session-management-followups`
   (this session expects `seq=3`).
2. Open `issues/02-one-ledger-heading-rule.md`; set it `in progress`. Read
   only the files that ticket names, with targeted reads (the setup reads for
   ticket 01 cost ~70K; keep it lean).
3. Run `tdd` on the ticket: failing test, minimal change, suites green
   (`for t in scripts/tests/test-*.sh; do bash "$t" >/dev/null 2>&1 || echo "FAIL $t"; done; python3 scripts/tests/test-check-ledger.py; scripts/check-workspace-structure.sh`).
4. Backlog card: open and resolve in the same commit — next free ID is **M41**
   (M40 was ticket 01); cards are `<span class="id">M41</span>` inside a
   `<div class="find med resolved">` appended to the archive's Medium section
   (just above its `<h2>Low</h2>`), plus one change-log row before the open
   file's single `</tbody>` and the Resolved scorecard count (now 91) bumped.
   Never load either HTML whole. Decision note in `decisions.md` if an
   alternative was rejected. Tick the ticket's boxes, set `done`. One commit:
   `work(session-management-followups): ticket 02 — …` with a `Decision:` trailer.
5. Ledger block `# Session Handoff — 3 (<date>): ticket 02 — …` on top of
   `handoff.md` (plain numbered form only; keep two blocks, archive block 1
   to the top of `handoff-archive.md`);
   `python3 scripts/check-ledger.py work/session-management-followups` exit 0.
   Rewrite this launcher for ticket 03. Commit.
6. `scripts/context-budget.sh record --label "ticket 02 done"`, then roll over
   per `skills/session-rollover/SKILL.md` (under the supervisor: record
   "rollover complete", then `scripts/launch-next-session.sh
   session-management-followups --emit --loop-mode handsoff --loop-reason "…"`
   as the last action of the turn).
7. A refusal (`refused reason=<code>`): read the code in the skill's table
   and `docs/context-budget.md`; never edit a script outside the ticket's remit.

## Constraints already decided (do not re-litigate)

- Scope is tickets 01–03 only. Scaffolded lanes, human-only items, and parked
  items are out (README "What this is", categories 2–4).
- Ledger headings use the plain numbered form; the launcher's shell parser
  rejects the addendum form (ticket 02 settles the rule).
- `import-session-seq.sh` stays; it is the downstream migration tool (human,
  2026-09-22, `work/template-improvement-review/handoff.md` session 22).
- Ticket 01's readers live in `scripts/lib/session-lib.sh`;
  `context-budget.sh` keeps its own `owner_live()` (out of scope; noted).
- Do not push main; report how far ahead it is.

## Do NOT reload

- `docs/context-budget.md` for lock-based prose about attach/statusline: none
  exists (checked in session 2).
- The ticket 01 scripts and suites: done, green, committed.

## State snapshot

- Branch `main`, clean after this rollover's commit; 2 commits ahead of
  `origin/main`, not pushed.
- No running processes beyond the supervisor (`session-loop.sh`).

## Read these first, in order

1. `work/session-management-followups/issues/02-one-ledger-heading-rule.md`
2. `work/session-management-followups/handoff.md` (top block only)
