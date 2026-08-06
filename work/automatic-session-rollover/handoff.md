<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-06 (session 28: issue-01 items 1+3 VERIFIED live; housekeeping done; build hands off)

**What shipped (worktree `session-28-issue-01-vscode`, pushed to `origin/main`):**

- **Issue-01 items 1+3 VERIFIED (`64c3f85`).** The full verified VS Code
  1.132 agent-hooks contract + a numbered build spec live in
  `issues/01-vscode-agent-mode-hooks.md` → "Update … (session 28)". Gist:
  `code chat -r -m agent "<prompt>"` works from an agent shell (item 3);
  hooks fire from `.github/hooks/*.json` with PascalCase events and
  snake_case Claude-style payloads carrying `transcript_path` from which
  the promptTokens chatSessions artifact is derivable (self-measure blocker
  dissolved); in-band = SessionStart `hookSpecificOutput.additionalContext`
  (verified) + Stop **exit-2 stderr** block (verified; JSON
  `decision:block` IGNORED). Method: 3 probe runs relayed via the user's
  live VS Code, read back from the hook-provided transcripts.
- **Housekeeping COMPLETE:** all 12 disposable worktrees removed + pruned,
  their merged `worktree-*` branches deleted; `session-26-pre-reconcile`
  deleted by the user via `!` (permission classifier blocks
  `git branch -D` even user-approved — 1st strike, parked).
- **Build NOT started** — that is session 29's whole mission; spec is in
  the ticket, nothing lives only in conversation.
- **Probe files intentionally left in the user's main checkout**
  (untracked): `scripts/hooks/vscode-hook-probe.sh`,
  `.github/hooks/vscode-probe.json`, `.vscode-hook-probe.jsonl` — build
  spec step 3 (hook-process cwd / relative-command verification, probe v4)
  still needs them. Delete only after the real wiring ships.

**Suggested skills (next session):** none beyond the standard set;
`superpowers:verification-before-completion` before claiming the build done;
`session-rollover` at WARN/STOP.

**Learnings:**
- Copilot's model may refuse hook-injected `additionalContext` as prompt
  injection while OBEYING the Stop exit-2 forced-turn instruction in the
  same session (routed: ticket's session-28 block, behavioral caveat).
- Claude Code's auto-mode classifier blocks `git branch -D` regardless of
  user approval in chat — hand force-deletes to the user via `!` (1st
  strike, parked).

**Wrap:** WARN rollover (~124.6K at trigger); findings flushed to the
ticket BEFORE the rollover decision, so the handoff carries pointers only.
Session-26 block archived (two-block rule).

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

