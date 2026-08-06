# Decisions — automatic-session-rollover

Tier-2 decision notes, newest last. Format: `skills/decision-log/SKILL.md`.

## 2026-08-05 — Automate the rollover→relaunch pipeline (the effort itself)
**Chose:** A workspace-owned script (`scripts/launch-next-session.sh`) that
bakes the canonical bootstrap prompt in verbatim and launches a fresh runtime
session seeded with it, governed by workspace parameters offering a
consent-gated mode (agent asks, then launches and continues) and a fully
automatic mode (WARN/STOP triggers rollover + relaunch unprompted).
Interactive seeded launch is the agent-agnostic core; detached background
launch is a claude-only tier.
**Because:** Stage 3 of the rollover pipeline (relaunch) is a manual
copy-paste today, and the prompt wording is load-bearing — hand-typed looser
phrasings make the new session summarize-and-wait instead of execute. Keeping
disk (launcher + ledger) as the source of truth means any runtime can pick the
work up; the script only accelerates the launch.
**Rejected:** upstream `claude-handoff` wholesale — its content rules already
landed via the inlined hand-off contract; its prompt-only background-handoff
mechanism — loses disk-as-source-of-truth and is Claude-only; nohup+yolo
background emulation for codex/gemini — trades permission safety for symmetry;
inlining vendor launch commands in the `session-rollover` skill — violates the
CLI-first rule (vendor specifics live only in scripts).
**Blast radius:** `scripts/launch-next-session.sh` (new),
`context-budget.env`, `skills/session-rollover/SKILL.md` (closing step),
`docs/context-budget.md`, `docs/workspace-structure.md`.
**Promote?:** done → ADR-0003

## 2026-08-05 — Multi-session identity redesign (approved, session 3)
**Chose:** Session-keyed registry state
(`.context-budget/sessions/<runtime>-<session-id>.json`, each session writes
only its own file; resolve-self via runtime env-var identity first) plus one
*active* session per project enforced by an advisory lock
(`work/<proj>/.active-session`; dying session releases after the D5
verification gate, successor's register acquires, stale locks reclaimable).
Gemini exception documented (exact counts are single-session-per-workspace;
per-session fallback is estimate-only). D8 restated: successor confirmed =
new session file with same project + different session-id.
**Because:** The operating model is one developer running multiple
projects/work items concurrently, each with its own main session — and the
scalar per-runtime registry (`session-<runtime>.json`) is a live bug under
that model: `check`/`record` prefer the registry over re-discovery, so
session A measures session B's artifact (fired live 2026-08-05 when the
`--bg` demo clobbered the design session's registry entry).
**Rejected:** keeping a global "active project" scalar — breaks with
concurrent sessions by construction; making the launcher/ledger backbone
multi-writer instead of locking — REPLACE semantics on `next-session.md` are
single-writer by construction, and concurrent rollovers on one work item
would silently destroy each other.
**Blast radius:** `scripts/context-budget.sh` (register/check/record/resolve),
`.context-budget/` layout, `work/*/.active-session` (new),
`docs/context-budget.md`, `skills/session-rollover/SKILL.md` (D5/D8 gates).
**Promote?:** done → ADR-0004

## 2026-08-05 — Relaunch knobs: home, shape, defaults (session 3)
**Chose:** `ROLLOVER_RELAUNCH=off|manual|auto` + `ROLLOVER_RUNTIME` in
`context-budget.env`, workspace-level. Default `manual` (consent-gated: agent
asks at rollover, then runs `launch-next-session.sh` itself). `off` = today's
paste-prompt behavior; `auto` = STOP background-launches the successor
unprompted where supported (claude; falls back to manual elsewhere), WARN
still asks per the hybrid. `ROLLOVER_RUNTIME` is only a fallback default —
the actual relaunch runtime comes from the dying session's own registry
record (codex session → codex successor).
**Because:** The knobs govern behavior at a context-budget threshold and are
consumed by the same actors that read WARN/STOP — `context-budget.env` is
already the checked-in home for those. `manual` as default exercises the full
pipeline while keeping a human decision at every session boundary. Consent
lives in the *trigger* policy (WARN asks / STOP goes), not a separate
per-launch confirmation.
**Rejected:** a new `workspace.env` — second knobs file whose only tenant
overlaps the first's domain; create it only when a genuinely non-budget knob
arrives. Per-project knob override — the multi-session operating model varies
*sessions* per project, not relaunch policy; per-project policy would make
rollover behave differently depending on which terminal fires first. A second
"really launch?" gate at STOP in `auto` — recreates `manual` inside `auto`.
**Blast radius:** `context-budget.env`, `scripts/launch-next-session.sh`,
`skills/session-rollover/SKILL.md` (closing step), `docs/context-budget.md`.
**Promote?:** done → ADR-0004 (this note keeps the defaults' fuller rationale).

## 2026-08-05 — Detection + runtime scope after smoke tests (session 3)
**Chose:** All four hook deployments (codex `UserPromptSubmit`, gemini
`BeforeAgent`, opencode `chat.message` plugin, copilot CLI
`sessionStart`/`agentStop`) IN SCOPE for this project; the only spun-out
ticket is VS Code agent-mode hook verification (+ `copilot_vscode_measure`)
on a Copilot-licensed machine. Launcher covers all five runtimes with seeded
interactive (`claude`, `codex`, `gemini -i`, `opencode --prompt`,
`copilot -i`); detached background stays claude-only (`--bg`); opencode
serve/attach noted as a possible future tier, not v1. Cadence rule shrinks
to a fallback note for hook-less environments.
**Because:** Smoke tests (`smoke-test-opencode.md`, `smoke-test-copilot.md`)
confirmed the push channels LIVE on real installs and produced working
hook/plugin code, collapsing the deployment cost that justified deferral;
`copilot -i` refuted the headless-only claim that had excluded copilot from
the launcher; opencode's sqlite artifact makes it the easiest runtime to
measure.
**Rejected:** separate tickets for opencode/copilot CLI hooks — their
rationale (CLI not installed, channel untested) no longer holds; excluding
copilot from the launcher — based on a refuted docs claim; including VS Code
agent-mode verification in scope — impossible on this machine (no Copilot
extension/license) and Preview-status contract may shift.
**Blast radius:** `scripts/launch-next-session.sh` (5 runtimes),
`.codex/config.toml`, `.gemini/settings.json`, `.opencode/plugins/`,
`.github/hooks/`, `docs/context-budget.md`, a new ticket for VS Code
verification.
**Promote?:** done → ADR-0004
