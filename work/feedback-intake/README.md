# feedback-intake — Route production/user signal into discovery (the N7→N1 edge)

Governing skill(s): — (none yet; the effort will likely *produce* a skill).

**Start here:** `next-session.md` (catch-up launcher) → `handoff.md`
(session ledger, top block).

## What this is

Close gap **G1** from the SDLC map (`work/sdlc-ai-mapping/sdlc-map.md`, gap
register + N1/N7 entries): the workspace has no convention or skill that
routes real user signal — telemetry, experiment results, user research,
support tickets, feedback corpora — back into discovery. The map rates this
High severity because the N7→N1 edge is the steady-state loop's first edge:
for a live product, most new work *starts* there, and today nothing carries
that signal into the workspace where `to-spec`/`triage` can pick it up.

Existing pieces to build on, not duplicate: `rlm` (native) already analyzes
large feedback corpora; `triage` (native) owns the intake side of tickets;
`to-spec` turns conversation into specs. The missing piece is the routing
convention in front of them.

## Success criteria

- A documented intake convention exists (doc and/or skill) stating where
  incoming user/production signal lands in the workspace, in what form, and
  which existing skill (`triage`, `to-spec`, `rlm`) consumes it next.
- The convention covers at least: user-research/feedback corpora (N1 inbound)
  and operational signal (telemetry/experiment/incident learnings, N7→N1).
- The SDLC map's G1 row can be marked closed: N1 and N7 "GAP" notes have a
  named template capability to point to.
- Wired per template rules: agent-agnostic (works from CONTEXT.md for
  Codex/Gemini/OpenCode, not just Claude Code) and shipped/documented for
  template downloaders.

## Files

- `next-session.md` — forward launcher (what to do next). REPLACED each rollover.
- `handoff.md` — session ledger (what happened). APPEND newest-on-top; archive
  to `handoff-archive.md` when it exceeds the two most recent sessions.
