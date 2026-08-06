# Session Handoff — 2026-08-06 (session 24: wayfinder tickets 06+07 RESOLVED; STOP rollover at ~157K)

**What shipped (worktree `session-24-wayfinder-tickets`, pushed to `origin/main`):**

- **Ticket 06 — mid-flight hook injection: REFUTED, dispatch-only stands.**
  Empirical run on production wiring (evidence:
  `research/06-midflight-hook-injection.md`): PostToolUse hooks DO fire on a
  child's tool calls but keyed to the PARENT session_id (shared 60s throttle
  + shared escalation state), and the harness DROPS hook exit-2 stderr for
  those fires — a natural 120K WARN crossing mid-run reached no transcript
  (parent/child/grandchild all grepped clean). Accelerator-tier fog patch
  closed. Surviving model-mediated alternative noted in the ticket answer
  (parent SendMessage → contract checkpoint clause). Two defects filed as
  backlog rows: swallowed-WARN (busy child consumes the one-shot escalation)
  and EnterWorktree registry-artifact staleness.
- **Ticket 07 — copilot child artifacts: resolved via gen 2
  (DONE_WITH_CONCERNS, ~23 min).** Findable + parseable: per-child events in
  `~/.copilot/session-state/<sid>/events.jsonl` tagged `agentId=<toolCallId>`
  (+ `subagent.completed.totalTokens`), and `session-store.db::
  assistant_usage_events` per-request rows. Adapter buildable → fog patch
  graduated to new ticket `issues/09-copilot-adapter-design.md`. Dispatch
  gen 2 closed; drain clean. Caveats in the ticket answer (model varies,
  background/`write_agent` unverified, `-wal` sidecar).
- Map updated (2 decisions, 2 fog patches closed/graduated); `decisions.md`
  session-24 notes; backlog: 2 finding rows.
- Note: gen 2's report edits landed in the worktree copy of
  `research/07-copilot-child-artifacts.md` (my mid-task worktree entry
  blocked its shared-checkout writes; it adapted via a worktree-isolated
  sub-subagent) — committed from the worktree, so origin/main carries it.

**Suggested skills (next session):** wayfinder (ticket 09 AFK, or 08 if user
is live); session-rollover at WARN/STOP.

**Learnings:** (parked)
- Auto-mode permission classifier blocks spawning nested `claude -p` with
  `--settings`/`--dangerously-skip-permissions`/`--allowedTools` (1st strike;
  worked around by testing against the production hook wiring instead).
- Mid-session EnterWorktree severed a RUNNING subagent's shared-checkout
  writes and all its Bash (1st strike; child adapted with an
  `isolation: worktree` sub-subagent — enter the worktree BEFORE dispatching
  children, or expect this).

**Rollover:** STOP at ~157K immediately after the ticket/map writes;
committed, pushed, rolled. Session-22 block archived (two-block rule).

# Session Handoff — 2026-08-06 (session 23: slice (c) registry hygiene COMPLETE + wayfinder map charted; WARN rollover at ~132K)

**What shipped (commits `0b71c46`, `f10941a`, `52b94ea` in worktree
`session-23-registry-hygiene`, all pushed to `origin/main`):**

- **Slice (c) — register-time sweep of stale primary records
  (`0b71c46`):** `sweep_stale_primaries` in `context-budget.sh` runs at
  primary acquisition (after `backstamp_superseded`): any other
  same-project `role=primary` record whose artifact liveness is stale
  (`LOCK_STALE` rule) is stamped with the takeover triple
  (`superseded`/`superseded_at`/`superseded_by=<new primary>`); live
  records, other projects, non-primary roles untouched; auxiliary/child
  registrations never sweep. Registry suite T15 (8 asserts, 68 total);
  all eight suites green (326 asserts). Plan:
  `plans/registry-hygiene-sweep.md`; stamp-don't-delete rationale in
  `decisions.md` session-23 note (not promoted). Docs paragraph in
  `context-budget.md` roles section; backlog row. **Retires the parked
  sessions-19/21 learning.**
- **Slice (a) — wayfinder map charted (`f10941a`):** `map.md` +
  tickets `issues/06-midflight-hook-injection.md` (task, AFK),
  `07-copilot-child-artifact-location.md` (research, AFK),
  `08-per-role-thresholds.md` (grilling, HITL). Accelerator-tier and
  copilot-adapter design parked in the map's fog until 06/07 resolve.
- **Ticket-07 gen 1 dispatched and rolled (`52b94ea`):** research
  subagent launched via `dispatch-open` (first live use of the R4
  machinery — open → contract emit → close worked end-to-end); child hit
  its own WARN at ~123K before any copilot probe runs and yielded
  `ROLLOVER_NEEDED` per contract; gen 1 closed with that status; report
  checkpointed at `research/07-copilot-child-artifacts.md`
  (self-contained: pre-run `~/.copilot` snapshot + method; gen 2 starts
  at its open item 1). Ticket 07 back to `Status: open`.

**Suggested skills (next session):** wayfinder (work-through-the-map
mode); session-rollover at WARN/STOP.

**Learnings:** (parked)
- Worktree-isolated sessions: the sandbox refuses compound shell
  commands (for-loops, multi-statement `&&`/`;` chains with redirects)
  as "too complex to verify"; use separate plain commands. Bit both the
  parent and the ticket-07 child this session (also documented in the
  gen-1 report).

**Rollover:** WARN at ~122K as charting finished; child's
ROLLOVER_NEEDED yield folded in, committed, pushed, rolled.

# Session Handoff — 2026-08-06 (session 22: R4 COMPLETE — dispatch records + generation fencing; WARN rollover at ~127K)

**What shipped (committed `1713daa` in worktree
`session-22-r4-dispatch-records`, pushed to `origin/main`):**

- **R4 — parent-persisted dispatch records + generation fencing:** three new
  `context-budget.sh` subcommands. `dispatch-open --project <p> --task
  <slug> --report <path> [--brief/--agent-type/--model/--effort/--agent-id]`
  appends generation N+1 (status `open`) to the gitignored record
  `work/<p>/.agent-dispatch/<slug>.json` and emits the R2 contract for that
  generation in one step; refuses while the previous generation is still
  open (fencing — at most one live writer per report file); `--gen` is
  rejected (computed from the record). `dispatch-close --status <five yield
  statuses|KILLED>` closes the open generation (`--agent-id` merges
  post-hoc). `dispatch-list` prints `task= gen= status= report=` lines,
  exit 1 while any generation is open (the rolling parent's drain check).
  Contract emitter now labels progress blocks `[gen N]`. Design + rejected
  alternatives: `plans/dispatch-records-r4.md` + session-22 `decisions.md`
  note (not promoted — within ADR-0005/0006's model; revisit at R6).
- **Tests:** new suite `scripts/tests/test-dispatch-records.sh` L1–L9
  (51 asserts); all eight suites green — registry 60, attach 22, launcher
  81, statusline 16, vendor 37, children 27, dispatch-contract 24,
  dispatch-records 51 (318 total).
- **Docs:** `docs/context-budget.md` children section retitled R2–R4 with
  the record/fencing flow + successor-parent re-dispatch paragraph +
  quickstart bullet now dispatch-open-first; CONTEXT.md dispatch bullet
  likewise; `.gitignore` gains `work/*/.agent-dispatch/`; backlog changelog
  row.

**Slice order (user pick, session 22):** (b) R4 → (c) registry hygiene →
(a) §14 wayfinder tickets. (b) is done; (c) is next, then (a) — no further
user pick needed.

**Suggested skills (next session):** tdd for slice (c); wayfinder for
slice (a); session-rollover at WARN/STOP.

**Learnings:** (parked, carried from sessions 19/21 — slice (c) is the
retirement)
- Registry hygiene: stale `role=primary` records accumulate in
  `.context-budget/sessions/`; cosmetic — lock is authoritative.

**Rollover:** WARN at ~125K right as R4 follow-through finished; committed,
pushed, rolled. Session-19 block archived (two-block ledger rule).

<!--
ARCHIVE of work/automatic-session-rollover/handoff.md — older ledger blocks,
newest first. Moved here when handoff.md exceeds the two most recent blocks.
-->
# Session Handoff — 2026-08-06 (session 21: ADR-0006 promoted + slice 3 COMPLETE — dispatch-contract (R2/R3); WARN rollover at ~129K)

**What shipped (committed `d2ee5dd` + `6fc7cec` in worktree
`session-21-adr-0006-slice-3`, both pushed to `origin/main`):**

- **ADR-0006 promoted (`d2ee5dd`):** the session-19 note ("coordination
  state keyed to repository identity, never a checkout") is now
  `docs/adr/0006-repository-keyed-coordination-state.md`, amending
  ADR-0004/0005's implicit one-checkout assumption; README index + backlog
  row updated, note flipped to `done → ADR-0006`.
- **Slice 3 — dispatch-contract hardening, R2/R3 (`6fc7cec`):** new
  stateless, runtime-agnostic `context-budget.sh dispatch-contract
  --report <path> [--brief <path>] [--gen <n>]` emits the R2 rollover
  contract for a long-running child's dispatch prompt (checkpoint to report
  at work-unit boundaries = heartbeat; 15-line return cap; five-status
  vocabulary incl. `ROLLOVER_NEEDED` only-on-request, never
  self-assessment; gen≥2 read-report-first clause; ASCII-only for the
  `%q`/BSD-sed launch paths). R3 documented parent-side: successor dispatch
  is the only rollover verb; sweep (`children`) before any resume, roll at
  child WARN/STOP, no human ask (R7). Design + rejected alternatives:
  `plans/slice-3-dispatch-contract.md` + session-21 `decisions.md` note
  (not promoted — implementation within ADR-0005's model).
- **Tests:** new suite `scripts/tests/test-dispatch-contract.sh` K1–K7
  (24 asserts); all seven suites green — registry 60, attach 22, launcher
  81, statusline 16, vendor 37, children 27, dispatch-contract 24 (267).
- **Docs:** `docs/context-budget.md` new "Dispatching long-running
  children" section + agent-quickstart line + children cross-ref;
  CONTEXT.md Context Budget bullet (dispatch-time pointer); backlog rows
  for both units.
- **Live verification:** first live T13-via-launcher back-stamp — session
  19's record was stamped `superseded_by` this session's id at register
  (the launcher-mediated succession chain now closes end-to-end).

**Suggested skills (next session):** tdd for the next slice; wayfinder if
slice 4 (decision tickets) is picked; session-rollover at WARN/STOP.

**Learnings:** (parked, carried from session 19 — did not bite this
session)
- Registry hygiene: stale `role=primary` records accumulate in
  `.context-budget/sessions/` from sessions that never released; cosmetic —
  lock is authoritative.

**Rollover:** WARN at ~121.6K right after slice-3 suites green;
follow-through finished, committed, rolled. Second worktree-invoked
auto-relaunch.
# Session Handoff — 2026-08-06 (session 19: issue 05 COMPLETE — workspace-root anchoring; WARN rollover at ~139K)

**What shipped (committed `a850d7b` in worktree
`issue-05-workspace-root-anchoring`, pushed to `origin/main` with the
rollover commit; the successor relaunch itself ff-pulls the main checkout —
first live use of the mechanized sync):**

- **Workspace-root anchoring (issue 05):** all five coordination scripts
  (`context-budget.sh`, `launch-next-session.sh`, `attach-session.sh`,
  `statusline-context-budget.sh`, `hooks/context-budget-hook-lib.sh`) now
  resolve `WORKSPACE_ROOT` via `git rev-parse --git-common-dir` → every
  worktree converges on the main checkout's `.context-budget/`, locks,
  ledger, `.session-seq`. Marker-guarded fallback to script-relative
  resolution outside git. Design + rejected alternatives:
  `plans/workspace-root-anchoring.md` + session-19 `decisions.md` note
  (**promote-candidate: YES** — amends ADR-0004/0005's one-checkout
  assumption; not yet promoted).
- **Mechanized worktree launch-sync:** `launch-next-session.sh` invoked from
  a worktree verifies worktree committed+pushed and main `work/<proj>/`
  clean, `pull --ff-only`s the main checkout, launches from the main root
  (loud exit-3 refusals). Retires the "no auto-relaunch from worktrees" ban
  and register-before-isolate.
- **Tests:** new G1/G2 (registry), W1–W5 (launcher), T8 (statusline); all
  six suites green — registry 60, attach 22, launcher 81, statusline 16,
  vendor 37, children 27 (243 total).
- **Live verification:** `record` from this worktree wrote to the main
  checkout's ledger (fix observed working); T13 back-stamp check at register
  was a correct no-op — session 18 released its lock manually (worktree
  ban, now retired), so no `superseded` record existed to claim.
- **Follow-through, all done:** `docs/context-budget.md` "Worktrees"
  section; operational-knowledge divergence entry marked superseded-by-fix;
  worktree Bash-guard learning promoted (second strike, sessions 18+19);
  backlog changelog row; issue 05 marked RESOLVED; plan COMPLETE.

**Suggested skills (next session):** decision-log (`/decision promote`) if
the user wants the ADR; tdd for the next slice; session-rollover at
WARN/STOP.

**Learnings:** (parked, first strike)
- Registry hygiene: `.context-budget/sessions/` accumulates stale
  `role=primary` records from ended sessions that never released/rolled
  (three from 2026-08-06 alone); lineage stamps only cover launcher-mediated
  successions. Cosmetic for now — the lock, not the records, is
  authoritative.

**Rollover:** WARN at ~126K right after all suites green; follow-through
finished, committed, rolled. First rollover to use the worktree-invoked
auto-relaunch path this slice just shipped.

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

# Session Handoff — 2026-08-06 (session 12: HTML review rendition shipped; STOP rollover at 155K mid-turn)

**What shipped (committed on `main`, pushed):**

- **`subagent-rollover-research.html` — `d93daea`:** standalone, self-contained
  HTML review rendition of the research note, restructured per user direction:
  problem (with the stats evidence) → the model (§2: roles/policy, verb,
  protocol, files, lock hierarchy, state machines, drain mode, invariants
  I1–I8 — with 5 hand-authored inline-SVG diagrams: system model, resume-vs-
  successor, lock hierarchy, child lifecycle, parent budget modes) → machinery
  already in place (§3) → findings (§4) → proposal R1–R8 + inventory (§5) →
  evaluation model (§6) → next steps. Light/dark via CSS tokens; no external
  deps. Diagrams visually verified in Chrome (3 label-overlap fixes applied
  pre-commit). The markdown note remains the raw record (footer says so).
- Tier-2 decision note (HTML-vs-Artifact) in `decisions.md`; claude-in-chrome
  `file://` gotcha routed to `docs/operational-knowledge.md`.

**Mid-turn user request (binding, NOT started):** enumerate rollover
*scenarios* — mainline functional plus corner/edge cases for resilience,
recoverability, and performance — to (a) keep in mind while working through
the doc and (b) drive evaluation, *before* any implementation. User asked
whether their dimension list misses anything (candidates to consider:
concurrency/contention incl. human attach during drain, observability/
auditability, cost/token-economy, schema evolution of records, degradation on
opaque runtimes, human-in-the-loop policy edges). Seed material: S1–S10 +
P1–P5 + §13 fault model already in the research doc — the new catalog should
extend, not duplicate, those.

**Rollover:** WARN fired mid-diagram-verification (134K), STOP (155K) two
edits later; wrapped the atomic step (commit `d93daea` + this ledger) and
rolled. Second consecutive session terminated on schedule by its own subject
matter.

# Session Handoff — 2026-08-06 (session 11b: subagent-rollover research phase; STOP rollover at 157K)

**What shipped (committed on `main`, pushed through `4fa0cdb`):**

- **`subagent-rollover-research.md`** (this work dir) — full research/design
  note on parent-managed child-session rollover: what transfers from
  main-session rollover, parent-as-manager policy mapping, successor-dispatch
  as the only rollover verb (resume worsens context), per-child files +
  dispatch records, lock hierarchy with transitive validity, drain-mode
  invariant (no parent rollover with live children), checkpoint/yield
  protocol (§8), 14-row rollover inventory (§9), delta requirements R1–R8
  (§10), vendor-agnostic layering (§11), depth/resilience model (§12),
  evaluation model — state machines, invariants I1–I8, scenarios S1–S10,
  fault properties P1–P5, cost model (§13).
- **`subagent-rollover-stats.md`** — measured: 30 subagent transcripts, 3
  crossed 120K WARN, max 141.8K (a *resumed* implementer), 0 ≥ 150K; claude
  child transcripts live at `<project-dir>/<parent-uuid>/subagents/agent-*.jsonl`
  with `.meta.json` siblings.
- **`subagent-vendor-survey.md`** — 4-runtime capability survey: only claude
  (and partially copilot) expose child identity; codex/gemini children are
  opaque; opencode forbids nesting; no runtime reports per-child usage.

**How it was produced:** three parallel background research agents (local
stats; Claude Code docs mechanics; live-CLI vendor survey) + controller
synthesis; user added mid-flight: vendor-agnostic requirement, the
communication protocol, the rollover inventory, and the evaluation model.

**Rollover:** STOP hook fired at 156,987 tokens right after the eval-model
section landed — the system being designed terminated its own design session
on schedule.

# Session Handoff — 2026-08-05 (session 8: plan execution started — Task 1 shipped; WARN rollover)

**What shipped (committed + pushed on `main`):**

- **Task 1 of `plans/2026-08-05-vendor-hook-deployments.md` — commit `4a39bf8`:**
  shared lib `scripts/hooks/context-budget-hook-lib.sh` (throttle /
  escalation-only / fail-open core, canonical WARN/STOP text);
  `context-budget-claude-hook.sh` refactored to a thin wrapper sourcing it
  (byte-identical messages; state files renamed `hook-claude-<sid>.*` — stale
  old files harmless); new suite `scripts/tests/test-vendor-budget-hooks.sh`,
  13 asserts green (T1 escalation, T2 throttle, T3 fail-open, T4 claude
  envelope).

**Session friction (resolved, no action needed):** primary checkout lagged
origin/main — session 7 had pushed its rollover commit from the worktree
branch; `git pull --ff-only` fixed it (the launcher's First-action warning
worked). The live claude hook fired WARN in-band at 121K right after plan
load — the push channel this whole item builds is demonstrably working.

**What did NOT happen:** Tasks 2–8 untouched (opencode runtime, codex/gemini/
opencode/copilot deployments, option inheritance, docs gate). Task 1 was
executed as the final work unit under WARN; rollover began at ~135K.

**Loose ends:** leftover locked worktree
`.claude/worktrees/vendor-hook-deployments` (branch fully merged into main) —
safe to `git worktree remove --force` + `git branch -d` when convenient.

**Suggested skills for next session:** `superpowers:executing-plans` on the
plan (Tasks 2–8); `session-rollover` at WARN/STOP.


# Session Handoff — 2026-08-05 (session 7: item #3 planned — vendor hooks + option inheritance; STOP rollover before execution)

**What shipped (committed + pushed from worktree branch
`worktree-vendor-hook-deployments`):**

- **Item #3 implementation plan, complete and self-contained:**
  `plans/2026-08-05-vendor-hook-deployments.md` — 8 tasks, all code inlined
  (no placeholders), TDD steps per task. Covers: shared hook lib extracted
  from the claude hook (Task 1); **new `opencode` runtime for
  context-budget.sh** (Task 2 — gap found this session: the script had no
  opencode branch; sqlite schema live-verified against
  `~/.local/share/opencode/opencode.db` v1.18.14: `message.session_id` +
  `json_extract(data,'$.tokens.total')`, session-column fallback); codex
  `UserPromptSubmit` (Task 3), gemini `BeforeAgent` (Task 4 — envelope pinned
  from bundled v0.46.0 reference.md: `hookSpecificOutput.additionalContext`,
  JSON-only stdout), opencode `chat.message` plugin (Task 5), copilot
  `sessionStart`+`agentStop` STOP-only block (Task 6); **successor option
  inheritance** (Task 7 — user request mid-session: approval mode + model
  replay via `work/<proj>/.rollover-options`, mapped per runtime in
  launch-next-session.sh); docs/backlog/decisions + full verification gate
  (Task 8).
- **Ops finding** routed to `docs/operational-knowledge.md`: EnterWorktree
  re-keys the Claude Code project dir — the live transcript moves, the
  registry artifact goes stale, and discovery misattributes another session's
  usage (a predecessor's 148K WARN read as ours; real reading was 45K then).
  Re-register after entering a worktree.

**What did NOT happen:** no plan task was executed — the session hit STOP
(171K, measured exact against its own worktree-keyed transcript) right after
the plan was written. Execution is entirely the successor's.

**User inputs this session (both folded into the plan, Task 7):** the
successor session must inherit the predecessor's options (approval/auto mode,
model, etc.), for all vendor agent types.

**Loose ends:** main checkout's `work/context-decay/context-ledger.jsonl` has
uncommitted rows (this session's record calls ran there); fold into the next
work commit. Session-5 ledger block moved to `handoff-archive.md` (2-block
rule).

**Suggested skills for next session:** `superpowers:executing-plans` (or
subagent-driven-development) on the committed plan; `session-rollover` at
WARN/STOP.


# Session Handoff — 2026-08-05 (session 6: implementation item #2 shipped — launch-next-session.sh; WARN rollover)

**What shipped (all committed + pushed, `b6d245a`, `d468f7c`, `ef42a12`):**

- **Item #2 complete.** `scripts/launch-next-session.sh` per ADR-0003/0004:
  verbatim bootstrap prompt (single source of truth in the script); runtime
  resolution --runtime flag > dying session's own registry record (D6,
  env-first identity mirroring `context-budget.sh session_id_for()`) > newest
  record for the project > `ROLLOVER_RUNTIME` > claude; 5 runtimes
  seeded-interactive (`claude` [+`--bg`], `codex` positional, `gemini -i`,
  `opencode --prompt`, `copilot -i` — all flags re-verified against live
  `--help` this session); modes off/manual/auto honored (auto+claude implies
  --bg); --bg claude-only (die otherwise); D8 successor confirmation poll
  after --bg (`ROLLOVER_CONFIRM_SECS`, default 120s, non-fatal); non-tty
  manual prints `run: <cmd>` instead of exec'ing a TUI; copilot-vscode
  degrades to prompt-only.
- **Tests:** `scripts/tests/test-launch-next-session.sh` — 13 cases /
  28 asserts, all green (dry-run flag assembly + stub-binary --bg/D8/timeout/
  non-tty paths). Registry suite still green (13/13).
- **Docs:** `docs/context-budget.md` §Rollover trigger policy status note
  flipped to implemented; backlog changelog row appended; four Tier-2 notes
  in `decisions.md` (tty guard, copilot-vscode degradation, --bg-only D8
  confirmation, always-print prompt); plan committed at
  `plans/2026-08-05-launch-next-session.md`; stale `workspace-structure.html`
  rebuilt.

**Where things stand:** items #1+#2 done; item #3 (four vendor hook
deployments) not started — next session's mission. Working tree clean apart
from the live `.active-session` lock (untracked by design).

**Suggested skills for next session:** superpowers:writing-plans →
executing-plans (the pattern items #1 and #2 both used successfully);
session-rollover at WARN/STOP.

# Session Handoff — 2026-08-05 (session 5: implementation item #1 shipped — session-keyed registry, lock, release, gemini guard; WARN rollover)

**What shipped (all committed + pushed, `15ec961`…`187f926` + rollover commit):**

- **Item #1 complete, M13 closed.** `scripts/context-budget.sh` migrated to the
  session-keyed registry per ADR-0004: `session_id_for()` (env-first identity,
  artifact-derived fallback, gemini fixed id `workspace`); resolve-self in
  `check`/`record` (own session file only, never another's);
  `.context-budget/sessions/<runtime>-<session-id>.json`; `register --project`
  acquires `work/<proj>/.active-session` (advisory: live holder warned never
  stolen; stale >`CONTEXT_LOCK_STALE_SECS` [new knob, 3h] reclaimed); new
  `release` subcommand (self-only, project defaults from own session record);
  gemini concurrent-session guard (fresh non-empty telemetry log → skip reset,
  degrade to chat-log estimate).
- **Tests:** `scripts/tests/test-context-budget-registry.sh` — 13 asserts, all
  green; T1 is the live M13 clobber repro (was red against the old scalar
  registry). Self-contained throwaway workspace in mktemp; fake $HOME.
- **Docs:** `docs/context-budget.md` (§Multi-session status → implemented;
  §Session registration rewritten for sessions/ + lock + release; gemini-only
  limitation para), `skills/session-rollover/SKILL.md` (release call after
  verification gate), backlog M13 → Resolved, new L16 (phantom test suite in
  workspace-structure.md, fixed same session), summary line → all 31 resolved.
- **Plan + decisions:** implementation plan at
  `plans/2026-08-05-session-keyed-registry.md` (all tasks checked off in
  execution, file committed with this rollover); three Tier-2 notes appended to
  `decisions.md` (identity derivation, advisory-not-blocking lock, gemini
  freshness guard).

**Verification state:** `bash scripts/tests/test-context-budget-registry.sh`
exits 0; live register/record in this session used the new registry and
correctly tracked this session's own transcript (dogfood: the WARN that
triggered this rollover came from it).

**Suggested skills for next session:** `superpowers:writing-plans` then
`superpowers:executing-plans` (same pattern as this session) for item #2;
`docs/context-budget.md` §Relaunch knobs is the spec.

# Session Handoff — 2026-08-05 (session 4: documentation phase shipped in one commit; WARN rollover into implementation phase)

Executed the session-3 launcher's documentation plan verbatim; no design was
reopened. Substance is in the committed docs themselves; this block is
provenance only.

- One commit, `9c6a097`, pushed to main: `docs/context-budget.md` gained
  "Rollover trigger policy" / "Relaunch knobs" / "Multi-session model"
  sections (each with an explicit design-accepted-implementation-pending
  status note) and corrected stale copilot-cli "unverified" claims (smoke
  test verified 73.0k exact); knob block landed in `context-budget.env`
  (`ROLLOVER_RELAUNCH=manual`, `ROLLOVER_RUNTIME=claude`);
  `skills/session-rollover/SKILL.md` gained hybrid trigger semantics, the
  hook-less cadence fallback (~10 exchanges), and the relaunch closing step
  (graceful when the script is absent); pointer lines in `CONTEXT.md` +
  `docs/workspace-structure.md`; ADR-0004 companion promoted from the three
  session-3 notes (Promote? fields flipped; ADR-0003 got a Refined-by link);
  `issues/01-vscode-agent-mode-hooks.md` ticket created; backlog card M13
  (registry-clobber bug, Open with approved fix) + scorecard updated.
- Doc-phase decision recorded in `decisions.md` (newest note): one companion
  ADR-0004, not an amended 0003 or four ADRs.
- Ops note: `workspace-structure.md`'s scripts tree already lists planned
  entries (`scripts/tests/` doesn't exist on disk), so the
  `launch-next-session.sh` tree line landing pre-implementation is consistent;
  `check-workspace-structure.sh` iterates existing scripts only.
- WARN (122.7K) fired at commit time; user approved rollover. Docs summary was
  presented; user raised no objections before approving — treat the doc set as
  baseline unless they say otherwise.

Suggested skills for the next session: `superpowers:writing-plans` or `tdd`
(implementation of the registry migration), `decision-log`,
`session-rollover` at the boundary.

---


# Session Handoff — 2026-08-05 (session 3: ALL open questions closed; research + smoke tests landed; user-directed rollover into documentation phase)

Design discussion is COMPLETE. Every open question is closed and recorded;
substance lives in `relaunch-analysis.md` (open-questions section, final
state), `decisions.md` (three new Tier-2 notes), and the three research docs.
This block is provenance only.

- Closed with user: #1 multi-session identity redesign approved (operating
  model: one developer, N concurrent sessions, one per work item); #2 knobs
  (`context-budget.env`, off/manual/auto, `manual` default); #3 all four hook
  deployments in scope (smoke tests collapsed the deferral rationale); #4
  launcher covers all five runtimes seeded-interactive, background claude-only.
- Research delivered (background agents): `vendor-hooks-research.md` (all
  four runtimes PUSH-CAPABLE — the "agent discipline only" matrix rows were
  stale); `smoke-test-opencode.md` (opencode 1.18.14 installed; chat.message
  injection CONFIRMED live, part shape trap documented; sqlite token store);
  `smoke-test-copilot.md` (copilot CLI 1.0.78 installed; hooks CONFIRMED
  live; `copilot -i` seeded-interactive REFUTED the headless-only claim;
  VS Code agent mode ships hooks since v1.109, Preview, reads our formats —
  live verification is the one spun-out ticket).
- Machine state changed: opencode (brew) + copilot CLI (npm) now installed;
  scratch test dirs under the session scratchpad; a stray `$schema` line
  opencode auto-added to `.opencode/opencode.json` was reverted.
- Next phase (user-agreed sequence): documentation first, then
  implementation. See `next-session.md`.

Suggested skills for the next session: `writing-for-agents` (doc edits),
`decision-log` (promotions to the ADR-0003 family), `checkpoint` or
`session-rollover` at the boundary.

---

*Older blocks: `handoff-archive.md`.*
# Session Handoff — 2026-08-05 (session 2: design discussion — hybrid settled, ADR-0003, codification walkthrough, multi-session redesign proposed; WARN rollover)

Same calendar day as session 1, fresh context. All substance lives in
`relaunch-analysis.md` (written incrementally — effective write-ahead) and
ADR-0003; this block is provenance only.

- Settled with user: consent axis reframe; hybrid trigger (WARN asks, STOP
  automatic); dying agent conducts rollover; write-ahead on declined WARN;
  answer-then-rollover as discussion atomic step; D1–D8 local-vs-LLM verdicts
  + conductor state machine.
- ADR-0003 promoted (user-directed) from a Tier-2 note; committed + indexed.
- User challenged D6 (global active-project state) → multi-session identity
  redesign proposed (session-keyed state + per-project advisory lock);
  **awaiting user verdict** — the successor's first question.
- The registry-clobber bug fired live mid-session (record measured the dead
  demo session); evidence in the analysis, workaround in
  docs/operational-knowledge.md.
- Commits this session: 506a68e, 8e2ac7d, 8eabdb0, 56dc888 + the rollover
  commit; all pushed to main.

---

# Session Handoff — 2026-08-05 (session 1: project spun out of template-maintenance; demo run; analysis captured)

Spun out of `work/template-maintenance/` mid-discussion: its queued
`launch-next-session.sh` mission grew into this focused project at the user's
request ("this deserves a good discussion and proper focused project").

What got done this session (while still under template-maintenance):
- Verified launch flags against installed CLIs — caught that
  `claude --bg --name` doesn't exist (no `--name` flag).
- Live demo: `claude --bg` launched a detached seeded session in this cwd; it
  read the launcher and answered correctly in ~11s; stopped cleanly.
- Full analysis written to `relaunch-analysis.md` (pipeline concept, vendor
  matrix, knob proposal, four open questions).
- User widened scope beyond the script: cross-vendor *triggering* reliability
  and workspace-parameter optionality are explicitly part of the problem.

State: no code written; `main` clean apart from this new work directory and a
retarget note in `work/template-maintenance/next-session.md`. Immediate next
step: the open-questions discussion (see launcher).
# Session Handoff — 2026-08-06 (session 11: Task 9 shipped + final whole-branch review — PLAN COMPLETE)

**What shipped (committed on `main`, pushed through `75e8cbc`):**

- **Task 9 — `3fafd13` + `6d0f448`:** `scripts/attach-session.sh` (find latest
  session for a work dir; attach when alive+locked) + `test-attach-session.sh`
  (19 asserts, bash-3.2 verified), docs front-door update, backlog row,
  Tier-2 note. Live `--help` verification: no `claude attach` subcommand
  exists — wired `claude --resume <session_id>`; limitation recorded in
  script header, docs, and decision note. One fix round (backlog row missing
  commit hash), then review clean.
- **Final whole-branch review (`13201b5..6d0f448`, most capable model):** no
  Criticals. One Important — `skills/session-rollover/SKILL.md:141` still
  instructed the nonexistent `claude attach` — fixed in `75e8cbc` along with
  a new open backlog card **L17** bundling the deferred follow-up minors
  (attach-session unlocked-case wording; space-unsafe `ls -t` loops in
  attach/launch scripts; unquoted SQL interp in `opencode_measure`; registry
  suite filename drift in docs). Re-review clean except one **parked** Low:
  backlog scorecard counts drifted (Open reads 2 vs 1 actual; Resolved 29 vs
  31 — pre-existing) — ruled cosmetic, folded into L17's scope.
- Ledger deferred minors all triaged by the final review: T3 lib-sourcing
  fail-open ruled fine as-is; T7 docs pointer and T8 footer date verified
  fixed. SDD workspace deleted after completion (git history is the record).

**Plan status: all 9 tasks complete, reviewed, pushed. The
vendor-hook-deployments plan is DONE.**

# Session Handoff — 2026-08-06 (session 10: plan Tasks 7–8 shipped; user added Task 9 (attach helper); WARN rollover)

**What shipped (committed on `main`, pushed):**

- **Task 7 — `e0cb70d`:** successor option inheritance —
  `work/<proj>/.rollover-options` read in `scripts/launch-next-session.sh`,
  mapped to per-runtime flags; rollover-skill step 6 added; suite
  `test-launch-next-session.sh` now 38 asserts. Live `--help` verification
  corrected the plan's table: codex `--full-auto` does not exist in codex-cli
  0.142.4 → shipped `--ask-for-approval never`; opencode `--auto` exists so
  opencode stayed in the approval mapping. Review clean.
- **Task 8 — `f9e003a`:** docs gate — `docs/context-budget.md` "Vendor hook
  deployments" section + `.rollover-options` under Relaunch knobs, CLAUDE.md
  Context Budget updates, backlog rows, 6 Tier-2 notes in `decisions.md`.
  All three suites green (37/38/13). Review clean. Includes two user-requested
  additions: "Chained rollovers & re-attach" passage (attach-vs-relaunch
  decided by the `.active-session` lock; bg chains are claude-only) and the
  gemini successor spurious-STOP caveat (workspace-scoped telemetry).

**Mid-session user input (binding):** (1) analysis of 2+-hop rollovers per
vendor — delivered in-session, durable parts flushed into
`docs/context-budget.md` by Task 8; (2) attach helper is NOT YAGNI — user
mandated `scripts/attach-session.sh`; scoped as **Task 9 (user-added)**, brief
written at `.superpowers/sdd/2026-08-05-vendor-hook-deployments/task-9-brief.md`,
NOT yet implemented.

**What did NOT happen:** Task 9 implementation/review; the final SDD
whole-branch review (range `13201b5..HEAD`, plus deferred-minor triage).
SDD ledger with per-task record + deferred minors:
`.superpowers/sdd/2026-08-05-vendor-hook-deployments/progress.md`.

**Suggested skills for next session:** `superpowers:subagent-driven-development`
(mid-plan, resume at Task 9); `session-rollover` at WARN/STOP.

# Session Handoff — 2026-08-06 (session 9: plan Tasks 2–6 shipped via subagent-driven development; WARN rollover)

**What shipped (committed on `main`, pushed at rollover):**

- **Task 2 — `6a78138`:** `opencode` runtime in `scripts/context-budget.sh`
  (sqlite measurement from `message.data` tokens.total, session-column
  fallback; env-only detect). Suite T9.
- **Task 3 — `4543645`:** codex `UserPromptSubmit` hook
  (`scripts/hooks/context-budget-codex-hook.sh` + `.codex/config.toml`). T5.
  Smoke check needed `-m gpt-5.5` (machine's global codex config pins an
  unavailable model — see docs/operational-knowledge.md).
- **Task 4 — `93e9d45`:** gemini `BeforeAgent` hook + `.gemini/settings.json`
  wiring (graphify BeforeTool + telemetry preserved). T6/T10. Live smoke
  blocked by missing gemini auth on this machine (pre-documented gotcha);
  gemini parsed the new config shape cleanly.
- **Task 5 — `f9579fe`:** opencode `chat.message` plugin + wrapper. T7.
  Justified 4th file: plugin registered in `.opencode/opencode.json` `plugin`
  array (plugins do NOT auto-load from `.opencode/plugins/`). Live smoke green.
- **Task 6 — `9fa16b7`:** copilot CLI `sessionStart`/`agentStop` hooks +
  `.github/hooks/context-budget.json`. T8. Live smoke green; this workspace
  added to `~/.copilot/config.json` `trustedFolders` (was absent).

Suite `scripts/tests/test-vendor-budget-hooks.sh`: 37 asserts green.
Per-task review record + deferred minors: `.superpowers/sdd/2026-08-05-vendor-hook-deployments/progress.md`
(SDD ledger — final whole-branch review still pending, do after Task 7).

**What did NOT happen:** Task 7 (option inheritance in launch-next-session.sh
+ SKILL.md step) and Task 8 (docs/backlog/decisions + verification gate +
final review). Two machine gotchas routed to docs/operational-knowledge.md.

**Suggested skills for next session:** `superpowers:subagent-driven-development`
(SDD ledger above is mid-plan); `session-rollover` at WARN/STOP.

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

