# 03 — Session roles per work item (primary / auxiliary / superseded)

Status: core resolved 2026-08-06 (session 15) · raised 2026-08-06 (session 15,
lock-lifecycle discussion with user)

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

## Deferred (revisit with implementation slice 1 — parent/child registry)

- **`superseded_by` back-link** — the launcher can't know the successor's
  session id at stamp time (the runtime generates it); a successor-side
  back-stamp at `register` could complete the chain. Time-ordered records
  per project suffice for now.
- **`--takeover` flag** — explicit reclaim for a dead-holder-within-stale
  window; rare once SessionEnd release exists (crash-only), and the env
  override path is blocked by backlog L18 anyway.
- **`sessions` listing subcommand** and **terminal-tab-title display via the
  five-runtime hook layer** — user deprioritized both (chose in-band +
  claude statusline).
- **Convergence:** child sessions in the subagent-rollover design are
  structured auxiliaries (`parent_session_id`/`depth`, per-child locks,
  release-order guard R4/R5); the role field should extend, not fork, when
  that slice lands.
