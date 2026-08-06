# Catchup prompt — Automatic Session Rollover (paste into a new agent session)

We're resuming automatic-session-rollover. Works in any runtime (Claude Code,
Codex, Gemini, OpenCode, Copilot) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## First actions

1. `scripts/context-budget.sh register --project automatic-session-rollover`
   — acquires the work-item lock the predecessor released.
2. Read `work/automatic-session-rollover/vendor-hooks-research.md` — the
   per-runtime hook schemas/events with citations; it is the spec for item #3.
3. Plan item #3 (`superpowers:writing-plans`, then executing-plans — the
   pattern items #1 and #2 both shipped with; shape references:
   `plans/2026-08-05-session-keyed-registry.md`,
   `plans/2026-08-05-launch-next-session.md`).

## Mission: item #3 — four vendor hook deployments

Items #1 (session-keyed registry + lock) and #2 (`launch-next-session.sh`)
are DONE, tested, pushed. Item #3 wires the WARN/STOP push channel into the
four non-claude runtimes so their agents get the in-band signal Claude Code's
`PostToolUse` hook already provides:

- **codex** — `UserPromptSubmit` hook.
- **gemini** — `BeforeAgent` hook (`.gemini/settings.json` already carries a
  graphify `BeforeTool` hook + the telemetry block — extend, don't clobber).
- **opencode** — `chat.message` plugin (working plugin code exists:
  `smoke-test-opencode.md`).
- **copilot CLI** — `sessionStart` + `agentStop`-reason at STOP (working hook
  JSON + auth path: `smoke-test-copilot.md`).

Each deployment should call `scripts/context-budget.sh check` (or a thin
wrapper in `scripts/hooks/`) and surface WARN/STOP escalation-only, throttled,
fail-open — mirror `scripts/hooks/context-budget-claude-hook.sh`.

## Constraints already decided (do not re-litigate)

- ADR-0003/0004 govern; hybrid trigger (WARN asks, STOP automatic); knobs
  workspace-level only; vendor specifics only in scripts; skills stay
  runtime-neutral.
- Known hook frictions: copilot folder-trust gate (repo hooks silently no-op
  in untrusted folders), copilot `additionalContext` discounted → use
  `agentStop` reason at STOP, codex hash-based hook trust, gemini JSON-only
  stdout, opencode mandatory `id`/`sessionID`/`messageID` part shape.
- VS Code agent-mode verification OUT of scope → `issues/01-vscode-agent-mode-hooks.md`.
- Standing push-to-main approval applies.
- At session end / rollover: release the lock (`scripts/context-budget.sh
  release --project automatic-session-rollover`) after the verification gate.

## Demand-load only when implementing that runtime

- `vendor-hooks-research.md` — per-runtime hook schemas/events + citations.
- `smoke-test-opencode.md` — working plugin code, sqlite artifact details.
- `smoke-test-copilot.md` — working hook JSON, auth path, VS Code section.

## Do NOT reload

- `handoff-archive.md` — sessions 1–4 provenance, superseded.
- `plans/2026-08-05-*.md` — both executed and landed; shape references only.
- `relaunch-analysis.md` — item #2 rationale (D1–D8), implemented; consult
  only if a launch-script question resurfaces.
- `docs/adr/0001*/0002*` — background only.
- Items #1/#2 design questions (identity, lock semantics, gemini guard,
  launch flags, tty guard) — settled, implemented, regression-tested; see
  `decisions.md` tail.

## State snapshot (at session-6 rollover, 2026-08-05)

- Branch `main`, working tree clean (only the live `.active-session` lock is
  untracked, by design); session-6 commits pushed: `b6d245a`, `d468f7c`,
  `ef42a12` + rollover commit.
- `scripts/launch-next-session.sh` EXISTS and is live; `ROLLOVER_RELAUNCH=manual`
  now operative. Test suites green: `test-launch-next-session.sh` (28
  asserts), `test-context-budget-registry.sh` (13).
- Machine: claude, codex 0.142.4, gemini 0.46.0, opencode 1.18.14, copilot
  CLI 1.0.78 installed. No running background processes.
- Work-item lock released at rollover; successor re-acquires via First
  action 1.
