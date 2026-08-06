# 07 — Where does Copilot CLI persist per-child (task) artifacts?

Type: research (AFK)
Status: resolved (session 24, 2026-08-06; gen 2 DONE_WITH_CONCERNS)
Blocked by: none
Map: ../map.md

## Question

Copilot CLI task IDs are live-confirmed but the per-child artifact
location is undetermined (research §11 measured tier;
`smoke-test-copilot.md`, copilot 1.0.78 installed locally). Before a
copilot measured-tier adapter (child discovery + `check --transcript` +
per-child locks) can be planned: do copilot subagent/task runs persist
transcripts or usage artifacts on disk at all — and if so, where, in what
format, and keyed how (task id? session id?)?

- **Findable + parseable** → the adapter fog patch graduates to a design
  ticket.
- **No on-disk artifacts** → copilot children stay contract-tier only
  (like codex/gemini); record the refutation and close the fog patch.

Method: probe `~/.copilot/` (history-session-state, logs) after a `-p` run
that spawns a task; check `--share`/`--output-format json` output for
per-task usage; consult official docs only for corroboration — live
verification wins (workspace verify-against-live-help rule).

## Answer

**Findable + parseable — the copilot measured-tier adapter is buildable**
(gen-2 live probes on copilot 1.0.78; full evidence + adapter sketch in
`../research/07-copilot-child-artifacts.md` [gen 2] blocks + VERDICT):

- Children get NO session dir of their own; artifacts are keyed by the
  parent's `task` toolCallId, in two places:
  1. `~/.copilot/session-state/<sessionId>/events.jsonl` — full child
     transcript tagged `agentId=<toolCallId>`; `subagent.completed` carries
     `totalTokens` (cross-checked exactly vs `session.shutdown.modelMetrics`).
  2. `~/.copilot/session-store.db` (SQLite; copy the `-wal` sidecar) table
     `assistant_usage_events` — per-request token rows with `agent_id`,
     `initiator='sub-agent'`, full token split.
- Adapter caveats: subagent model varies per run (don't assume); background
  (`mode: background`) tasks and `write_agent` children assumed same event
  stream, unverified; task *name* only surfaces in
  `tool.execution_complete.toolTelemetry.restrictedProperties.agent_id`.
- Fog patch graduates: copilot-adapter design is now specifiable →
  charted as ticket 09.
