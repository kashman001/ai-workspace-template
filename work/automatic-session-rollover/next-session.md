# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

We're resuming automatic-session-rollover. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Objective: finish the design discussion, then implement. This is a
**discussion-first** project — do not start coding until the user closes the
open design points.

1. `scripts/context-budget.sh register` (also fixes the clobbered registry —
   see constraints).
2. Read `relaunch-analysis.md` in full — it is the design document; every
   settled point and open question lives there.
3. **Re-pose the open question to the user:** their verdict on the
   multi-session identity redesign (session-keyed state files + per-project
   advisory lock + gemini exception + D8 restated) — analysis delivered last
   session, not yet approved. It fixes a live wrong-measurement bug, so it
   likely becomes implementation item #1.
4. Then work the remaining open questions with the user: knob home
   (`context-budget.env` vs new file), detection-reliability scope (cadence
   rule vs vendor hooks — probably its own ticket), runtime scope
   (opencode/copilot).
5. Only after the user closes discussion: plan implementation (conductor
   state machine, `launch-next-session.sh`, session-keyed registry
   migration, knobs, skill pointer line).

## Constraints already decided (do not re-litigate)

- ADR-0003 (`docs/adr/0003-automate-rollover-relaunch.md`) records the
  effort's why + rejected alternatives (claude-handoff wholesale, prompt-only
  handoff, nohup+yolo emulation, vendor commands in skills).
- Hybrid trigger: WARN asks, STOP automatic; declined WARN arms write-ahead
  mode; discussion atomic step = answer first, then roll over.
- Dying agent conducts the rollover itself (conversation-only state).
- D1–D8: everything local except handoff-content generation (LLM-irreducible).
- Bootstrap prompt wording baked verbatim; vendor specifics only in scripts;
  verify every CLI flag against `--help` (no `claude --bg --name`).
- Registry-clobber gotcha + workaround: `docs/operational-knowledge.md`.
- Standing push-to-main approval applies.

## Read these first, in order

1. `work/automatic-session-rollover/README.md`
2. `work/automatic-session-rollover/handoff.md` (top block)
3. `work/automatic-session-rollover/relaunch-analysis.md`

## Do NOT reload

- `work/template-maintenance/` — retargeted; nothing pending there.
- Upstream `claude-handoff` SKILL.md — fully absorbed into ADR-0003.
- `docs/adr/0001*/0002*` — background only.
