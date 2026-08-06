# 06 — Does mid-flight hook injection reach a running claude child?

Type: task (AFK — empirical verification on this machine)
Status: open
Blocked by: none
Map: ../map.md

## Question

Claude Code documents context injection landing "at the start of the
subagent's conversation" — reliable at dispatch, unverified as a mid-flight
push (research §3, §8 channels table). Verify empirically: dispatch a
long-running subagent, then, while it runs, emit hook output that should
inject (e.g. `PreToolUse`/`PostToolUse` `additionalContext`/stdout inside
the child, `agent_id` populated) and observe the child's transcript
(`subagents/*.jsonl`) and behavior.

The verdict decides whether the accelerator tier (in-flight WARN push into
running children) is buildable on claude at all, or whether the
dispatch-time contract remains the *only* parent→child channel:

- **Lands mid-flight** → accelerator tier is specifiable (graduates the
  fog patch in the map); design its wiring as a fresh ticket.
- **Dispatch-only** → record the refutation, close the accelerator-tier
  fog patch as out of scope, and the R2 contract stays the whole story.

Method sketch: hook script keyed on `agent_id` that flips output on a
sentinel file mid-run; child prompt = a multi-step loop with tool calls
(so `PreToolUse` fires repeatedly); success criterion = injected sentinel
text visibly present in the child transcript *after* its first turn.
