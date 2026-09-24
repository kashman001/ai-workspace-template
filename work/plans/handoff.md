<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2 (2026-09-23): grill closed, verdict BUILD, concept + spec + 11 tickets; rolled at WARN

**Summary.** Seq 2, supervised chain, launched interactive for the grill.
The user was present. Two grill rounds settled all seven open points
(recommended answers taken on every one; the user asked for plain-language
explanations on the Stop-hook and node-kind questions before deciding).
Landed: seven new notes in `decisions.md` (no "(proposed)" left; both OPEN
sections resolved in place), `concept.md` (definition, five properties,
glossary, this item as a worked plan in node-file form), README status line
= BUILD, `spec.md` (36 stable S-items, two testing seams: the `plan.sh`
command line and the existing session-loop fake-child harness), eleven
tracer-bullet tickets under `issues/` approved by the user as listed,
backlog card L48 (wayfinder as a plan template, deferred). WARN hit right
after the tickets; wrapped up here.

**Decisions this session** (why + rejected in `decisions.md`): build format
+ `plan.sh` + loop hook, no runner; `blocked` explicit / `done` verified
only; HITL nodes have no `check`, human tick, interactive rollover when only
HITL remain; `<!-- plan:begin/end <name> -->` markers; `kind: work |
reconcile | hitl`; integration = all parts except the Stop/SessionEnd hook;
wayfinder untouched in v1 (L48).

**State.** All of the above committed by this rollover. Branch main, nothing
pushed. Spec approved by the user in this session;
tickets are `ready-for-agent`. Frontier: ticket 01 only.

**Next.** `next-session.md` → implement ticket 01 with `implement` + `tdd`.

**Key files.** `work/plans/spec.md`, `work/plans/issues/01-*.md`,
`work/plans/concept.md`, `work/plans/decisions.md`.

# Session Handoff"

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
