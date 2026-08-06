# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

We're resuming automatic-session-rollover. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode, Copilot) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Mission: implementation item **#1 is DONE** (session-keyed registry + lock +
`release` landed, M13 closed, 13 regression tests green). This session builds
**item #2: `scripts/launch-next-session.sh`**, then starts item #3 if budget
allows. Spec for #2 (settled — do not re-litigate): 5 runtimes
seeded-interactive (`claude`, `codex`, `gemini -i`, `opencode --prompt`,
`copilot -i`), `--bg` claude-only; bootstrap prompt baked **verbatim**; honors
`ROLLOVER_RELAUNCH`/`ROLLOVER_RUNTIME` from `context-budget.env`; relaunch
runtime comes from the dying session's own registry record
(`.context-budget/sessions/<runtime>-<session-id>.json`, field `runtime`),
`ROLLOVER_RUNTIME` is fallback-only. **Re-verify every CLI flag against
`--help` before baking it in.**

Item #3 (next): four hook deployments — codex `UserPromptSubmit`, gemini
`BeforeAgent`, opencode `chat.message` plugin, copilot CLI `sessionStart` +
`agentStop`-reason at STOP.

### First actions

1. `scripts/context-budget.sh register --project automatic-session-rollover`
   — the `--project` form now exists and acquires the work-item lock the
   predecessor released.
2. Read `docs/context-budget.md` §"Relaunch knobs" (spec for #2) and skim
   §"Multi-session model" (what item #1 shipped; D8 successor confirmation =
   new session file, same project, new session-id — the launcher script can
   use it).
3. Plan item #2 (`superpowers:writing-plans`, then executing-plans — the
   pattern session 5 used successfully; its plan file is
   `plans/2026-08-05-session-keyed-registry.md` as a shape reference). Test
   strategy suggestion: `--dry-run`/command-echo mode so flag assembly is
   assertable without launching real sessions; put tests in
   `scripts/tests/test-launch-next-session.sh` (suite convention `test-*.sh`).
4. As it ships: flip the "Until the script lands, relaunch behaves as off"
   status note in `docs/context-budget.md` §"Rollover trigger policy", and
   update `docs/workspace-structure.md`'s existing `launch-next-session.sh`
   line if its description drifts.

## Constraints already decided (do not re-litigate)

- ADR-0003/0004 govern; hybrid trigger (WARN asks, STOP automatic); knobs
  workspace-level only; vendor specifics only in scripts; skills stay
  runtime-neutral.
- At session end / rollover: release the lock (`scripts/context-budget.sh
  release --project automatic-session-rollover`) after the verification gate —
  the SKILL.md now says this.
- Known hook frictions (for item #3; details in demand-load docs): copilot
  folder-trust gate, copilot `additionalContext` discounted → `agentStop`
  reason at STOP, codex hash-based hook trust, gemini JSON-only stdout,
  opencode mandatory `id`/`sessionID`/`messageID` part shape.
- VS Code agent-mode verification OUT of scope → `issues/01-vscode-agent-mode-hooks.md`.
- Standing push-to-main approval applies.

## Demand-load only when implementing that runtime

- `vendor-hooks-research.md` — per-runtime hook schemas/events + citations.
- `smoke-test-opencode.md` — working plugin code, sqlite artifact details.
- `smoke-test-copilot.md` — working hook JSON, auth path, VS Code section.
- `relaunch-analysis.md` — conductor state machine D1–D8 deep rationale.

## Do NOT reload

- `handoff-archive.md` — sessions 1–3 provenance, superseded.
- `plans/2026-08-05-session-keyed-registry.md` — executed and landed; shape
  reference only.
- `docs/adr/0001*/0002*` — background only.
- Item #1 design questions (identity derivation, lock semantics, gemini
  guard) — settled, implemented, regression-tested; see `decisions.md` tail.

## State snapshot (at session-5 rollover, 2026-08-05)

- Branch `main`, working tree clean after rollover commit; all session-5 work
  pushed (`15ec961`, `7b99b99`, `712c4bb`, `e88bf30`, `557015e`, `187f926` +
  rollover commit).
- `scripts/launch-next-session.sh` does NOT exist yet (docs already point at
  it; `ROLLOVER_RELAUNCH=manual` inert until it lands).
- Machine: claude, codex 0.142.4, gemini 0.46.0, opencode 1.18.14, copilot
  CLI 1.0.78 installed. No running processes.
- Work-item lock `work/automatic-session-rollover/.active-session` released at
  rollover; successor re-acquires via First action 1.
