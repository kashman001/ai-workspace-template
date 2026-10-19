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

## 2026-10-18 — One registry name per Copilot session: copilot-cli (node 03) — PROPOSED, awaiting the user (plan 02 node 05)

On the Copilot CLI runtime (VS Code agent mode included), every Copilot chat gets a
`copilot-cli-<sid>.json` record from the CLI hook config (`scripts/hooks/context-budget-hook.sh`
auto-register, ~:139). A second record, `copilot-vscode-<sid>.json` with the same `events.jsonl`,
appears only when an agent runs `register --runtime copilot-vscode` by hand (the probe's
`probe-env.sh`, registry test H2). The VS Code hook config writes nothing: its `SessionStart` has no
`transcript_path`, and its `Stop` stands down while the CLI config is installed (hook ~:60-66).
Auto-detection already says copilot-cli when `COPILOT_AGENT_SESSION_ID` is set (`detect_runtime`).
Measured in a sandbox: the twin does not affect the ambiguity refusal (the glob is runtime-prefixed),
pruning (the twins go together), auto `check` or the Claude-only status line. It does split
work-item ownership: an item bound under `copilot-vscode-<sid>` refuses the same chat's later auto
`register` with `owner_live`. And `record` keeps only its own twin fresh. Only the env var
`AI_AGENT=github_copilot_vscode_agent` tells VS Code from terminal Copilot; payloads are the same on
both surfaces, and `TERM_PROGRAM` / `__CFBundleIdentifier` are not reliable.

Options: (a) accept it and document "don't pass `--runtime copilot-vscode` on the CLI runtime";
(b) canonicalise: a copilot-vscode resolution whose artifact is `*/session-state/<sid>/events.jsonl`
(or with `COPILOT_AGENT_SESSION_ID` set) becomes copilot-cli, so every path keys one record; keep the
surface, if ever needed, as an optional `surface` field from `AI_AGENT`; (c) dedupe by session id
across runtimes; (d) make copilot-vscode the canonical name via `AI_AGENT`.

Recommendation: (b). One guard in one place, removes the ownership split at its source, and matches
the earlier note that the Copilot CLI hook config owns every Copilot payload. Update `probe-env.sh`
and test H2 to expect `copilot-cli-<sid>`. Depends on node 02: if Copilot events move to the VS Code
hook config, the canonical name flips, but the rule stays: one name, the owning hook row's `measure_as`.

Rejected: (a) leaves a trap a documented flag walks into, and its refusal looks like a live sibling.
(c) every reader keys `$RUNTIME-$SID`, so dedupe touches all of them to fix what one name prevents.
(d) contradicts the ownership decision, needs `AI_AGENT` (absent from hook payloads, undocumented by
the vendor), and would rename the CLI row's hook stamps too.

Side gap seen: `--runtime copilot-vscode` with no id var dies "no session artifact" (rc 3) on the CLI
runtime — its discovery only looks in workspaceStorage `chatSessions`. Evidence: node 03 Log;
sandbox `scratchpad/n03/sandbox.sh` (session-local, not kept).
