<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 11 (2026-08-29): L43 delivered — ledger archives fixed, lineage-restart marker shipped; arc complete

**What got done (all committed & pushed to main):**
- Re-filed the four misfiled blocks (11, 10, 9, 16) in
  `work/automatic-session-rollover/handoff-archive.md` into newest-first
  position — whole blocks moved, content untouched.
- context-decay posture settled: taught `scripts/check-ledger.py` an explicit
  `<!-- ledger-lineage-restart: … -->` marker (restarts the NUMBER chain at
  the block below; dates still check across the seam) and placed one, with a
  human-readable two-lineage explanation, at the seam in
  `work/context-decay/handoff-archive.md`. Renumbering rejected — see
  decisions.md 2026-08-29 L43 note.
- Marker documented in `docs/work-directory-conventions.md` → "Lineage
  restart (rare)"; mutation suite extended to 12/12 (restart-without-marker
  and marker-hidden-date-regression both caught).
- Repo-wide `scripts/check-ledger.py` exits 0 — first time since M32 made the
  gate honest. Backlog: L43 → archive with Fixed: note; 6 open / 75 resolved.

**State at close:** main carries the fix + this close commit; user's checkout
pulled current. Worktree `tm-s11-l43` disposable. The L43 arc (M31→M34, L41–L43)
is fully drained; no queued mission — session 12 picks from the backlog's 6
open cards.

# Session Handoff — 10 (2026-08-29): setup-docs audit applied (M34) + workspace currency done

**Summary:** Both directive items delivered. All 18 setup-docs audit findings
(F1–F18) fixed, tested, ff-pushed to main (`34f8dce`); filed + resolved as
backlog card **M34** (archive), scorecard 74. User's checkout brought current
and cleaned. L43 deferred (headroom: 98K at decision point; it needs a
deliberate pass).

**Shipped (commit 34f8dce):**
- F1/F2: workspace-structure.html regenerated (was instructing pre-M31
  double-wiring); F3/F16/F17 hand-fixed in setup-guide.html (tracked-vs-
  gitignored split, `cp -n`, `npm install -g ccstatusline`).
- F4–F7: phantom "MCP token export" / "setup.sh wires claude hooks" purged.
- F8: check-dependencies.sh `graphifyy[mcp]` package name (the install bug).
- F9/F10: runbook tool list + new "wiring checks" section (hooks restore,
  Copilot trustedFolders).
- F11–F15 md rewords; F18 test D3 → tracked settings.json. Suite 5/5;
  check-workspace-structure exit 0. Audit file stamped APPLIED.

**Workspace currency (user's checkout):** was already on main (launcher's
"sits on vendor branch" claim stale); pulled to `34f8dce`. Deleted merged
`vendor-mattpocock-skills` (local + origin). Removed merged worktrees
`m31-close` (unlocked first) + `tm-s9` and their branches. M31 verified live:
hook wiring only in tracked `.claude/settings.json` (local file has none —
hooks fire once; local carries only permissions/MCP enables).

**Decisions:** deferred L43 rather than starting it at 98K tokens — its card
demands a deliberate pass (ledger-content re-file + checker-posture decision),
not a tail-of-session drive-by. Removed `tm-s9` worktree beyond the explicit
directive (fully merged, this work item's own detritus).

**State:** main = `34f8dce`; user's checkout on main, current, clean. Only
foreign worktrees remain (`doc-review-skill`, `learn-agentic-workflows-s2`).
Repo-wide `check-ledger.py` still exits 1 (L43's two archives — the one open
thread).

**Learnings:** none beyond the ledger.

**Suggested skills next:** none special — L43 is targeted edits + one design
decision; session-rollover at WARN.

