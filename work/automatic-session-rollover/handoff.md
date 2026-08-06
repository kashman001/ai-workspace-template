<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->


# Session Handoff — 2026-08-06 (session 16: statusline chaining fix + slice-1 cycles 1–3; STOP rollover at 152K)

**What shipped (committed and pushed to `origin/main` through `4c6569e`; work
done in worktree `slice-1-registry-schema` — main checkout BEHIND until
pulled):**

- **`3f97027` — L21 statusline chaining fix (user report, mid-session):** the
  L20 project-level statusLine had replaced the user's global `ccstatusline`
  bar and printed `no work item` for unregistered sessions.
  `statusline-context-budget.sh` now re-runs the global `statusLine.command`
  from `~/.claude/settings.json` with the same stdin (output first, budget
  segment appended only on a work item, recursion-guarded). Tests T7a–f
  (statusline suite 14). Backlog L21 opened+resolved.
- **`4c6569e` — slice 1 cycles 1–3 (R4/R5 partial):** `register
  --parent-session/--agent-id` → artifact-keyed child records with
  `parent_session_id`/`depth`; role extends to `child`; per-child locks in
  `work/<p>/.agent-locks/` with transitive parent-chain validation;
  `release` sweeps stale child locks and enforces bottom-up order (I4, die
  exit 3). Tests T7–T12 (registry suite 45; all 5 suites green).
  Design + remaining work: `plans/slice-1-registry-schema.md`.
- Decisions routed to `decisions.md` (artifact-keyed child identity, role
  `child`, lock filename, liveness placement). Worktree/main-checkout
  runtime-state divergence promoted to `docs/operational-knowledge.md`
  (second strike).

**Not done (successor picks up):** T13 `superseded_by` back-stamp, T14
`--takeover`, docs (`context-budget.md`), issues/03 + backlog card +
scenario-catalog notes — all enumerated in the plan file.

**Rollover:** STOP fired at 152K right after cycle-3 green; committed, pushed,
rolled. Auto-relaunch NOT invoked from the worktree (operational-knowledge
rule); user pulls main checkout, then launches.

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
