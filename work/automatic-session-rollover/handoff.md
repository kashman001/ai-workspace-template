<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->


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

# Session Handoff — 2026-08-06 (session 13: scenario catalog + parent positions + learnings rules; WARN rollover at ~125K)

**What shipped (committed on `main`, pushed):**

- **`967b3d2` — scenario catalog S11–S54:** new `rollover-scenarios.md`
  (authoritative; nine dimension groups, each scenario with pass criteria),
  mirrored as HTML §7. Answered the user's open question: five missing
  dimensions added (concurrency/contention, vendor heterogeneity,
  human-in-the-loop policy, observability/auditability,
  evolution/compatibility); cost folds into performance.
- **`5d2f75d` — root vs intermediate parent positions** (user review finding):
  HTML §2.2 + research-md §3 subsection — parent *role* is
  position-invariant; the node's own lifecycle differs by position (delta
  table: manager, rollover path, measurement, escalation, authority, lock,
  recovery owner). No parent-type field — `depth`/`parent_session_id`
  suffice. Scenarios S53 (BLOCKED bubbles L2→L1→root) and S54 (intermediate
  parent rolls itself: drain own children, then yield) added; HTML §2.3–2.9
  renumbered.
- **`536fd9c` — learnings-capture rules** (user retro discussion): rollover
  skill Reflect step now says capture at incident time + park uncertain
  observations as `Learnings:` ledger lines + second-strike promotion;
  checkpoint skill points the human retro at checkpoint/successor-start.
  Backlog changelog row added. Deliberately no learnings.md, no auto-retro.
- This rollover commit: decisions.md notes (catalog placement; parent
  positions as node position, not type enum), ledger restructure.

**Learnings:** *(parked; promote on second strike)*
- Blind sed renumbering of doc section numbers also matched CSS (`2.6em`)
  and version strings (`0.142.4`) — pattern-guard (`§`, `secno">`, TOC text)
  and a pre-grep of all `2.x` occurrences avoided corruption.
- A ~15-line python `html.parser` tag-balance + id-dedup + secno-order check
  before committing hand-edited HTML is cheap, reusable pre-commit insurance.

**Rollover:** WARN fired at 122K mid-edit; finished the parent-positions and
learnings units cleanly; user then asked to close the learnings thread and
roll over. First rollover of this work item triggered below STOP.

