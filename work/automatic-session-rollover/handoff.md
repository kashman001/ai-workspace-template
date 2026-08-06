<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-06 (session 27: sandbox discovery fix shipped + live-verified; ticket 08 RESOLVED — map destination REACHED)

**What shipped (main checkout, pushed to `origin/main`):**

- **Copilot-vscode sandbox discovery fix (`2c45bfe`).**
  `copilot_vscode_discover()` now derives the workspaceStorage hash from
  `$VSCODE_TARGET_SESSION_LOG` by parameter expansion and probes
  `chatSessions/<sid>.jsonl` directly (no `readdir` on `workspaceStorage/`);
  glob-and-grep kept as older-build fallback. Verified: fake-HOME harness
  incl. `chmod 311` readdir-blocked parent (7/7), all eight `scripts/tests/`
  suites green (326 asserts), AND live in-copilot run of the spec's Verify
  section (user-relayed): correct artifact pinned, no listing.
  `method=estimate` mid-first-turn is the designed pre-usage-flush degrade —
  same file measured `38152 exact` after the turn flushed. Recorded:
  backlog M10 second follow-up + changelog row; issue-01 session-27 update
  block (item 2 effectively closed — only the optional UI-meter comparison
  leg remains); spec file carries a Status: IMPLEMENTED+VERIFIED header.
- **Ticket 08 — per-role WARN/STOP thresholds: YAGNI (`18c5aee`), resolved
  live with the user (grilling, all four decision points confirmed).** One
  shared pair stands; thresholds encode where the model degrades, roles
  differ only in response to crossing; no task-role taxonomy exists to key
  on. Revisit trigger recorded in `docs/context-budget.md` → Thresholds.
  Premise correction: per-item `context-budget.env` overrides relaunch
  knobs ONLY — threshold plumbing unbuilt, deliberately. Full answer +
  rejected alternatives in `issues/08-per-role-thresholds.md`.
- **Map destination REACHED:** all §14.4 questions are recorded decisions,
  fog exhausted, no open tickets. Map body carries the completion note.
- Session start: registered primary (stale session-26 record swept);
  ff-pull required deleting a byte-identical untracked copy of the fix spec.

**Suggested skills (next session):** none standing — the map is complete.
Issue-01 items 1+3 are task-type HITL (need the user live in VS Code);
`session-rollover` at WARN/STOP as ever.

**Learnings:**
- `git pull --ff-only` refuses when an untracked file matches an incoming
  tracked path — diff against the incoming blob first (here byte-identical
  → safe delete), then pull (1st strike, parked).
- Copilot Chat flushes `promptTokens` to chatSessions only at turn end —
  mid-turn checks size-estimate by design (routed: issue-01 update block +
  spec status note, not conversation-only).

**Wrap:** WARN rollover at ~132K after ticket-08 resolution. All work
committed and pushed (`2c45bfe`, `18c5aee`). Session-25 block archived
(two-block rule).

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
