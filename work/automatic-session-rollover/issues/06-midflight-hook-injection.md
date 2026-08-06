# 06 — Does mid-flight hook injection reach a running claude child?

Type: task (AFK — empirical verification on this machine)
Status: resolved (session 24, 2026-08-06)
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

## Answer

**Dispatch-only. Refuted for the hook channel** — empirically, on this
machine, with the production wiring (evidence log:
`../research/06-midflight-hook-injection.md`):

- PostToolUse hooks DO fire on a running child's tool calls, but keyed to
  the PARENT session_id (shared throttle stamp + shared escalation state),
  and their exit-2 stderr is dropped for those fires — the emitted
  CONTEXT BUDGET WARN reached no transcript (parent, child, or grandchild)
  when the real 120K threshold crossed mid-run at 15:10:35.
- The accelerator-tier fog patch closes as out of scope for hook wiring:
  the R2 dispatch-time contract stays the only hook-automatic parent→child
  channel (ADR-0005 layering empirically confirmed).
- Surviving alternative (not hook wiring, model-mediated): the parent can
  SendMessage a running background child; harness-level mid-run appends
  into children demonstrably exist (token-budget lines, roster updates).
  A WARN-ing parent ordering its open children to checkpoint per contract
  is a parent *behavior*, chartable separately if ever needed.
- Bonus defect found: a busy child consumes the parent's one-shot WARN
  escalation on a dropped-output fire → the parent never sees the in-band
  push (escalation-only never re-emits). Tracked in the template backlog.
