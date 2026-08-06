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

## 2026-08-05 — Promote the session-3 cluster as ONE companion ADR (session 4)
**Chose:** A single companion ADR-0004 ("multi-session model, trigger policy,
knobs, runtime scope") in the ADR-0003 family, with all three session-3 notes
in its Provenance block and a "Refined by" forward link added to ADR-0003.
**Because:** The three notes describe one coherent behavioral model (how the
ADR-0003 automation behaves), and accepted ADRs should stay immutable —
supersede/companion, don't rewrite.
**Rejected:** amending ADR-0003 in place — substantially rewriting an accepted
ADR breaks record immutability; four separate ADRs — ceremony without a fork
per document, and the launcher explicitly capped promotion at one.
**Blast radius:** `docs/adr/0004-multi-session-rollover-model.md` (new),
`docs/adr/0003-*.md` (one Refined-by line), `docs/adr/README.md` index.
**Promote?:** no — it *is* the promotion record.

## 2026-08-05 — Session-id derivation: env-first, artifact-derived fallback (item #1)
**Chose:** `session_id_for()` resolves identity from the runtime's own env var
first (`CLAUDE_CODE_SESSION_ID`, `CODEX_THREAD_ID`, `COPILOT_AGENT_SESSION_ID`,
`VSCODE_TARGET_SESSION_LOG` basename), else derives the same id from the
artifact path (transcript basename / rollout UUID suffix / session-state dir).
Gemini gets the fixed id `workspace`.
**Because:** the same session must map to the same registry file whether or not
the env var is present, or one session grows two files and resolve-self breaks.
Gemini exports no per-session identity — the fixed id *is* the documented
single-session-per-workspace exception.
**Rejected:** mtime-heuristic keying (still races — identity is the only
reliable key); refusing to register without an env var (kills the fallback
runtimes entirely).

## 2026-08-05 — Advisory lock warns, never blocks measurement (item #1)
**Chose:** `register --project` finding the lock held by a live session warns
and skips acquisition but still registers and emits the check; `release` only
ever removes a lock held by self. Staleness = holder artifact untouched >
`CONTEXT_LOCK_STALE_SECS` (default 3h, in context-budget.env).
**Because:** hard-failing register would kill budget tracking for exactly the
session that most needs measuring; enforcement is the agent honoring the
warning before single-writer launcher/ledger writes.
**Rejected:** hard-fail register on held lock; lock-free multi-writer
launcher/ledger (REPLACE semantics are single-writer by construction).

## 2026-08-05 — Gemini concurrent guard: freshness heuristic on the shared log (item #1)
**Chose:** at gemini register, a non-empty telemetry log modified <10 min ago
is treated as another live session's — skip the reset, register against the
newest chat log (estimate-only), warn.
**Because:** register is a session-start action, so a fresh own-session log
cannot exist yet; freshness is the only signal gemini offers (no session id).
**Rejected:** always-reset (corrupts the live session's exact counts);
per-session telemetry filtering (nothing to filter on).

## 2026-08-05 — TTY guard for attached relaunch (item #2)
**Chose:** `launch-next-session.sh` in manual mode `exec`s the runtime only
when stdin+stdout are a terminal; otherwise it prints the ready-to-run
command (`run: …`) and exits 0.
**Because:** the agent invokes the script from a non-tty tool shell — exec'ing
a TUI there hangs; relaunch-analysis already prescribed "print the
ready-to-run command (others)" for that case.
**Rejected:** always exec (hangs agent shells); refusing to run outside a tty
(loses the paste-me fallback).

## 2026-08-05 — copilot-vscode degrades to prompt-only (item #2)
**Chose:** runtime `copilot-vscode` prints the bootstrap prompt with a warning
and exits 0 — no launch attempted.
**Because:** VS Code agent mode has no CLI seeded launch; verification is spun
out (issues/01-vscode-agent-mode-hooks.md); the dying session still needs the
prompt emitted for the user to paste.
**Rejected:** hard error (kills the rollover's paste-me fallback).

## 2026-08-05 — D8 successor confirmation only after --bg launches (item #2)
**Chose:** after a `--bg` launch, poll `.context-budget/sessions/` for a file
absent before launch with matching project and a different session-id;
timeout `ROLLOVER_CONFIRM_SECS` (default 120s), non-fatal
(`successor=unconfirmed` + advice).
**Because:** attached launches occupy the terminal — nothing to poll from; a
confirmation timeout must not fail an otherwise-complete rollover.
**Rejected:** mandatory confirmation on all launch paths.

## 2026-08-05 — Bootstrap prompt block always prints first (item #2)
**Chose:** every mode (including error-free `off` and dry runs) prints the
verbatim bootstrap prompt block before any launch logic.
**Because:** the paste-me fallback must survive any launch failure; the script
is the single source of the load-bearing wording (ADR-0003).
**Rejected:** printing it only in `off` mode.
