<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 3 (2026-10-18)

## Summary
User added two subjects: T5 ("Claude Changed Completely" video, read for
cross-agent carry-over) and T6 (OpenViking). Ran both as parallel subagents;
spot-checked load-bearing claims at source (goal + sub-agents docs; `gh api`
license/relicense commit and integration docs). Both learn-from. Synthesis
extended to R17–R24 (themes E, F); summary.md/.html updated. User accepted
all recommendations; dispositions filed. **Item closed — all four success
criteria met.**

## Decisions
- `decisions.md` → "Disposition of R1–R24": R6 reword; R11/R12 rejected; R5,
  R18 later. Cards L94 (doc pass), L95 (dispatch contract, work item when
  started), L96 (R21 overnight risk), L97 (R5), L98 (R18); L93 now "reword,
  do in L94". R1 → `work/concurrent-sessions/input-external-tools-review.md`.

## Current state
- Committed on `main` (not pushed). No processes. No plan.

## Corrections
- T5's "7 of 9 skill packs no better than a dummy" claim is unsourced; R17
  rests on Anthropic's baseline guidance instead.
- OpenViking is AGPL-3.0 since PR #1085 (2026-03-30); was Apache-2.0.

## Suggested skills
- L94: none special (doc edits). L95: `create-work-item`, then `tdd`.

Learnings:
- A video of "new Claude features" is mostly Claude-only; for an
  agent-agnostic template, read it for methods, not features.

# Session Handoff — 2 (2026-10-18)

## Summary
Ran T1–T4 as four parallel subagents; each wrote `research/tN-*.md`. Spot-checked
each note's three load-bearing claims at source (gh API / cloned repos / official
docs); all held. Wrote `synthesis.md` (R1–R16 in four themes), `summary.md` +
`summary.html` (on the html-kit prototype; rendered and checked). Verdicts:
T1 REA learn-from, T2 CLI-Anything learn-from, T3 Projects learn-from, T4
Phonon-2 skip. Nothing adopted or vendored.

## Decisions
- `decisions.md`: T1 ideas go to workspace-owned `research-wave`, not the
  vendored `research`/`prototype` skills; HTML twin built on the kit.

## Current state
- Committed this session (see git log). Filed backlog card **L93** (docs/mcp-setup.md
  calls the yt-dlp MCP server a CLI — verified T2 side finding; = R6).
- Success criteria 1–3 met. Criterion 4 (user dispositions R1–R16) is open.

## Open questions
- The user's yes / no / later on each of R1–R16 (`summary.md` → "What I need from you").

## Corrections to the brief (recorded in synthesis.md)
- REA is mostly a tool, not a staged method; tags are observations/inferences/unknowns.
- Projects' local threads already exist via Remote Control (article said "coming soon").

## Suggested skills
- `decision-log` for rejections; backlog card format per `docs/template-workspace-backlog.html` → Maintaining.

Learnings:
- Before recommending an edit to a skill, check whether it is vendored (keep-unmodified header).

# Session Handoff — 2026-10-18 (session 1: scaffolded; four tracks identified)

User asked to evaluate four outside subjects for template benefit and wanted
a holistic view. Agreed one work item over four (shared synthesis, overlapping
tracks, small tracks). Identified subjects: T1 REA (`morluto/rea`, owner seen
in one source only), T2 HKUDS/CLI-Anything, T3 Claude Code redesigned Projects
(user supplied the article link), T4 Phonon-2 speech model (video metadata
read; likely low relevance — not yet assessed). Scaffolded README, launcher,
ledger, `research/`. Next: run the four tracks.
