# Clear Session Loop — research whether `/clear` can drive the session loop, then spec it

Governing skill(s): `research` (research doc), `to-spec` (spec), `session-rollover` (the loop being changed).

**Start here:** `next-session.md` (catch-up launcher) → `handoff.md`
(session ledger, top block).

## What this is

Today the session loop rolls over at context WARN/STOP to a fresh process
(`launch-next-session.sh`, supervised by `session-loop.sh`); `/clear` is used only
in the attended, Claude-only `--clear` path because an agent cannot press `/clear`.
This effort researches whether a same-process `/clear`-style reset can drive the
loop — including unattended — across Claude Code, Codex, Copilot, Gemini CLI and
the VS Code chat agents, and how subagents behave across it. If the research says
it is worth doing, it ends with a spec that feeds `/plan`.

## Success criteria

1. `research.md` exists: covers the video, `/clear` semantics and hooks in Claude
   Code, every loop component it touches, subagent behaviour, and a per-runtime
   support matrix (CLI + VS Code chat) with fallbacks, and the current loop's
   limitations (incl. multiple concurrent sessions per work item) with whether
   this approach lifts each; ends with a go / no-go
   recommendation. Claims not verified live are marked as such.
2. Key claims spot-checked by the orchestrating session against the repo/docs,
   recorded in `research.md`.
3. If go: `spec.md` exists per `docs/agents/issue-tracker.md` → "Spec
   conventions", ready to turn into a plan. If no-go: no spec; the reason is in
   `research.md` and the ledger.
4. Each document has an up-to-date self-contained HTML twin (`research.html`,
   `spec.html`) for the user to read.
5. The user has reviewed both documents.

## Files

- `next-session.md` — forward launcher (what to do next). REPLACED each rollover.
- `handoff.md` — session ledger (what happened). APPEND newest-on-top; archive
  to `handoff-archive.md` when it exceeds the two most recent sessions.
- `context-budget.env` — per-item `ROLLOVER_RELAUNCH=auto` so `session-loop.sh` may chain it.
- `research.md` — research findings (to be written).
- `spec.md` — the spec, only if research recommends go (to be written).
- `research.html`, `spec.html` — rendered reading copies of the above; regenerate after edits.
- `s14-runbook.md` — human steps for the S14 probe (two `/clear` rollovers).
- `probes.md` — S14 probe results, one row per run (created by session #6).
