# Next Session — template-improvement-review (Stage 4: supervised chain, session 20)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

You are session 20, the first child of `scripts/session-loop.sh
template-improvement-review --max-sessions 2` (runbook step 6), hands-off:
nobody is at the keyboard. Your job is to prove the chain is live, record
it, and roll over with `--emit --loop-mode handsoff` so the supervisor
reports `verdict=staged seq=20` and starts session 21. Small session; do not
start new work.

## Read these, in order

1. `work/template-improvement-review/cutover-runbook.md`, step 6 and "Done
   looks like" only.
2. `work/template-improvement-review/stage4-tracker.md`: the "Now" line and
   the cutover row only.
3. `work/template-improvement-review/handoff.md`, top block only (session 19:
   step 4 evidence, the hook-visibility finding).

## Do NOT reload

Findings Parts 1–4, stage reports, `review.md`, `decisions.md` (append only),
backlog HTML, any script whole (grep them), `plans/*.md`, `dispatch/*.md`,
`issues/*` (session 21 ticks ticket 10), `skills/session-rollover/SKILL.md`
beyond its refusal-code table.

## State snapshot (end of session 19)

- `main` = ea52c4a + session 19's bookkeeping commit; clean apart from 13
  untracked old-script state files in six *other* work items (leave them);
  ahead of origin (do not push).
- Runbook steps 0–5 done live: merge 37d4100; attended `--clear` rollover
  18 → 19 confirmed (seed line in the hook output; record `seq` 19,
  `pending` null, `rolled_over`); session 19 ended via `close`, then `/exit`.
- Chain started by the human from the repo root with `--max-sessions 2`.
- Cost floor: ~60–64K at `register` for a fresh Claude Code session here.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
   (expect `seq=20`).
2. Chain evidence: `jq '.chain' work/template-improvement-review/session-state.json`
   → `.chain.supervisor.pid` live (`kill -0 <pid>`), `.chain.used` = 1;
   `scripts/context-budget.sh supervised --project template-improvement-review`
   → rc 0; `work/template-improvement-review/.session-loop.log` shows
   `session-loop: staging the first session`.
3. Tracker: cutover row Used → 4, add that evidence to its Notes; "Now" →
   "session 20 in the chain (leg 1); 21 records the final evidence".
4. Ledger block `# Session Handoff — 20`: the evidence, short. Keep two
   blocks in `handoff.md` (archive block 18 to the top of
   `handoff-archive.md`). `python3 scripts/check-ledger.py work/template-improvement-review` exit 0.
5. Rewrite this launcher for session 21 (chain plan below). Commit the
   bookkeeping (`work(template-improvement-review): session 20 — ...`).
6. `scripts/context-budget.sh record --label "rollover complete: template-improvement-review"`,
   then `scripts/launch-next-session.sh template-improvement-review --emit --loop-mode handsoff --loop-reason "cutover chain leg 1 done"`.
   That is your last command; end your turn.
7. A refusal (`refused reason=<code>`): read the code in the skill's table
   and the runbook; never edit a script. A script bug is a finding for the
   tracker Notes and the runbook's "Blockers"; the human decides on a fix
   agent.

## The chain after you (carry this into each launcher you write)

- **21**: register; confirm `verdict=staged seq=20` in
  `work/template-improvement-review/.session-loop.log` and `.chain.used` = 2;
  tick the boxes in `issues/10-cutover.md` (import, attended rollover, chain;
  leave the retire-import box); tracker cutover row `done` with the merge
  commit 37d4100, Used → 5; ledger block 21 with the evidence (archive 19);
  commit; launcher for 22 ("chain capped; nothing to do until the human
  restarts with `--reset-cap`; open follow-up: retire
  `scripts/import-session-seq.sh` + `scripts/tests/test-import-session-seq.sh`
  + its row under "Reason codes" in `docs/context-budget.md`, after every
  live work item with a `.session-seq` is imported"); `record`;
  `--emit --loop-mode handsoff` → the supervisor reports `cap seq=22`.
