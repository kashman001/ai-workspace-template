# 03 — Session roles per work item (primary / auxiliary / superseded)

Status: resolved 2026-08-06 (core session 15; slice-1 items sessions 16–17;
only the user-deprioritized listing/display items remain deferred) · raised
2026-08-06 (session 15, lock-lifecycle discussion with user)

## The model (decided with the user, 2026-08-06)

One **primary** session per work item; the lock is the marker.

- **primary** — holder of `work/<proj>/.active-session`; sole writer of the
  launcher/ledger/`.rollover-options`, sole rollover authority. A session is
  primary iff the lock carries its identity; on conflict the lock beats any
  cached `role` claim in a registry record.
- **auxiliary** — concurrent helper registered against the item while a live
  primary holds the lock. Associated + measured, never contends for the
  lock, must not write launcher/ledger or roll the item over.
- **superseded** — former primary after rollover; terminal state, distinct
  from auxiliary so a dead predecessor is never mistaken for a usable
  helper. Chosen terminology over primary/secondary/retired ("secondary"
  reads as backup-primary) and main/helper/handed-off.

"Latest session becomes primary" is emergent, not a mechanism: the launcher
releases the dying primary's lock pre-launch (M14) and the successor's
`register` acquires it.

## Shipped (core, session 15)

- `context-budget.sh register --project`: acquiring → `role=primary`; live
  foreign holder → `role=auxiliary` (association now persisted instead of
  dropped). Role stored in the session registry record; `register` prints
  `role=` in-band. Tests T6 (registry suite).
- `launch-next-session.sh`: stamps the dying record `role=superseded` +
  `superseded_at` alongside the pre-launch lock release (identity-matched;
  never on `--dry-run`). Tests T20 (launcher suite).
- `attach-session.sh`: status line gains `role=` (lock authoritative, record
  fallback). Tests T7 (attach suite).
- `SessionEnd` hook (`.claude/settings.json.example` + live copy): runs
  `release --transcript <own>` on exit, so a plainly-closed primary frees
  its lock; identity-matched, so non-holders no-op. Claude-only (other
  runtimes have no end hook; their backstop stays stale-reclaim).
- Claude Code status line `scripts/statusline-context-budget.sh`:
  `PRIMARY · <project> · <pct>%` from registry + lock + newest own ledger
  entry — never reads the transcript (statusline refreshes often; live
  measurement stays with `record`). Tests: statusline suite (8 asserts).
- Docs: `context-budget.md` → "Session roles"; work-directory-conventions →
  "One primary session per work item".

## Shipped with implementation slice 1 (sessions 16–17, 2026-08-06)

- **`superseded_by` back-link** — successor-side back-stamp at `register`:
  on primary acquisition, the newest same-project `role=superseded` record
  without a `superseded_by` gets `superseded_by=<runtime>-<sid>`. Test T13
  (registry suite).
- **`--takeover` flag** — explicit *recorded* steal at `register`; wins even
  against a live holder (human authority); old holder's record stamped
  `superseded` + `superseded_at` + `superseded_by`. Test T14.
- **Convergence** — role set extended (not forked) with `child`:
  parent-side artifact-keyed registration, `parent_session_id`/`depth`/
  `agent_id`, per-child locks in `work/<p>/.agent-locks/`, transitive
  parent-chain validation, I4 release-order guard with stale sweep. Tests
  T7–T12; decision note in `decisions.md` (session 16).

## Still deferred

- **`sessions` listing subcommand** and **terminal-tab-title display via the
  five-runtime hook layer** — user deprioritized both (chose in-band +
  claude statusline).
