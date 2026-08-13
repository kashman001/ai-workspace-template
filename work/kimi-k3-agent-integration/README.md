# Kimi K3 Agent Integration — use Kimi K3 as an agent runtime in this workspace

Governing skill(s): `superpowers:brainstorming` (design phase; implementation skill TBD once runtime is chosen).

**Start here:** `next-session.md` (catch-up launcher) → `handoff.md`
(session ledger, top block).

## What this is

Figure out and wire up how to drive this workspace template with Moonshot AI's
Kimi K3 model through an agent runtime. Constraint: Moonshot subscriptions are
not available to us, so access is **API-key only** (pay-per-token). Candidate
runtimes: OpenCode (already a supported template runtime), Kimi CLI (would be a
new seventh runtime), or Claude Code pointed at Moonshot's Anthropic-compatible
endpoint. Outcome: a chosen runtime, working config, and whatever template
wiring (hooks, context-budget, docs) that choice requires.

## Files

- `next-session.md` — forward launcher (what to do next). REPLACED each rollover.
- `handoff.md` — session ledger (what happened). APPEND newest-on-top; archive
  to `handoff-archive.md` when it exceeds the two most recent sessions.
