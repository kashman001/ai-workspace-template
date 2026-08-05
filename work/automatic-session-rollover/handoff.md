<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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
