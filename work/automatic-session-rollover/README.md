# Automatic Session Rollover — close the manual relaunch gap in the rollover pipeline

Governing skill(s): — (design discussion; the deliverables modify
`skills/session-rollover/SKILL.md` and add `scripts/launch-next-session.sh`).

**Start here:** `next-session.md` (catch-up launcher) → `handoff.md`
(session ledger, top block).

## What this is

When the context budget hits WARN/STOP, the agent runs `session-rollover` and
the user must then copy-paste (or retype) a bootstrap prompt into a fresh
session — and looser hand-typed phrasings measurably underperform. This project
designs and ships the automation that closes that gap across all supported
runtimes (Claude Code, Codex, Gemini, OpenCode): a `launch-next-session.sh`
script, workspace parameters making the behavior optional, and hardening of
rollover *triggering* reliability on non-Claude runtimes. Spun out of
`work/template-maintenance/` (2026-08-05) because it deserves a focused
discussion rather than a queued side mission.

## Files

- `next-session.md` — forward launcher (what to do next). REPLACED each rollover.
- `handoff.md` — session ledger (what happened). APPEND newest-on-top; archive
  to `handoff-archive.md` when it exceeds the two most recent sessions.
- `relaunch-analysis.md` — the grounding analysis: pipeline concept, verified
  per-vendor launch/detection matrix, demo results, proposed knobs, open
  questions.
- `rollover-scenarios.md` — authoritative scenario catalog (S11–S52) for the
  subagent-rollover design: dimension set + mainline/edge/measurement
  scenarios with pass criteria; extends S1–S10 in the research note and is
  mirrored in `subagent-rollover-research.html` §7.
