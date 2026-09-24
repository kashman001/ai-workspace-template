<!--
PURPOSE: ARCHIVE of the ledger (handoff.md). Older "# Session Handoff"
blocks, newest on top. Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 1 (2026-09-23): seam inventory + decisions from the concept discussion; rolled at WARN before the grill

**Summary.** First registered session (seq 1, supervised chain). The user
drove the concept in conversation instead of a formal grill; the agent
grounded each point against the workspace and proposed formats. Two files
landed: `seams.md` (ten mechanisms vs. the plan concept, every line claim
verified on disk; two Explore subagents did the reading, spot-checked by the
parent) and `decisions.md` (ten notes: nine **settled**, one **proposed**,
plus two OPEN items). Rolled over at the WARN threshold with the user's
consent, option "roll over now".

**Decisions (see `decisions.md` for the why and the rejected alternatives).**
Node = one session's budget, split on overrun; plans under
`work/<item>/plans/NN-<slug>/`, one open at a time; chain sessions are
orchestrators; waves end in a named reconcile node; parallelism = subagents
within a session, sessions serial, `parallel` caps on node and wave; tiers
abstract (`frontier|standard|cheap|auto`), uniform by default, lookup table
on `auto`, rise at fan-in; replan = capture now (`note`), restructure at
reconcile, authority by blast radius; optional `chain.plan` + `plan_closed`
verdict for the loop; `plan.sh` state tooling (bash+jq, derive-don't-decide),
never a runner; "work item" not "worktree". Proposed, unconfirmed: node files
as truth + rendered `plan.md` index, status set `todo|doing|done|blocked|dropped`.

**Current state.** `seams.md`, `decisions.md` new and committed by this
rollover. No `concept.md`, no `spec.md`, no build verdict on the README
status line. Branch main, nothing pushed.

**Open questions (for the grill).** Build/no-build verdict; confirm the node
file format and status set; `check` semantics for HITL nodes; marker
convention for generated blocks (none exists in the workspace); the
integration question the user raised last: how plans enter the template and
how agents learn them — proposed answer under "OPEN" in `decisions.md`.

**Suggested skills.** `grill-with-docs` on the OPEN items only (the settled
notes are not to be re-litigated); `decision` to record each answer;
`to-spec` once the verdict is build.

**Key files.** `work/plans/seams.md`, `work/plans/decisions.md`,
`work/plans/README.md`, `skills/grill-with-docs/SKILL.md`.

# Session Handoff — 2026-09-23 (scaffold): item created; concept exploration comes next

**Summary.** Scaffolded by a session not bound to this item (so this block
carries no session number; the counter starts at the first
`register --project plans`). The user asked for a work item to explore the
concept of **plans** in this workspace: plans that use graphs, loops, and
sessions to accomplish work in a structured, dependency-aware,
parallelism-aware, and LLM-tier-aware way. A quick survey found the
ingredients already present but disjoint (`to-tickets` blocking edges,
`wayfinder` map/frontier, Workflow tool + `research-wave` fan-out, `/loop`
and `session-loop.sh` chaining, `rlm` root/leaf tiers, launcher/ledger), so
the README frames the item as "should one artifact join them, and what would
it be" rather than "build a runner". The local-only `learn-agentic-workflows`
teaching item (gitignored) covers the graph-orchestration background and may
be worth a read when charting.

**State.** README (goal, success criteria pending a build/no-build verdict),
launcher (seam inventory → grill → concept note), this ledger; row added to
`work/README.md`. No `seams.md`, `concept.md`, `decisions.md`, or `spec.md`
yet. Not committed by the scaffolding session.

**Next.** `next-session.md` → seam inventory, then grill the concept.
