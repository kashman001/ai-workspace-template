# Decisions — runtime-session-identity

Tier-2 decision notes (skills/decision-log/SKILL.md). Newest last.

## 2026-10-12 — remaining-surface probes are a wave-3 hitl node

Antigravity IDE/app and Codex desktop app probes went into plan 01 as hitl node 11 (wave 3),
not ahead of wave 1, so the refuse-instead-of-guess and adapter fixes run hands-off.
Rejected: gating the whole plan on them. The VS Code results already settled node 5
(no pid-walk), and those probes can only add follow-up nodes.

## 2026-10-12 — ambiguous discovery refuses on every command, not only register

When discovery has no id var and finds more than one live transcript for the cwd,
`check`, `record` and `register` all exit 4 with `reason=ambiguous_artifact`.
Rejected: refuse on `register` only and warn on reads (the old copilot-vscode rule). That
rule was dead code anyway: its flag was set inside a `$(...)` subshell and never reached
`resolve_session`. A read of a sibling's transcript still gives a false STOP. Node 10
(`record` without the env id) is how an agent shell gets a non-ambiguous read.

## 2026-10-12 — the Copilot CLI hook config owns every Copilot payload

One Copilot turn fires `.github/hooks/context-budget.json`, the VS Code hook file and
`.claude/settings.json`. A payload whose transcript is `*/session-state/<sid>/events.jsonl`
is ignored by the `claude` row always, and by the `copilot-vscode` row while the CLI config
is installed; the `copilot` row (measured as copilot-cli) acts. The Claude SessionStart hook
now registers only when the payload carries `transcript_path` (Copilot's never does).
Rejected: the VS Code config owning it. Agent-side detection already resolves copilot-cli
whenever `COPILOT_AGENT_SESSION_ID` is set, so hook stamps and agent records agree, and the
VS Code row has no SIGTERM turn-end. Node 06, commit 133f763.

## 2026-10-12 — hook-registering rows register on any non-check event

For a `register=hook` row, an event that is neither the check nor the turn-end hook now
registers and stays silent (codex SessionStart, copilot sessionStart, antigravity
PreInvocation). The codex row pins `CODEX_THREAD_ID=sid` so the payload id beats an
inherited env id. Antigravity registers on every `PreInvocation` until its record exists
rather than only on `invocationNum == 0`. Rejected: per-runtime first-event checks; a missed
first firing heals on the next. Nodes 03 (1f8f4e5) and 07 (a7e2da5).

## 2026-10-12 — COPILOT_STATE_DIR stays an override above COPILOT_HOME

Transcript root is `${COPILOT_STATE_DIR:-${COPILOT_HOME:-~/.copilot}/session-state}`.
Rejected: dropping `COPILOT_STATE_DIR`; the hooks suite's byte-for-byte fixtures set it and
removing it changes fixtures with no behaviour gain. Node 04, commit d811946.

## 2026-10-12 — Hook context message does not add a session-id field (node 10)

An agent shell with no id var finds its own record by the runtime's env id
(ANTIGRAVITY_CONVERSATION_ID, COPILOT_AGENT_SESSION_ID, CODEX_THREAD_ID); Claude, which has
none, refuses as ambiguous and names `record --session-id`, and its SessionStart context line
already prints `artifact=<…>/<session-id>.jsonl`. Rejected: an explicit id field in every hook
payload — it rewrites 14 byte-for-byte fixtures in `test-vendor-budget-hooks.sh` (a payload
contract change) for an id the agent can already read. Node 10, commit c367404.

## 2026-10-12 — Phantom records are deleted after a fixed 60-min grace (node 09)

`prune_phantoms` (in `register`/`record`) deletes a non-own registry record whose artifact is
missing — recorded path absent and the claude id-keyed glob finds nothing — once the record
file is >60 min old. Artifact existence only, never the pid. Rejected: hiding phantoms in every
reader (check/attach-session/fleet) — more surface for the same outcome; and a configurable
grace — no caller needs it. Cost: a pre-spawned session first used >1h later re-registers.
Node 09, commits 79c5a6a, 769f54b (space-safe loop).

## 2026-10-12 — Antigravity IDE/app and Codex desktop probes deferred (node 11-remaining-surface-probes)

User call: no time now; kept as template backlog card L86 instead of blocking wave 3. Rejected:
holding the plan open on the hitl node. The probe clone stays until L86 is run.

## 2026-10-12 — Claude SessionEnd needs transcript_path, like SessionStart (node 15)

Without a payload `transcript_path`, the SessionEnd hook exits and runs no `release`. Rejected:
refusing inside `cmd_release`. Other callers (the agent, scripts) use release without
`--transcript`, and the risk sits only in the hook payload path. Commit 0b4dd7c, hooks K1g.

## 2026-10-12 — Copilot-cli discovery does not guess among current-format transcripts (node 15)

With no runtime id and no cwd match in `session-state/*/events.jsonl`, discovery fails ("no
session artifact"). Only the legacy `history-session-state/` keeps newest-mtime. Rejected:
newest-mtime over `session-state/`, which binds another project's live session (findings.md
gap 4). The agent shell also now honours `COPILOT_STATE_DIR`, applying the earlier note above.
Commits 0d581ce and 0964a23, registry U1 and U2.
