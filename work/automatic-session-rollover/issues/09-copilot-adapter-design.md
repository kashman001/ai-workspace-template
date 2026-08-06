# 09 — Copilot measured-tier adapter: design

Type: task (AFK-able; graduated from ticket 07's fog patch)
Status: open
Blocked by: none
Map: ../map.md

## Question

Ticket 07 verified copilot per-child artifacts (session-scoped
`events.jsonl` with `agentId=<toolCallId>`-tagged child events +
`session-store.db::assistant_usage_events` per-request token rows). Design
the adapter: child discovery, `check --transcript`-equivalent token
measurement, and per-child locks for copilot children — reusing the R4
dispatch-record machinery where possible.

Constraints: don't assume child model or event-stream shape for
background/`write_agent` children (unverified — probe before relying);
SQLite reads must copy the `-wal` sidecar; artifact facts + adapter sketch
live in `../research/07-copilot-child-artifacts.md` (gen-2 VERDICT section).
