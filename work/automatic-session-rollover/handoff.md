<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->


# Session Handoff — 2026-08-06 (session 15: issue-02 approval ladder + issue-03 session roles; STOP rollover at 177K)

**What shipped (committed on `main`, pushed through `e7d9f10` — work done in
worktree `issue-02-permission-mode-auto`, pushed to origin/main; the LOCAL
main checkout is BEHIND until pulled):**

- **`ad16eb0` — issue 02 resolved (approval ladder):** `ROLLOVER_OPT_APPROVAL`
  is now `default < edits < auto < full`; `auto` re-pointed to the classifier
  tier (claude `--permission-mode auto`, verified live `--help` 2.1.223,
  ADR-0003), `edits` carries the old acceptEdits-tier mappings; non-classifier
  runtimes fall back to `edits` + stderr note. User decisions: option-2
  spelling (agent-agnostic capability ladder), nearest-level fallback, this
  item switches `full`→`auto` (machine-local `.rollover-options` updated
  live). Tests T14a–p; backlog **L19**; issue file + `decisions.md` updated.
- **`e7d9f10` — issue 03 core (session roles, from lock-lifecycle discussion
  with user):** roles **primary / auxiliary / superseded**, lock =
  authoritative primary marker; `register` records + prints `role=`
  (auxiliary association persisted); launcher stamps `superseded` at
  pre-launch release; `attach-session.sh` prints `role=`; **SessionEnd hook**
  releases the lock on plain exit (own-transcript identity);
  `scripts/statusline-context-budget.sh` (new) shows
  `PRIMARY · <project> · <pct>%`. Docs: `context-budget.md` "Session roles",
  work-directory-conventions "One primary session". Tests: registry T6,
  launcher T20, attach T7, statusline suite — 19+58+22+8+37 green. Backlog
  **L20**; deferred items (superseded_by back-link, --takeover, sessions
  listing, tab-title) in `issues/03-session-roles.md`; `decisions.md` note
  (promote-candidate when slice 1 lands).
- **Machine-local (not in git):** live `.claude/settings.json` gained the
  SessionEnd hook + statusLine wiring; statusline live-verified
  (`PRIMARY · automatic-session-rollover · 65%`). Live settings now reference
  `scripts/statusline-context-budget.sh`, which exists in the main checkout
  only after `git pull`.
- **M14 fix verified live** at this session's bootstrap (session-14's parked
  learning, closed): first auto-relaunch successor acquired the lock cleanly.
- Doc review of `subagent-rollover-research.html` remained with the user all
  session; untouched.

**Learnings:** *(parked; promote on second strike)*
- Worktree-isolated sessions push tracked work to origin/main while the MAIN
  checkout stays behind and holds all runtime state (registry, locks, ledger,
  live settings) — successor launches and live-settings references break
  until the main checkout pulls. This rollover's launcher carries the pull as
  a first action; if it bites again, route to operational-knowledge.md.

**Rollover:** STOP fired at 177K on the `record` immediately after issue-03
shipped; atomic step was complete. Auto-relaunch deliberately NOT invoked
from the worktree (would seed a successor with divergent runtime state);
user pulls main checkout, then launches.

# Session Handoff — 2026-08-06 (session 14: M14 lock-release fix + runtime-state gitignore; WARN rollover at ~123K)

**What shipped (committed on `main`, pushed through `bc3fab3`):**

- **`c45969d` — M14 lock-release-before-launch fix** (fired live at this
  session's own bootstrap: predecessor's `.active-session` lock survived the
  auto-relaunch; successor's `register` refused, `LOCK_STALE=3h` gave no
  reclaim). `launch-next-session.sh` now releases the dying session's own
  lock — identity-matched via its registry record, foreign holders never
  removed — before every launch path; `--dry-run` inert; `mode=off` included.
  Skill + `docs/context-budget.md` reworded to release-before-launch (manual
  `release` kept as no-script fallback). Tests T16–T19 (suite: 49 asserts).
  Backlog **M14** opened+resolved; **L18** opened (env-file sourcing guard
  keyed on `CONTEXT_DUMB_ZONE_TOKENS` clobbers other knob overrides).
  Decision note (rejected: skill reordering only / successor retry /
  successor-side steal) in `decisions.md`.
- **`bc3fab3` — runtime-state gitignore** (user-requested architecture
  review): untracked `work/*/.active-session` +
  `work/context-decay/context-ledger.jsonl`, pre-ignored
  `work/*/.rollover-options`. Rule codified — commit what a future session
  must read; ignore live-session state — in `.gitignore` comments,
  `docs/context-budget.md`, `docs/work-directory-conventions.md` ("Tracked
  vs. untracked"). Working tree now genuinely clean between sessions.
- User review of `subagent-rollover-research.html` continued in background;
  one model question answered in-conversation (multiple parallel subagent
  sessions under one main session — already covered: parent-only project
  lock, per-child locks, R5, S13/S35/S36; no doc change needed).

**Learnings:** *(parked; promote on second strike)*
- This session's own bootstrap was the first live exercise of auto-relaunch
  succession; the next successor's clean lock acquisition is the fix's first
  real verification — check `register` output at bootstrap.
