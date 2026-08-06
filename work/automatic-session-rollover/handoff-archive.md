<!--
ARCHIVE of work/automatic-session-rollover/handoff.md — older ledger blocks,
newest first. Moved here when handoff.md exceeds the two most recent blocks.
-->

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
