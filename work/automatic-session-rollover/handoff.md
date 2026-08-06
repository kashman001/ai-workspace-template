<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->


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

