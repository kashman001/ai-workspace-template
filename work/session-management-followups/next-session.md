# Catchup prompt — session-management-followups (paste into a new agent session)

We're resuming `session-management-followups`. Works in any runtime (Claude
Code, Codex, Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Objective: work the three tickets under `issues/` in order (01, 02, 03), one
ticket per session, test-first, each landing on main with its backlog card
and a Decision note where an alternative was rejected. When all three are
`done`, close the item through the stop door.

1. `scripts/context-budget.sh register --project session-management-followups`
   (the first loop session expects `seq=2`; the scaffolding session was 1).
2. Open the lowest-numbered ticket in `issues/` whose status is `todo`; set it
   `in progress`. Read only the files that ticket names, with targeted reads.
3. Run `tdd` on the ticket: failing test, minimal change, suites green
   (`for t in scripts/tests/test-*.sh; do bash "$t" >/dev/null 2>&1 || echo "FAIL $t"; done; python3 scripts/tests/test-check-ledger.py; scripts/check-workspace-structure.sh`).
4. Backlog card: open and resolve in the same commit (grep the backlog header
   for the next free ID; never load the HTML whole). Decision note in
   `decisions.md` if an alternative was rejected. Tick the ticket's boxes,
   set `done`. One commit: `work(session-management-followups): ticket NN — …`
   with a `Decision:` trailer.
5. Ledger block `# Session Handoff — <seq> (<date>): ticket NN — …` on top of
   `handoff.md` (plain numbered form only; keep two blocks, archive older);
   `python3 scripts/check-ledger.py work/session-management-followups` exit 0.
   Rewrite this launcher for the next ticket. Commit.
6. `scripts/context-budget.sh record --label "ticket NN done"`, then: another
   ticket left → roll over per `skills/session-rollover/SKILL.md` (under the
   supervisor: `--emit --loop-mode handsoff`); none left → flip the
   `work/README.md` row to Complete, then `scripts/context-budget.sh close
   --project session-management-followups` and end the turn.
7. A refusal (`refused reason=<code>`): read the code in the skill's table
   and `docs/context-budget.md`; never edit a script outside the ticket's remit.

## Constraints already decided (do not re-litigate)

- Scope is tickets 01–03 only. Scaffolded lanes, human-only items, and parked
  items are out (README "What this is", categories 2–4).
- Ledger headings use the plain numbered form; the launcher's shell parser
  rejects the addendum form (ticket 02 settles the rule, until then avoid it).
- `import-session-seq.sh` stays; it is the downstream migration tool (human,
  2026-09-22, `work/template-improvement-review/handoff.md` session 22).
- Do not push main; report how far ahead it is.

## Read these first, in order

1. `work/session-management-followups/README.md`
2. `work/session-management-followups/handoff.md` (top block)
3. The current ticket under `issues/`
