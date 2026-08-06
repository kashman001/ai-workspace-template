<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->


# Session Handoff — 2026-08-06 (session 18: slice 2 COMPLETE — `children` per-child sweep (R1); WARN rollover at ~120K)

**What shipped (committed `d194cc1`, pushed to `origin/main`; work done in
worktree `slice-2-children-sweep` — main checkout BEHIND until pulled):**

- **`children` subcommand (slice 2, R1):** `context-budget.sh children
  [--parent-session <sid>] [--all]` — enumerates a Claude parent's
  `subagents/agent-*.jsonl` + `.meta.json`, measures each with a
  sidechain-INCLUSIVE Claude-measure variant (child rows are all
  `isSidechain:true`; the self-measure filter would degrade them to size
  estimates), prints escalation-only WARN/STOP check-style lines
  (`agent= tokens= … status= age= type=`), exits with the worst child
  status. Non-claude runtimes die loudly. Design + rejected alternatives:
  `plans/slice-2-children-sweep.md` and the session-18 `decisions.md` note.
- **Tests:** new suite `scripts/tests/test-children-sweep.sh` C1–C9
  (27 asserts); all six suites green (registry 54, attach 22, launcher 65,
  statusline 14, vendor 37, children 27).
- **Live verification:** T13 back-stamp confirmed at register (session-17
  record stamped with this session's id); smoke sweep of a real fleet
  surfaced the research's motivating 141.8K subagent as WARN.
- **Follow-through, all done:** usage header; `docs/context-budget.md`
  "Per-child sweep" section + quickstart line; decisions.md note (not
  promoted — implementation detail within ADR-0005); backlog changelog row;
  plan file marked COMPLETE.

**Suggested skills (next session):** tdd for the next slice;
session-rollover at WARN/STOP.

**Learnings:** (parked, first strike each)
- The worktree-isolated Bash guard refuses compound commands (for-loops,
  `;`-chains with redirects, unquoted globs) even when they only run tests —
  split into one plain command per call.

**Rollover:** WARN at ~120K right at the slice boundary (record after push);
deliberate rollover, no unfinished work. Lock released manually (launch
script not invoked from a worktree, per operational rule).

# Session Handoff — 2026-08-06 (session 17: slice 1 COMPLETE — T13/T14 + follow-through + ADR-0005; WARN rollover at ~128K)

**What shipped (committed and pushed to `origin/main`; work done in worktree
`slice-1-t13-t14` — main checkout BEHIND until pulled):**

- **T13 `superseded_by` back-stamp:** on primary acquisition, `register`
  stamps `superseded_by=<runtime>-<sid>` onto the newest same-project
  `role=superseded` record without one (`backstamp_superseded` in
  `context-budget.sh`); already-stamped records never overwritten. Lineage
  now walkable both directions from disk.
- **T14 `register --takeover`:** explicit recorded steal — wins even against
  a live holder (S33 human authority); loser's record stamped
  `superseded`/`superseded_at`/`superseded_by`; loud stderr note. Without
  the flag, live-holder refusal to auxiliary unchanged.
- **Tests:** registry suite T13a–c + T14a–f → 54 asserts; all five suites
  green (registry 54, attach 22, launcher 65, statusline 14, vendor 37).
- **Follow-through, all done:** `context-budget.md` multi-session model
  reworked (four roles incl. `child`, release-order guard, takeover,
  back-stamp; status blockquote + attach role enum fixed); usage header of
  `context-budget.sh` gained the three new flags; issues/03 closed (only
  user-deprioritized listing/display items remain deferred); decisions.md
  session-17 note appended; **promoted → ADR-0005**
  (`docs/adr/0005-session-roles-and-child-registry.md`, indexed in README;
  session-15/16 notes marked promoted); scenario catalog gained
  "Implementation notes" (I2/I4 groundwork, S33, H-group seeds); backlog
  changelog row added (no new card — resolved the launcher's "L22?" as
  feature work, not a finding); plan file marked COMPLETE.

**Learnings:** (parked, first strike each)
- A `claude bg-spare` daemon (pid-alive) held the session-16 worktree lock;
  EnterWorktree refused re-entry. Fresh worktree from main cost nothing
  since everything was pushed.
- `record` run from inside a worktree writes to the *worktree's own*
  `.context-budget/` + ledger (script resolves WORKSPACE_ROOT from its own
  path) — measurement still correct, but those ledger entries are throwaway;
  the real lock/registry live in the main checkout where `register` ran.

**Rollover:** WARN fired at ~126K during backlog edit, right after all
suites green; finished follow-through, committed, pushed, rolled. Per the
operational-knowledge rule, auto-relaunch NOT invoked from the worktree;
user pulls main checkout, then launches.

