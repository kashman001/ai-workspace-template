# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

We're resuming automatic-session-rollover. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Objective: settle the design for automating the rollover→relaunch pipeline,
then implement. Next actions:

1. `scripts/context-budget.sh register`
2. Read `relaunch-analysis.md` — the grounding facts (verified vendor matrix,
   demo results, proposed knobs).
3. **Discuss with the user** the analysis' four open questions (knob shape,
   auto-mode consent, detection-reliability scope, runtime scope). The user
   explicitly asked for a proper discussion before implementation — do not
   start coding until these are settled.
4. Once settled: implement `scripts/launch-next-session.sh` + knobs + the
   session-rollover pointer line; verify (`bash -n`, live flag checks); Tier-2
   decision notes in `decisions.md`; docs (`docs/workspace-structure.md`
   scripts list, backlog changelog row); commit with `Decision:` trailer; push.

## Constraints already decided (do not re-litigate)

- Bootstrap prompt wording is load-bearing — bake it into the script
  **verbatim**: "Read `work/<project>/next-session.md` and continue from
  **First actions**." (see `relaunch-analysis.md`).
- Vendor launch specifics live ONLY in the script (CLI-first rule).
- Rejected: claude-handoff wholesale; prompt-only background handoff;
  nohup+yolo background emulation (leaning rejected — confirm with user).
- `claude --bg` has no `--name` flag; re-verify all flags against `--help`
  before shipping.
- Standing push-to-main approval applies (carried over from
  template-maintenance, same template repo).

## Read these first, in order

1. `work/automatic-session-rollover/README.md`
2. `work/automatic-session-rollover/handoff.md` (top block)
3. `work/automatic-session-rollover/relaunch-analysis.md`
