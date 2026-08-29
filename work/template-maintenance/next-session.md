<!-- LAUNCHER: forward-looking only; REPLACED at each rollover. History: handoff.md -->

# Next Session — template-maintenance (session #11)

## Mission

**L43** (last open thread of this arc): two historical handoff archives fail
the now-honest repo-wide `scripts/check-ledger.py` (exits 1; every per-project
run is green). One deliberate ledger-content pass:

1. `work/automatic-session-rollover/handoff-archive.md` — genuine misfilings:
   session 11 (2026-08-06) filed below session 1 (2026-08-05) at ~:996/:1015,
   session 16 below session 9 at ~:1076/:1109. Re-file the blocks into
   newest-first date order (move whole blocks; content untouched).
2. `work/context-decay/handoff-archive.md` — dates ARE ordered; the session
   *numbering restarted* mid-project (earlier lineage's 4b below a later
   lineage's 3, ~:34/:100). Decide the posture: annotate the restart in the
   archive so a human isn't confused AND make the check pass — either teach
   `check-ledger.py` an explicit restart marker (mutation-test it in
   `scripts/tests/test-check-ledger.py`), or renumber/retitle the later
   lineage's headings. Session #9 already rejected silently widening the
   ordering rule to tolerate restarts — don't relitigate that; a marker must
   be explicit and rare.
3. Verify repo-wide `scripts/check-ledger.py` exits 0; resolve L43 (card →
   archive with Fixed: note, scorecard 6 open / 75 resolved), commit, ff-push
   to main (authorized pattern).

**No-human-in-the-loop:** buildable unattended. Work in a worktree; push to
main; pull the user's checkout current after (`git pull --ff-only`).

## Read these, in order

1. Backlog card L43 (`grep -n 'L43' -A 15 docs/template-workspace-backlog.html`).
2. The two archive files — targeted reads around the cited lines only; line
   numbers were taken at `dcebc95`, re-verify before editing.
3. Only if adding a restart marker: `scripts/check-ledger.py` +
   `scripts/tests/test-check-ledger.py`.

## Do NOT reload

- The setup-docs audit / M34 — delivered (`34f8dce`), card in the archive.
- M31/M32/M33 history — settled; M32's grammar is what made the gate honest.
- The peer message / downstream commits — fully consumed at sessions #8–9.

## State snapshot

- main = `34f8dce` (M34 audit fixes + session-10 close). Backlog: 7 open
  (incl. L43) / 74 resolved.
- User's checkout: on main, current, clean. Vendor branch and the
  `m31-close`/`tm-s9` worktrees are gone; `doc-review-skill` and
  `learn-agentic-workflows-s2` worktrees belong to OTHER work — leave them.
- `.claude/settings.json` (tracked) carries the Claude hook wiring; local
  file is personal-only. Verified live session #10.

## First actions

1. `scripts/context-budget.sh register --project template-maintenance`
2. Work the mission top-down; verify with repo-wide `check-ledger.py`.
3. `scripts/context-budget.sh record --label "L43 done"`; close per
   conventions (ledger block + launcher replacement + push).
