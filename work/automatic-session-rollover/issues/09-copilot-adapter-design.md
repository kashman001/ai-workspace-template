# 09 — Copilot measured-tier adapter: design

Type: task (AFK-able; graduated from ticket 07's fog patch)
Status: resolved
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

## Answer

**Decision: the adapter is an in-place extension of `context-budget.sh` —
one new measure path, a copilot branch in `children`, and an agent-id
suffix on child identity. The R4 dispatch-record machinery is reused
verbatim; no new script, no new state files.** Resolved session 25.

### 1. Identity — composite child id, since children have no session

A copilot `task` child has no session of its own (ticket 07): its events
live in the parent's `events.jsonl` keyed `agentId=<task toolCallId>`.
Child identity is therefore the composite `<parentSessionId>+<toolCallId>`
(`+` collides with neither uuid nor `toolu_…` alphabets). It is carried by
the existing `--agent-id` flag: when `register --runtime copilot-cli
--parent-session <sid> --transcript <parent events.jsonl> --agent-id
<toolCallId>` is given, `session_id_for_artifact_only` returns the
composite, so the registry record and lock filename
(`copilot-cli-<sid>+<toolCallId>.json`) are unique per child while
`parent_session_id=<sid>` keeps `parent_chain_holds_lock` walking exactly
as today (claude primary → copilot session child → task grandchild).

### 2. Discovery — `children` grows a copilot-cli branch

Parent artifact = the session's `events.jsonl` (existing
`copilot_cli_discover`, `${COPILOT_HOME:-$HOME/.copilot}` respected).
Children are enumerated two ways, cross-checking each other:

- **events.jsonl scan**: `subagent.started` events → agentId, agentName,
  model; `subagent.completed` marks finished children.
- **sqlite (authoritative)**: `SELECT DISTINCT agent_id FROM
  assistant_usage_events WHERE session_id=? AND initiator='sub-agent'` —
  the hedge for background/`write_agent` children whose event-stream shape
  is unverified: any model request lands here regardless of stream shape.

Output keeps the existing line/exit-code contract: `agent=<toolCallId>
tokens=… status=… type=<agentName>`, `artifact=` pointing at the parent
events.jsonl, worst-child exit code, escalation-only unless `--all`.

### 3. Measurement — context size, not lifetime total

The `check --transcript`-equivalent for one child is
`check --runtime copilot-cli --transcript <parent events.jsonl>
--agent-id <toolCallId>` (flag already parsed; `measure_for` grows an
agent-id-aware copilot path):

- **Primary (`method=exact`)**: last `assistant_usage_events` row for
  (session_id, agent_id): `input_tokens + cache_read_tokens +
  cache_write_tokens` — same last-request input-side semantics as
  `claude_measure`. Mechanics: snapshot `session-store.db` + `-wal`
  (+ `-shm` if present) to a temp dir first (bare .db is 4KB/zero tables;
  also dodges SQLITE_BUSY against the live process); helper
  `copilot_db_snapshot()`.
- **Fallback (`method=estimate`)**: `subagent.completed.totalTokens` from
  events.jsonl — a lifetime input+output sum, over-counts context; good
  enough for a WARN-side signal when sqlite is unavailable. A child with
  neither (still running, no sqlite) is skipped with a note — child
  assistant messages in events.jsonl carry `outputTokens` only, so there
  is no input-side number to read there.
- Bonus: top-level `copilot_cli_measure` (parent self-measure) upgrades to
  sqlite-first (last parent row, `agent_id=''`), keeping today's grep as
  fallback — the current `promptTokens|inputTokens` grep finds nothing in
  events.jsonl and silently degrades to size-estimate.

### 4. Locks — same grant rule, composite filename

Per-child locks reuse `acquire_child_lock` untouched apart from the
composite id in the filename (§1). Note the honest scope: sync `task`
children block their parent, so lock-mediated concurrency matters mainly
for background children (unverified) and for successor-parent audit; it
costs nothing since it is the same code path.

### 5. R4 dispatch records — reused verbatim

Copilot parent flow: `dispatch-open` (emits contract) → embed contract in
the `task` prompt → task runs (parent blocked) → at yield, measure the
child (§3) → `dispatch-close --status <S> --agent-id <toolCallId>`
(stamps provenance into the generation). `ROLLOVER_NEEDED` → gen N+1
re-dispatch, exactly as for claude children. No schema change.

### 6. Escalation topology — the structural difference from claude

A sync `task` blocks the copilot parent, so the parent cannot sweep
mid-flight, and there is no push channel into a running child (ticket 06
closed hook injection generally). The measured tier for copilot children
therefore delivers: (a) **post-hoc** measurement at yield feeding the
dispatch-close / re-dispatch decision, and (b) **external observation** —
a watcher in another session tailing events.jsonl / polling the sqlite
snapshot (a `watch`-variant is a possible later slice, not required).
In-flight discipline remains the dispatch contract's report-file
checkpoints. Thresholds: existing THRESHOLD/WARN apply per child;
per-role overrides await ticket 08.

### 7. Build prerequisites and caveats (carried from ticket 07)

- Never assume child agent type or model (run 1 general-purpose/gpt-5.4
  vs run 2 Explore/haiku); measurement is token-count based so model does
  not matter, but `type=` labels come from `subagent.started.agentName`.
- **Slice 0 of any build is a probe** replaying ticket 07's method for
  `mode: background` and `write_agent` children before trusting the
  events.jsonl leg; the sqlite leg is expected to hold regardless.
- Task display name surfaces only in
  `tool.execution_complete.toolTelemetry.restrictedProperties.agent_id`
  (cosmetic).

### Rejected alternatives

- **Standalone adapter script** — rejected: threshold/exit-code/resolve
  plumbing already lives in `context-budget.sh`; a second entry point
  drifts.
- **`subagent.completed.totalTokens` as the primary measure** — rejected:
  lifetime input+output sum, not context size; grows with every request
  and over-alarms. Kept as estimate fallback only.
- **`--share` export as data source** — rejected (ticket 07: no usage
  data).
- **Tail events.jsonl for live child context** — rejected as primary: the
  input side of child requests exists only in the sqlite rows.
- **Registering children under the parent's bare session id** — rejected:
  registry/lock filenames are `$RUNTIME-$SESSION_ID.json`; all children of
  one session would collide.

**Building it is execution work, out of this map's scope** — recorded as a
template-backlog row (build unscheduled; schedule with the user).
