<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-06 (session 26: ticket-09 duplicate resolution reconciled + design verified; launcher-staleness race found)

**What shipped (worktree `session-26-ticket-09`, pushed to `origin/main`):**

- **Incident: session 26 launched from a stale checkout and re-resolved
  ticket 09 in parallel.** Session 25 had already resolved it and pushed,
  but the local main checkout was never ff-pulled, so this session read
  session 24's launcher (whose "pull if missing session-24" first-action
  check passed vacuously) and independently re-derived the design.
  Reconciled: origin/main (session 25's answer) is canonical; session-26's
  duplicate commit was discarded (kept on backup branch
  `session-26-pre-reconcile`), and its value reduced to a verification
  addendum. Root cause + mitigation recorded as a backlog Finding row;
  launcher First-actions now demand `git fetch` + empty `HEAD..origin/main`
  BEFORE trusting the launcher.
- **Ticket-09 design VERIFIED on the durable evidence files** (addendum in
  the ticket): child (`agentId`-tagged) events carry ONLY `outputTokens` +
  `subagent.completed.totalTokens`; every `inputTokens` sits on the single
  `session.shutdown` rollup — so sqlite-first measurement (§3) is confirmed
  necessary (no input-side number in events.jsonl mid-session), and the
  `copilot_cli_measure` silent-degrade concern (§3 bonus) is confirmed real.
  The independent re-derivation also converged on context-size-not-
  totalTokens, R4-reuse-verbatim, and the background/`write_agent` probe
  gate — one divergence (no-locks vs composite-id locks) adjudicated in
  session 25's favor (addendum has the reasoning).
- decisions.md session-26 note; backlog: 1 new Finding row (launcher
  staleness race) + verification sentence appended to the session-25 design
  row. No code/tests touched.
- **User is live in VS Code with Copilot Chat (Sonnet 5) and offered to run
  prompts there** — issue-01 item 2 (`copilot_vscode_measure` live
  verification) prompt handed over; result to be recorded in
  `issues/01-vscode-agent-mode-hooks.md` when it comes back.

**Suggested skills (next session):** wayfinder (ticket 08, ONLY if user is
live — grilling, HITL); session-rollover at WARN/STOP.

**Learnings:**
- Launcher staleness race (1st strike, mitigated same session): a
  "checkout carries session N's commit" first-action check cannot detect a
  newer sibling rollover on origin — fetch-and-compare is the only safe
  freshness guard before trusting next-session.md.

**Post-wrap addendum (user went live in VS Code):**

- **Issue-01 item 2 largely CLOSED, diagnosis flipped twice:** live copilot
  chat couldn't self-measure (no artifact), but `copilot_vscode_measure` was
  then verified exact from this session (`method=exact tokens=38680` against
  the live chatSessions jsonl). Root cause found by a user-side agent: the
  sandboxed VS Code terminal blocks `readdir` on `workspaceStorage/` parent
  (glob expands empty) though direct paths stay readable. **Fix spec queued:**
  `work/context-decay/copilot-vscode-sandbox-discovery-fix.md` (derive the
  storage hash from `VSCODE_TARGET_SESSION_LOG` via parameter expansion, no
  readdir; keep glob as fallback) — user-approved work for the successor.
- Archive-truncation incident: session-26's archive step opened
  `handoff-archive.md` for write before reading it (833 lines lost,
  restored from git history same session, commit `71ce22d`).

**Learnings:** (parked)
- Python one-liner `open(f,'w').write(...+open(f).read())` truncates before
  reading — write-before-read archive bug (1st strike, self-inflicted).
- Copilot Chat agent terminals: `VSCODE_TARGET_SESSION_LOG` visible in
  session context but not exported to its shell; `~/Library` readdir
  sandbox-blocked (1st strike; fix spec above removes the dependency).

**Wrap:** WARN rollover at ~149K after the live-user verification work;
reconcile + verification + issue-01 updates committed, pushed through
`955de80` + this rollover commit. Session-24 block archived (two-block rule).

# Session Handoff — 2026-08-06 (session 25: wayfinder ticket 09 RESOLVED — copilot adapter designed; clean wrap at ~113K)

**What shipped (worktree `session-25-ticket-09`, pushed to `origin/main`):**

- **Ticket 09 — copilot measured-tier adapter: DESIGNED.** Full design +
  rejected alternatives under `## Answer` in
  `issues/09-copilot-adapter-design.md`; gist: in-place extension of
  `context-budget.sh` (no new script) — composite child identity
  `<parentSessionId>+<toolCallId>` via the existing `--agent-id` flag
  (task children have no session); `children` grows a copilot-cli branch
  (events.jsonl `subagent.started` scan cross-checked against
  `session-store.db::assistant_usage_events initiator='sub-agent'` — the
  hedge for unverified background/`write_agent` streams); measurement
  keeps claude context-size semantics — last usage row's
  `input+cache_read+cache_write` per agent_id, `method=exact`, WAL-sidecar
  snapshot before reading; `subagent.completed.totalTokens` demoted to
  estimate-only fallback (lifetime sum, not context size); per-child locks
  and R4 dispatch records reused verbatim; escalation is post-hoc/external
  only (sync `task` blocks the parent; push tier closed by ticket 06).
  Build = execution work, out of map scope: backlog row added (incl.
  slice-0 probe + `copilot_cli_measure` sqlite-first upgrade), unscheduled.
- Map updated: ticket-09 decision line, fog patch cleared (Not-yet-specified
  now holds only the ticket-08-dependent threshold-config item), Out-of-scope
  line for the adapter build. Launcher REPLACED (frontier = ticket 08 only,
  HITL; AFK sessions have no map work left).
- No code/tests touched (design-only session). No dispatches opened.

**Suggested skills (next session):** wayfinder (ticket 08, ONLY if user is
live — grilling, HITL); session-rollover at WARN/STOP.

**Learnings:** none new (the two session-24 parked learnings did not
re-strike; register-time artifact path did go worktree-stale again after
EnterWorktree — already an open backlog finding, second strike noted there
if it bites a check).

**Wrap:** clean end at ~113K (OK, below WARN) — ticket resolved, map has
no AFK frontier left, so the session wrapped rather than idling toward
WARN. Committed, pushed. Session-23 block archived (two-block rule).

