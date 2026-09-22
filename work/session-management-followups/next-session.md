# Catchup prompt — session-management-followups (paste into a new agent session)

We're resuming `session-management-followups`. Works in any runtime (Claude
Code, Codex, Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Position: ticket 3 of 3 (01 done in e7c2356, 02 done in 8a14af3). Objective:
work the tickets under `issues/` in order, one per session, test-first, each
landing on main with its backlog card and a Decision note where an
alternative was rejected. When all three are `done`, close the item through
the stop door.

1. `scripts/context-budget.sh register --project session-management-followups`
   (this session expects `seq=4`).
2. Open `issues/03-template-version-marker.md`; set it `in progress`. Read only the files
   that ticket names, with targeted reads (grep `docs/template-usage.md` for
   its upgrade guidance and `scripts/tests/test-template-instantiation.sh`
   for the instantiation/prune path; never load either whole).
3. Decision note FIRST in `decisions.md` (the ticket says so): chosen file
   name and value scheme, the alternatives considered, what the human changes
   to reverse it. The human has not chosen a shape and nobody is at the
   keyboard — build under the stated assumption; do not stop to ask.
4. Run `tdd` on the ticket: failing test (the marker exists, parses, survives
   the instantiation/prune path), minimal change, suites green
   (`for t in scripts/tests/test-*.sh; do bash "$t" >/dev/null 2>&1 || echo "FAIL $t"; done; python3 scripts/tests/test-check-ledger.py; scripts/check-workspace-structure.sh`).
   The marker only — no upgrade tool.
5. Backlog card: open and resolve in the same commit — next free ID is **M42**
   (M41 was ticket 02); cards are `<span class="id">M42</span>` inside a
   `<div class="find med resolved">` appended to the archive's Medium section
   (just above its `<h2>Low</h2>`), plus one change-log row before the open
   file's single `</tbody>` and the Resolved scorecard count (now 92) bumped.
   Never load either HTML whole. `docs/template-usage.md` names the marker;
   `docs/workspace-structure.md` tree gains its one line (the structure check
   already warns `workspace-structure.html is stale` — pre-existing; run
   `scripts/build-guide-html.sh` only if the check turns that into a failure).
   Tick the ticket's boxes, set `done`. One commit:
   `work(session-management-followups): ticket 03 — …` with a `Decision:` trailer.
6. Ledger block `# Session Handoff — 4 (<date>): ticket 03 — …` on top of
   `handoff.md` (plain numbered form only; keep two blocks, archive block 2 to
   the top of `handoff-archive.md`);
   `python3 scripts/check-ledger.py work/session-management-followups` exit 0.
   All three tickets are then `done`: rewrite this launcher into the closed
   state (position: item complete, nothing to do unless a ticket reopens) and
   end through the stop door per `skills/checkpoint/SKILL.md`
   (`scripts/context-budget.sh close`), not a rollover. Commit. Record
   `scripts/context-budget.sh record --label "ticket 03 done"` before closing.
7. If instead the budget hits WARN/STOP before ticket 03 lands, roll over per
   `skills/session-rollover/SKILL.md` (under the supervisor: record "rollover
   complete", then `scripts/launch-next-session.sh
   session-management-followups --emit --loop-mode handsoff --loop-reason "…"`
   as the last action of the turn). A refusal (`refused reason=<code>`): read
   the code in the skill's table and `docs/context-budget.md`; never edit a
   script outside the ticket's remit.

## Constraints already decided (do not re-litigate)

- Scope is tickets 01–03 only. Scaffolded lanes, human-only items, and parked
  items are out (README "What this is", categories 2–4).
- Ledger headings: one rule, `docs/work-directory-conventions.md` → Ledger
  ("One heading rule, two parsers"); the addendum form is grandfathered
  history, never written anew (ticket 02; `decisions.md` top note).
- `import-session-seq.sh` stays; it is the downstream migration tool (human,
  2026-09-22, `work/template-improvement-review/handoff.md` session 22).
- Ticket 01's readers live in `scripts/lib/session-lib.sh`;
  `context-budget.sh` keeps its own `owner_live()` (out of scope; noted).
- Ticket 03 builds the marker only; no upgrade tool (the ticket's own line).
- Do not push main; report how far ahead it is.

## Do NOT reload

- The ticket 01 and 02 scripts, suites, and docs: done, green, committed.
- `docs/context-budget.md` for lock-based prose about attach/statusline: none
  exists (checked in session 2).
- The M36/M41 backlog cards: the heading rule is settled.

## State snapshot

- Branch `main`, clean after this rollover's commit; 4 commits ahead of
  `origin/main`, not pushed.
- No running processes beyond the supervisor (`session-loop.sh`).
- `scripts/check-workspace-structure.sh` passes with one pre-existing warning
  (`docs/workspace-structure.html is stale`).

## Read these first, in order

1. `work/session-management-followups/issues/03-template-version-marker.md`
2. `work/session-management-followups/handoff.md` (top block only)
