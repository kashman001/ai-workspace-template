---
name: plans
description: >
  Drive a work item's plan (docs/plans.md) where scripts/plan.sh cannot: create
  a plan from a spec or from tickets, run a reconcile node (join a wave, verify
  on disk, record decisions, replan), replan on its own, and dispatch a subagent
  onto one node with the prompt template. plan.sh owns every state write.
disable-model-invocation: true
---

# plans — create, reconcile, replan

> **Vendor-neutral skill.** Plain markdown any agent (Claude Code, Codex, Gemini
> CLI, OpenCode) can read and drive. Claude Code also exposes it as `/plan`
> (`.claude/commands/plan.md`, a thin wrapper around this skill).

`scripts/plan.sh` derives and writes; it never decides. This skill is the
deciding side: which nodes a plan has, whether a wave's work is really on disk,
what a replan may touch. Format, verbs, check rules, tiers, replan authority:
`docs/plans.md` — read it once before the first procedure; nothing below
restates it. Every write goes through a `plan.sh` verb. The hand edits are
prose (Goal, Acceptance, `plan.md` sections) and the two file moves the split
and a same-wave `add` need (below); `status` is never hand-written.

Every verb below takes `--project <item>` unless the session is bound to the
item (`context-budget.sh register --project <item>`); a session bound to one
item that works another's plan passes it explicitly.

## Create a plan

From tickets (`work/<item>/issues/NN-*.md`) or from a spec's stories. Both end
with `plan.sh check` silent.

1. **Open.** `scripts/plan.sh new <slug>` (refuses while a plan is open — one
   per item; close the old one first). Fill `plan.md`'s title, `## Goal` and
   `## Out of scope` by hand; set `replan: local | structural` (who may
   restructure — see "Replans" in `docs/plans.md`) and `default_tier`.
2. **Waves.** A node's wave is one more than the longest chain of blockers
   behind it (a node with none is wave 1). Compute waves for every ticket or
   story first, then add in wave order — ids follow `add` order, and a wave's
   reconcile node must be the last id in its wave.
3. **Add, wave by wave.** For each ticket or story in the wave:
   `scripts/plan.sh add <slug> --wave <n> --title "Ticket NN — <title>"
   --blocked-by <ids>` — the ticket's `Blocked by:` mapped to the node ids you
   have just created (keep a ticket→node list as you go; the numbers differ).
   `--kind hitl` for a step only a person can do; `--tier`/`--leaf`/`--check`/
   `--loop`/`--parallel` when the ticket says so. Then close the wave:
   `scripts/plan.sh add reconcile-w<n> --wave <n> --kind reconcile
   --blocked-by <every work id in the wave> --title "Join wave n"`.
4. **Body.** Into each node file, under `## Goal`: a `Ticket: issues/NN-….md`
   pointer line and the ticket's "What to build" paragraph (from a spec: the
   story text and a `Spec: S<n>` pointer); under `## Acceptance`: the ticket's
   checkbox lines, ticked as they are. A reconcile node's Acceptance is the
   three boxes of "Run a reconcile node" below.
5. **Carry status.** A ticket already `done`: `scripts/plan.sh done <id>
   --force --by import` (Log: `- import · done (forced from todo)`); a wave
   whose work nodes are all done gets its reconcile node the same way. Every
   other ticket stays `todo`; `blocked` is never imported — a ticket stuck on a
   person becomes a `hitl` node instead.
6. **Lint, wire, render.** `scripts/plan.sh check` — silent, or fix every line
   it prints (an `add` after the reconcile in the same wave is renamed below it:
   "Replan", rule 1). The launcher needs the `<!-- plan:begin position -->` /
   `<!-- plan:end position -->` pair once (`create-work-item --plan` scaffolds
   it; `docs/work-directory-conventions.md` → "Generated blocks"), then
   `scripts/plan.sh sync`. `status`, `frontier` and `graph` should read as the
   tickets did; a chain binds to the plan with `session-loop.sh <item> --plan
   <slug>`.

Done when `check` is silent, `frontier` names the first ready node, and the
board and the launcher's Position block agree with `status`.

## Run a reconcile node

The wave's join. `frontier` names it once every work node in the wave is
`done` or `dropped`; it runs in the orchestrating session on the strongest
tier, never in a subagent.

1. `scripts/plan.sh start <id>`.
2. **Verify on disk.** For every node the reconcile node is `blocked_by`:
   `show <id>` and read its Acceptance and Log; every ticked box is a claim —
   open the file, run the command, read the test output it names.
   `scripts/plan.sh verify <id>` re-runs a node's `check`. A claim that does
   not hold: the node is already `done` and `done → blocked` is not a
   transition, so `add` a follow-up (Replan, rule 1) and log the finding on
   the reconcile node.
3. **Record.** Each fork the wave settled → a Tier-2 note (`decision-log`
   skill); each discovery not yet a node → `scripts/plan.sh note "<text>"`.
4. **Replan** within authority — the "Replan" procedure below, every change
   as a `## Replans` line in `plan.md`.
5. Tick the reconcile node's Acceptance boxes (verified on disk · decisions
   recorded · replan applied, `check` silent), append a Log line with the
   verdict, then `scripts/plan.sh check` and `scripts/plan.sh done <id>`.
   `done` does not look at blockers, so anything the replan added is a node
   for the next wave, not a new blocker of the node being closed.

## Replan

Authority is the plan's `replan:` line and the ladder in `docs/plans.md` →
"Replans": **local** (agent, any time) · **structural** (the reconcile node,
hands-off only when `replan: structural`) · **goal** (a person: close the
plan, open the next). A change above the plan's authority is not made
silently — `add` a `kind: hitl` node carrying the proposal as its Goal (in the
next wave, or a new last wave when there is none — a hitl node only asks) and
`note` it; the person answers with `done <id> --by human` or `drop`.

1. **Follow-up in a wave that already has its reconcile node** (local):
   `add` numbers the node after the join, which `check` refuses
   (`reconcile-last`). Give it the number of the node it follows with a
   suffix — `mv nodes/19-<slug>.md nodes/11-<slug>.md`, set `id:` to match —
   and add the new id to the reconcile node's `blocked_by` (the split at
   rollover does the same: `skills/session-rollover/SKILL.md` step 3). Found
   mid-wave → same wave; found at the join → next wave.
2. **Split** an oversized node (local): the rollover split, verbatim.
3. **Drop** a node (structural): `scripts/plan.sh drop <id> "<reason>"`;
   nodes that were blocked by it stay valid (dropped counts as satisfied).
4. **New wave / cross-wave re-edge** (structural): `add --wave <n>` for the new
   nodes and its reconcile node last; an edge change is a `blocked_by` edit,
   after which `check` must be silent.
5. **Always:** one line under `## Replans` in `plan.md` —
   `- <date> (<reconcile id>): <what> — <why>. Local|Structural replan.` — then
   `scripts/plan.sh check` and `scripts/plan.sh sync`. A `wave-size` violation
   means the wave should split, not that the limit should move.

## Subagent prompt template

The orchestrating session runs `start <id>` before dispatch and `done <id>`
after verifying, and it alone writes state. The child gets the node and a
Log actor (`s<n>-<letter>`, so its lines sort beside the session's `s<n>`
lines). A child that may outlive one window is wrapped in `fleet.sh
dispatch-open` (`docs/context-budget.md` → "Dispatching long-running
children").

```
You are working node <id> of plan <plan> in work item <item>; workspace root <root>.
Node file: <root>/work/<item>/plans/<plan>/nodes/<id>.md — read it first.
`## Goal` is the work; `## Acceptance` is the definition of done.

Write to the node file in exactly two ways:
  - append Log lines under `## Log`, newest last, one per outcome, in the form
      - <actor> · <what happened, with the path of what is now on disk>
  - tick an Acceptance box you have verified yourself: `- [ ]` → `- [x]`
The frontmatter (everything above the second `---`: status, wave, blocked_by,
sessions, tier) stays as it is — `status` is written by plan.sh in the
orchestrating session, never by you — and other node files stay untouched.
Finish with one Log line naming what is on disk and what is not; the
orchestrator verifies on disk before the node is marked done.
```

Fill `<actor>` (e.g. `s13-a`), `<root>`, `<item>`, `<plan>`, `<id>`. The
returned summary is a hint; step 2 of the reconcile procedure is where it
becomes a fact.

## Verification

- Create: `plan.sh check` silent; `plan.sh frontier` names the first ready
  node; `plan.md` board and the launcher's Position block match `status`.
- Reconcile: the node's three boxes ticked, its last Log line the verdict,
  `plan.sh status` shows the next wave.
- Replan: `check` silent, a new `## Replans` line, `sync` run.
- Dispatch: the child's node file differs from before only under `## Log` and
  in Acceptance ticks (`git diff` or `diff` against a copy).
