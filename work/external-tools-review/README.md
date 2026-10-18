# External Tools Review — evaluate four outside tools for what this template could adopt

Governing skill(s): `research` (per-track notes); `research-wave` if the user
invokes it for fact-checked parallel runs.

**Start here:** `next-session.md` (catch-up launcher) → `handoff.md`
(session ledger, top block).

## What this is

One review of four outside subjects, each checked against what the template
already provides, ending in a single holistic view of how to improve the
template. Research only — any track that turns into real integration work is
spun out as its own work item. Precedent: `work/deep-seek-harness-eval/`.

| Track | Subject | Source |
|---|---|---|
| T1 | Reverse Engineer Anything (REA) — staged method for agents to study an app feature and rebuild it; findings tagged seen / inferred / unknown | GitHub `morluto/rea` (owner unconfirmed — verify) |
| T2 | CLI-Anything — generates an agent-usable CLI (+ `SKILL.md`) for any program from source or API | GitHub `HKUDS/CLI-Anything` |
| T3 | Claude Code redesigned Projects — goal-driven coordinator chat delegating to parallel cloud threads, shared memory, library | https://claude.com/resources/articles/projects-redesigned (2026-09-17) |
| T4 | Phonon-2 — 164MB offline speech-to-text model (Better Stack video) | https://youtu.be/eskgvQYchd0 |

T3 overlaps `work/concurrent-sessions/` (several sessions owning one item) —
read its README before comparing, and cross-link findings rather than
duplicating them.

## Success criteria

1. `research/t1-rea.md` … `research/t4-phonon.md` exist. Each states what the
   subject is (from primary sources), what the template already has for the
   same need (with file pointers), the gaps it would fill, cost/risk of
   adopting (incl. agent-agnosticism and licence), and a verdict:
   adopt / adapt / learn-from / skip. Unverified claims are marked.
2. `synthesis.md` gives the holistic view: recommendations ranked by value
   to the template, grouped by theme rather than by tool, each tied to the
   track(s) it came from.
3. A plain-language one-page summary (glossary first, self-contained) with an
   HTML twin for the user to read.
4. The user dispositions each recommendation; accepted ones are filed as
   backlog cards in `docs/template-workspace-backlog.html` (or a spun-out
   work item), rejected ones recorded in `decisions.md`.

## Files

- `next-session.md` — forward launcher (what to do next). REPLACED each rollover.
- `handoff.md` — session ledger (what happened). APPEND newest-on-top; archive
  to `handoff-archive.md` when it exceeds the two most recent sessions.
- `research/` — one note per track (T1–T4).
- `synthesis.md` — the holistic view (written after all tracks land).
