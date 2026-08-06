# 07 — Where does Copilot CLI persist per-child (task) artifacts?

Type: research (AFK)
Status: open (gen 1 yielded ROLLOVER_NEEDED at its own WARN — no verdict
yet; report checkpointed at `../research/07-copilot-child-artifacts.md`,
self-contained for gen 2; dispatch record
`.agent-dispatch/07-copilot-artifacts.json`. Next session: `dispatch-open`
gen 2, agent starts at the report's open item 1)
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
