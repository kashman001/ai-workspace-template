# Wayfinder map — child-rollover open questions (research §14.4)

Label: wayfinder:map. Tickets are `issues/NN-<slug>.md` per
`docs/agents/issue-tracker.md` → "Wayfinding operations". Note: issues
01–05 predate this map (standalone investigation issues, not wayfinder
tickets); map tickets start at 06.

## Destination

The three open questions research §14.4 left unresolved are each a recorded
decision, so the **accelerator tier** (in-flight WARN injection into
children) and the **copilot measured-tier adapter** can be planned — or
ruled out — without re-opening the research, and the threshold config
question stops recurring in handoffs.

## Notes

- Source of truth: `subagent-rollover-research.md` §3 (signal path), §8
  (channels table), §11 (three-tier layering); `subagent-vendor-survey.md`
  caveats 4–5; `smoke-test-copilot.md` (live copilot 1.0.78 facts).
- Constraints already decided (do not re-litigate): dispatch-time contract
  is the load-bearing channel — hook injection is an accelerator, never a
  dependency (R2, ADR-0005); coordination state is repository-keyed
  (ADR-0006); role schema is final.
- Resolved tickets are Tier-2 decisions (tracker doc → "Decision-log
  tie-in"); promote only lasting-weight answers.
- Grilling tickets are HITL — they wait for a session where the user is
  live; AFK sessions take the task/research frontier first.

## Decisions so far

<!-- one line per closed ticket: gist + link -->

(none yet)

## Not yet specified

- **Accelerator-tier design** (claude in-flight WARN push into running
  children): shape depends entirely on ticket 06's verdict — don't ticket
  until the injection path is confirmed or refuted.
- **Copilot measured-tier adapter** (child artifact discovery +
  `check --transcript` + per-child locks for copilot): specifiable only
  after ticket 07 locates (or rules out) per-child artifacts.
- **Per-role threshold config shape** (if ticket 08 decides they earn
  their keep): where overrides live given the existing per-work-item
  `context-budget.env` override mechanism.

## Out of scope

- Build slices already tracked in the work item's `plans/` (R6 drain mode,
  hook-wiring throttling/ledger writes) — execution work, not decisions on
  this map.
- Issue 04 (in-place `/clear` relaunch) — parked by the user; not scheduled
  unprompted.
- Issue 01 (VS Code agent-mode hooks) — spun out; needs a machine profile
  this workspace doesn't control.
