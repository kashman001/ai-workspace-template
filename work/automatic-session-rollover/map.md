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

- **06 — mid-flight hook injection: REFUTED (dispatch-only stands).** Hooks
  fire on child tool calls (parent-keyed, shared throttle/escalation) but
  their exit-2 stderr is dropped — reaches no conversation. Accelerator
  tier closed for hook wiring; model-mediated SendMessage push noted as the
  surviving parent-behavior alternative. Bonus: swallowed-WARN defect →
  template backlog. (`issues/06-midflight-hook-injection.md`, session 24)
- **07 — copilot child artifacts: FINDABLE + PARSEABLE (adapter buildable).**
  Keyed by parent `task` toolCallId: session `events.jsonl` child events +
  `session-store.db::assistant_usage_events` token rows. Fog patch
  graduated to design ticket 09. (`issues/07-copilot-child-artifact-location.md`,
  session 24, gen 2)

## Not yet specified

- ~~Accelerator-tier design~~ — CLOSED by ticket 06 (refuted for hook
  wiring; out of scope. A parent-behavior SendMessage checkpoint push could
  be charted later if wanted — not scheduled).
- ~~Copilot measured-tier adapter~~ — GRADUATED to ticket
  `issues/09-copilot-adapter-design.md` (open, AFK-able).
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
