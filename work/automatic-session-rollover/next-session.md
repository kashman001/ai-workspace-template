# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

We're resuming automatic-session-rollover. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode, Copilot) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Mission: design AND documentation are **DONE** (docs shipped in `9c6a097`;
ADR-0003 + ADR-0004 govern; user raised no objections). This session starts
the **implementation phase**. Agreed order:

1. **Session-keyed registry migration** in `scripts/context-budget.sh`
   (register/check/record resolve-self; `.context-budget/sessions/
   <runtime>-<session-id>.json`; advisory lock `work/<proj>/.active-session`;
   gemini exception; D8 = new session file, same project, new session-id).
   Closes backlog **M13** — flip its card to Resolved when it lands.
2. **`scripts/launch-next-session.sh`** — 5 runtimes seeded-interactive
   (`claude`, `codex`, `gemini -i`, `opencode --prompt`, `copilot -i`),
   `--bg` claude-only; bootstrap prompt baked verbatim; honors
   `ROLLOVER_RELAUNCH`/`ROLLOVER_RUNTIME` from `context-budget.env`.
   **Re-verify every CLI flag against `--help` first.**
3. **Four hook deployments**: codex `UserPromptSubmit`, gemini `BeforeAgent`,
   opencode `chat.message` plugin, copilot CLI `sessionStart` +
   `agentStop`-reason at STOP.

### First actions

1. `scripts/context-budget.sh register`.
2. Read `docs/context-budget.md` §"Rollover trigger policy" / "Relaunch
   knobs" / "Multi-session model" — the committed spec. For deeper rationale:
   `relaunch-analysis.md` (conductor state machine D1–D8) and ADR-0004.
3. Plan item #1 with the user before coding (suggest
   `superpowers:writing-plans` or `tdd`): the registry migration touches
   register/check/record precedence, lock acquire/release, stale-lock
   reclamation, and the existing per-runtime adapters — decide test strategy
   (the bug has a known live repro shape: two sessions, one clobbers, record
   measures the wrong artifact).
4. As each item ships: update the implementation-pending status notes in
   `docs/context-budget.md`, the M13 backlog card (item #1), and
   `docs/workspace-structure.md` if file layout shifts.

## Constraints already decided (do not re-litigate)

- Design + docs are settled: ADR-0003/0004, `docs/context-budget.md` new
  sections, `skills/session-rollover/SKILL.md` trigger policy. Don't reopen.
- Hybrid trigger: WARN asks, STOP automatic; declined WARN arms write-ahead.
- Knobs live in `context-budget.env` (`ROLLOVER_RELAUNCH=manual` default,
  `ROLLOVER_RUNTIME` fallback-only); no per-project override; no extra STOP
  gate in `auto`.
- Vendor specifics only in scripts (CLI-first); skills stay runtime-neutral.
- Known hook frictions to honor (details in the demand-load docs): copilot
  folder-trust gate (untrusted repo hooks silently no-op), copilot
  `additionalContext` may be discounted → use `agentStop` reason at STOP,
  codex hash-based hook trust, gemini JSON-only stdout, opencode mandatory
  `id`/`sessionID`/`messageID` part shape (bare parts kill the turn).
- VS Code agent-mode verification is OUT of scope → `issues/01-vscode-agent-
  mode-hooks.md` (needs a Copilot-licensed machine).
- Standing push-to-main approval applies.

## Demand-load only when implementing that runtime

- `vendor-hooks-research.md` — per-runtime hook schemas/events + citations.
- `smoke-test-opencode.md` — working plugin code, sqlite artifact details
  (`~/.local/share/opencode/opencode.db`, per-turn `tokens.total`).
- `smoke-test-copilot.md` — working hook JSON, auth path, VS Code section.

## Do NOT reload

- `handoff-archive.md` — sessions 1–2 provenance, superseded.
- `work/template-maintenance/` — retargeted; nothing pending there.
- `docs/adr/0001*/0002*` — background only.
- Upstream `claude-handoff` SKILL.md — fully absorbed into ADR-0003.

## State snapshot (at session-4 rollover, 2026-08-05)

- Branch `main`; docs commit `9c6a097` + this rollover commit pushed; working
  tree clean.
- Machine: claude, codex 0.142.4, gemini 0.46.0, opencode 1.18.14,
  copilot CLI 1.0.78 all installed. No running processes.
- `launch-next-session.sh` does NOT exist yet; `ROLLOVER_RELAUNCH=manual` is
  set but inert until it does (skill falls back to paste-prompt).
