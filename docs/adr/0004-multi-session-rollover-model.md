# ADR-0004: Operate rollover automation under a multi-session model — session-keyed budget state, per-project locks, hybrid trigger

- Status: accepted
- Date: 2026-08-05
- Deciders: Kashif + Claude Code session (automatic-session-rollover project)

Companion to ADR-0003, which decided *that* the rollover→relaunch pipeline is
automated by a workspace script. This ADR records *how it behaves*: under what
identity model concurrent sessions coexist, who consents to a rollover, and
which runtimes are in scope.

## Context

Three forces surfaced while designing the automation:

1. **The real operating model is multi-session.** One developer runs multiple
   work items concurrently, each with its own main session in the same
   workspace, possibly across different runtimes. The context-budget registry,
   however, was scalar per runtime (`.context-budget/session-<runtime>.json`),
   and `check`/`record` prefer the registry over re-discovery — so session A
   can silently measure session B's artifact. Not theoretical: during the
   design session itself, a `claude --bg` demo clobbered the design session's
   registry entry, and a later `record` reported the dead demo's 47.7K (OK)
   while the real session sat at ~128K (WARN).
2. **Automation needs a consent story.** Fully automatic rollover at every
   threshold surrenders a human decision; asking at every step recreates the
   manual copy-paste burden ADR-0003 removed.
3. **Detection was believed unreliable off Claude Code** (no in-band WARN/STOP
   push), which had kept codex/gemini/opencode/copilot hook work out of scope.
   Live smoke tests (2026-08-05) refuted this: all four ship a usable
   hook/plugin push channel, and `copilot -i` refuted the claim that Copilot
   CLI cannot be launched interactively with a seed prompt.

## Decision

- **Session-keyed budget state.** Registry state lives at
  `.context-budget/sessions/<runtime>-<session-id>.json`
  (`{runtime, artifact, project, registered_at}`); each session writes only
  its own file and resolves itself via runtime env-var identity first. The
  relaunch targets the dying session's own project, read from its own record.
  Successor confirmation = a new session file with the same project and a
  different session-id. Gemini exception: exact counts (shared workspace
  telemetry log) remain single-session-per-workspace; the per-session fallback
  is estimate-only.
- **One *active* session per project**, enforced by an advisory lock
  (`work/<proj>/.active-session`: runtime + session-id + timestamp). The dying
  session releases it after the rollover-verification gate; the successor's
  `register` acquires it; stale locks (artifact untouched for hours) are
  reclaimable.
- **Hybrid trigger: WARN asks, STOP goes.** At WARN the agent finishes the
  work unit and asks; declining arms write-ahead mode (state routed to disk
  incrementally through the WARN→STOP window). At STOP the agent finishes only
  the current atomic step — mid-discussion, that means answering the live
  exchange first — then rolls over without asking. Consent lives in this
  trigger policy alone.
- **Knobs in `context-budget.env`:** `ROLLOVER_RELAUNCH=off|manual|auto`
  (default `manual`) and `ROLLOVER_RUNTIME` (fallback only — the actual
  runtime comes from the dying session's registry record). Workspace-level,
  no per-project override.
- **All five runtimes in scope.** Seeded-interactive relaunch for claude,
  codex, `gemini -i`, `opencode --prompt`, `copilot -i`; detached background
  is claude-only (`--bg`). All four non-claude hook deployments (codex
  `UserPromptSubmit`, gemini `BeforeAgent`, opencode `chat.message` plugin,
  copilot CLI `sessionStart`/`agentStop`) ship with this effort; only VS Code
  agent-mode verification is spun out (needs a Copilot-licensed machine).

## Alternatives considered

- **Global "active project" scalar for relaunch targeting** — rejected:
  breaks with concurrent sessions by construction.
- **Keep the scalar per-runtime registry** — rejected: a live
  wrong-measurement bug under the multi-session operating model (fired the
  day it was designed around).
- **Multi-writer launcher/ledger instead of a per-project lock** — rejected:
  `next-session.md` REPLACE semantics are single-writer by construction;
  concurrent rollovers on one work item would silently destroy each other.
- **A second knobs file (`workspace.env`)** — rejected: its only tenant would
  overlap `context-budget.env`'s domain; create one only when a genuinely
  non-budget knob arrives.
- **Per-project relaunch-policy override** — rejected: the operating model
  varies *sessions* per project, not policy; rollover would behave differently
  depending on which terminal fires first.
- **A second "really launch?" gate at STOP in `auto`** — rejected: recreates
  `manual` inside `auto`.
- **Separate tickets for opencode/copilot hook deployments** — rejected: the
  deferral rationale (CLIs not installed, channels untested) evaporated once
  smoke tests produced working hook/plugin code on live installs.

## Consequences

- Measurement, ownership, and relaunch all hold under N concurrent sessions;
  the clobber bug class is closed by construction (each session writes only
  its own file).
- A lock file appears in every active work directory; stale-lock reclamation
  is a new failure mode to handle (timestamp heuristics, not correctness
  guarantees).
- Gemini keeps a documented second-class tier: concurrent gemini sessions in
  one workspace degrade to estimates.
- `manual` default means every session boundary still gets a human decision;
  teams wanting lights-out succession must opt into `auto` knowingly.
- Write-ahead mode after a declined WARN makes long discussions rollover-safe
  but relies on agent discipline between hooks; hook-less runtimes also need a
  cadence rule (`record` every ~10 exchanges in extended discussions).
- Scope now includes four vendor hook surfaces that move fast; frictions
  already known: copilot folder-trust gate (repo hooks silently no-op in
  untrusted folders), copilot `additionalContext` may be discounted (use
  `agentStop` reason at STOP), codex hash-based hook trust, gemini JSON-only
  stdout, opencode's mandatory message-part shape.

## Provenance

- Promoted from:
  `work/automatic-session-rollover/decisions.md#2026-08-05--multi-session-identity-redesign-approved-session-3`,
  `…#2026-08-05--relaunch-knobs-home-shape-defaults-session-3`,
  `…#2026-08-05--detection--runtime-scope-after-smoke-tests-session-3`
- Refs: ADR-0003 (the companion decision this refines);
  `work/automatic-session-rollover/relaunch-analysis.md` (settled design,
  conductor state machine D1–D8);
  `work/automatic-session-rollover/smoke-test-opencode.md`,
  `…/smoke-test-copilot.md` (live push-channel evidence);
  `work/automatic-session-rollover/issues/01-vscode-agent-mode-hooks.md`
  (spun-out verification ticket)
