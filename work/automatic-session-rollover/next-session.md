# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

We're resuming automatic-session-rollover. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Mission: the design discussion is **COMPLETE — all four open questions
closed** (see `relaunch-analysis.md` → "Open questions — state as of
2026-08-05 session 3"). User-agreed sequence: **documentation first, then
implementation.** This session is the documentation phase.

### First actions

1. `scripts/context-budget.sh register`.
2. Read `relaunch-analysis.md` in full — the settled design: pipeline,
   hybrid trigger, conductor state machine (D1–D8), approved multi-session
   redesign, knobs, closed scope buckets.
3. Skim `decisions.md` (all Tier-2 notes) — the rationale + rejected
   alternatives the documentation must preserve.
4. Then draft the documentation set (discuss outline with the user before
   writing if anything is ambiguous):
   - `docs/context-budget.md` — add relaunch knobs (`ROLLOVER_RELAUNCH`
     off/manual/auto, default `manual`; `ROLLOVER_RUNTIME` fallback-only),
     hybrid trigger semantics (WARN asks / STOP automatic / declined-WARN
     write-ahead), and the session-keyed registry + per-project advisory
     lock model (gemini exception; hook-provided `transcript_path` path).
   - `skills/session-rollover/SKILL.md` — closing step gains the
     runtime-neutral relaunch line; cadence-rule fallback note for hook-less
     environments; answer-then-rollover for discussions.
   - `docs/workspace-structure.md` + `CLAUDE.md` pointer lines where the new
     script/knobs surface.
   - Promote the decision-note cluster into the ADR-0003 family
     (`/decision promote` — one amended or companion ADR, not four).
   - New ticket file (per `docs/agents/issue-tracker.md` conventions): VS
     Code agent-mode hook verification + `copilot_vscode_measure` check on a
     Copilot-licensed machine.
5. Only after docs are agreed: implementation planning (item #1 is the
   session-keyed registry migration in `scripts/context-budget.sh`, then
   `launch-next-session.sh` (5 runtimes), then the four hook deployments).

## Constraints already decided (do not re-litigate)

- All four open questions CLOSED — final state in `relaunch-analysis.md`;
  rationale in `decisions.md`. Do not reopen scope.
- Hybrid trigger: WARN asks, STOP automatic; declined WARN arms write-ahead;
  discussion atomic step = answer first, then roll over.
- Dying agent conducts the rollover itself; D4 (handoff content) is the only
  LLM step; everything else local (conductor state machine).
- Knobs: `context-budget.env`, `off/manual/auto`, default `manual`,
  workspace-level; consent lives in the trigger policy, no extra STOP gate.
- Launcher: all five runtimes seeded-interactive (`claude`, `codex`,
  `gemini -i`, `opencode --prompt`, `copilot -i`); background claude-only.
- Hook deployment (all in scope): codex `UserPromptSubmit`, gemini
  `BeforeAgent`, opencode `chat.message` plugin (exact part shape in
  `smoke-test-opencode.md` §2a — bare parts kill the turn), copilot
  `sessionStart` + `agentStop`-reason at STOP (folder-trust gate!).
- Bootstrap prompt wording baked verbatim; vendor specifics only in scripts;
  re-verify CLI flags against `--help` before shipping.
- ADR-0003 records the effort's why; registry-clobber gotcha in
  `docs/operational-knowledge.md`; standing push-to-main approval applies.

## Demand-load only when implementing that runtime (not for the doc phase)

- `vendor-hooks-research.md` — per-runtime hook schemas/events + citations.
- `smoke-test-opencode.md` — working plugin code, sqlite artifact details.
- `smoke-test-copilot.md` — working hook JSON, auth path, VS Code section.

## Do NOT reload

- `work/template-maintenance/` — retargeted; nothing pending there.
- Upstream `claude-handoff` SKILL.md — fully absorbed into ADR-0003.
- `docs/adr/0001*/0002*` — background only.
- `handoff-archive.md` — session-1 provenance, superseded.

## State snapshot (at session-3 rollover, 2026-08-05)

- Branch `main`, all session-3 work committed + pushed (single rollover
  commit; see ledger top block).
- Machine: opencode 1.18.14 (brew) and copilot CLI 1.0.78 (npm) newly
  installed; codex 0.142.4 + gemini 0.46.0 already present.
- No running processes; smoke-test scratch dirs live only in the old
  session's scratchpad (disposable).
