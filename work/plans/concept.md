# Plans — concept note

Written 2026-09-23 (session 2), after the concept was settled with the user.
This page is the reference for what a **plan** is in this workspace. The
reasons and the rejected alternatives are in `decisions.md`; how the plan
relates to what the workspace already has is in `seams.md`.

## Definition

A **plan** is a folder of plain files that describes a piece of work as a
graph of steps, so that a chain of agent sessions can carry it out, stop
anywhere, and resume from disk. It lives inside a work item at
`work/<item>/plans/NN-<slug>/`, one open plan per item at a time. Nothing
runs the plan: the existing session loop starts sessions, each session reads
the plan and acts as an orchestrator, and a small script (`plan.sh`) answers
"what is the plan, what is done, where are we, what remains" by reading the
files. It never calls a model and never decides anything.

A plan has five properties:

1. **Graph.** The work is a set of **nodes** with **edges** (`blocked_by`).
   The **frontier** is the set of nodes that can start now.
2. **Waves.** Nodes that may run in parallel are grouped into a wave. Every
   wave ends in one named **reconcile node** that joins the results, verifies
   them, and is the only place the plan's structure may change.
3. **Loops.** A node may repeat: it runs, then a **check** command decides
   pass or fail, up to a cap. The check is a command, never a judgement.
4. **Sessions.** A node is sized to one session's context budget. A plan
   spans as many sessions as it takes; a node that overruns is split at
   rollover into a done part and a remainder.
5. **Tiers.** A node names the cheapest model **tier** that can do it
   (`frontier | standard | cheap | auto`). Tier rises at fan-in; reconcile
   and human-in-the-loop nodes are always frontier.

Two rules hold everything together. **Node files are the truth**: each node
is one markdown file that only the agent working it may write; everything
else (the waves board in `plan.md`, the Position block in the launcher) is
rendered from them between marker comments. **Results are claims until
verified**: a subagent writes what it did in the node's Log; only the
orchestrator, after checking the disk, sets the node to `done`.

## Glossary

Terms reuse the vocabulary already in the workspace (Anthropic's "Building
Effective Agents": node, edge, gate, routing, orchestrator-workers,
evaluator-optimizer). Aliases to avoid are in italics.

- **Work item** — `work/<item>/`, the durable home of an effort (README,
  launcher, ledger). A plan lives inside one. *Not "worktree"*: a worktree is
  a git isolation mechanism the plan never names.
- **Plan** — `work/<item>/plans/NN-<slug>/`: `plan.md` plus `nodes/`. Open or
  closed, never moved. *Not "runner", "workflow", "map".*
- **Node** — one unit of work, one file `nodes/NN-<slug>.md`, sized to one
  session's budget. Has a `kind`: `work` (default), `reconcile`, or `hitl`.
  *Not "task", "ticket", "step" in plan files; a to-tickets ticket becomes a
  node by gaining frontmatter.*
- **Edge** — a `blocked_by` entry. A blocker that is `done` or `dropped` no
  longer gates.
- **Status** — `todo | doing | done | blocked | dropped`. `blocked` is
  explicit, with the reason as the latest Log line; a node merely waiting on
  edges is *waiting*, which `plan.sh` derives and never writes. `done` is set
  only by the orchestrator or a human after verification.
- **Wave** — the nodes sharing a `wave:` number; they may run in parallel
  within one session, up to the wave's `parallel:` cap. Waves run in order.
  Parallelism means subagents inside a session; sessions themselves are
  serial. (Pattern: parallelization plus a gate.)
- **Reconcile node** — `kind: reconcile`, exactly one per wave, last in it.
  Joins results, verifies on disk, records decisions, and is where
  structural replanning happens. Defaults to `tier: frontier`. *Not "join",
  "sync", "gate" in plan files.*
- **HITL node** — `kind: hitl`, a step only a person can complete (approve,
  decide, review). Has no `check`; a person marks it done. When the frontier
  holds only HITL nodes the chain rolls over in interactive mode so the next
  session poses the question to a person.
- **Loop node** — any node with `loop: N`: run, then `check`, up to N
  attempts; on the cap it becomes `blocked` with the reason logged. (Pattern:
  evaluator-optimizer.)
- **Check** — a shell command in the node's `check:` line; exit 0 is pass.
  Also the name of `plan.sh check`, the lint that refuses a malformed plan
  (wave without reconcile, HITL with a check, oversized wave, dangling edge).
- **Tier** — `frontier | standard | cheap | auto`; abstract, mapped to a
  model per runtime in a small env file. `auto` looks the node's kind of
  work up in a policy table. Uniform: a node's tier applies to every
  subagent it fans out. (Pattern: routing.)
- **Orchestrator session** — a session in a plan-driven chain: reads the
  plan, picks frontier nodes, dispatches subagents, verifies, records, hands
  off. Does not do leaf work itself. (Pattern: orchestrator-workers.)
- **Frontier** — nodes with status `todo` whose blockers are all `done` or
  `dropped`, in the lowest wave that still has unfinished nodes. `plan.sh
  frontier` prints it.
- **Capture / replan** — a discovery is *captured* at any time with
  `plan.sh note` into `plan.md` → "Not yet specified". *Replanning* changes
  the graph and happens only at a reconcile node, each change a decision
  note. Authority by blast radius: local (split a node, add a follow-up in
  the same wave) — any agent, any time; structural (new wave, cross-wave
  edge, drop) — the orchestrator at reconcile, hands-off only if the plan's
  `replan:` line allows it; goal — a human, by closing the plan and opening
  a new one.
- **Generated block** — text between `<!-- plan:begin <name> -->` and
  `<!-- plan:end <name> -->` that `plan.sh sync` rewrites; everything outside
  is hand-written.

## Worked example: this work item as a plan

Had this item been run as a plan, it would be
`work/plans/plans/01-concept/` with three waves: **ground** (inventory the
seams, settle the concept with the user), **write** (grill the open items,
write the concept note), **verdict** (record the verdict, spec, tickets).
Sessions 1 and 2 map onto it exactly: session 1 finished wave 1 and rolled
over at WARN; session 2 ran waves 2 and 3.

### `plan.md`

```markdown
---
plan: 01-concept
status: open
replan: local        # structural replans need a person
default_tier: standard
---

# Plan 01 — settle the concept of a plan

## Goal
A one-page concept note, a seam inventory, decisions with rejected
alternatives, and a build/no-build verdict for "plans" in this workspace.

## Not yet specified
- Marker convention for generated blocks (captured session 1; settled session 2).

## Out of scope
- A runner. Parallel sessions on separate checkouts.

## Replans
- 2026-09-23 (05-reconcile-ground): added 06-grill-open-items — the concept
  discussion left five OPEN items that need a person. Local replan.

<!-- plan:begin board -->
| Wave | Node | Kind | Tier | Status |
|---|---|---|---|---|
| 1 ground | 01-seam-inventory | work | standard | done |
| 1 ground | 02-concept-discussion | hitl | frontier | done |
| 1 ground | 03-reconcile-ground | reconcile | frontier | done |
| 2 write | 04-grill-open-items | hitl | frontier | done |
| 2 write | 05-concept-note | work | frontier | done |
| 2 write | 06-reconcile-write | reconcile | frontier | done |
| 3 verdict | 07-spec | work | frontier | doing |
| 3 verdict | 08-tickets | work | standard | todo |
| 3 verdict | 09-reconcile-verdict | reconcile | frontier | todo |
Frontier: 07-spec. Remaining: 3 of 9. Sessions used: 2.
<!-- plan:end board -->
```

### A work node with fan-out — `nodes/01-seam-inventory.md`

```markdown
---
id: 01-seam-inventory
title: Inventory existing mechanisms against the plan concept
status: done
kind: work
wave: 1
blocked_by: []
tier: standard
parallel: 2          # two Explore subagents, one per half of the list
loop: 1
check: test -s seams.md && grep -q '^## What is genuinely missing' seams.md
sessions: [1]
isolated: no
---

## Goal
For each of ten mechanisms (to-tickets, wayfinder, Workflow tool,
research-wave, loop, session-loop.sh, launch-next-session.sh, fleet.sh,
rlm, launcher/ledger): what part of a plan it covers, what it lacks,
wrap / replace / leave alone.

## Acceptance
- [x] `seams.md` has a coverage table with one row per mechanism.
- [x] Every line-number claim verified on disk by the orchestrator.
- [x] A "What is genuinely missing" section names what no mechanism covers.

## Log
- s1 · dispatched two Explore subagents (standard tier), five mechanisms each.
- s1 · subagent A claims done; spot-checked 4 of 5 line refs, one corrected.
- s1 · subagent B claims done; spot-checked 5 of 5.
- s1 · check passed; verified on disk → done.
```

### A human node — `nodes/04-grill-open-items.md`

```markdown
---
id: 04-grill-open-items
title: Grill the user on the OPEN items, one round, recommended answers first
status: done
kind: hitl
wave: 2
blocked_by: [03-reconcile-ground]
tier: frontier
sessions: [2]
---

## Goal
Settle build/no-build, node format and status set, HITL check semantics,
marker convention, template integration, node kind, wayfinder's fate.

## Acceptance
- [x] Each answer recorded as a decision note with its rejected alternative.
- [x] No "(proposed)" note left in decisions.md.

## Log
- s1 · frontier held only this hitl node → rolled over interactive.
- s2 · two rounds; user asked for plain-language explanations on two
  questions before deciding; all seven recorded → done (by human).
```

### A reconcile node with a loop — `nodes/09-reconcile-verdict.md`

```markdown
---
id: 09-reconcile-verdict
title: Verify spec and tickets agree with the decisions; close the plan
status: todo
kind: reconcile
wave: 3
blocked_by: [07-spec, 08-tickets]
tier: frontier
loop: 2
check: scripts/plan.sh check --project plans --plan 01-concept && test -n "$(ls issues/*.md)"
sessions: []
---

## Goal
Read spec.md and every ticket against decisions.md; fix drift in place;
set the README status line; close the plan.

## Acceptance
- [ ] Every settled decision is reflected in spec.md or a ticket.
- [ ] Tickets carry blocking edges that match the spec's order.
- [ ] `plan.md` frontmatter reads `status: closed`.

## Log
```

What the script would answer during session 2, before wave 3 started:

```
$ scripts/plan.sh status --project plans
plan 01-concept  open  wave 2 of 3  done 5/9  doing 1  todo 3  blocked 0
$ scripts/plan.sh frontier --project plans
06-reconcile-write   reconcile  frontier   (blocked_by satisfied: 04, 05)
$ scripts/plan.sh remaining --project plans
06-reconcile-write  07-spec  08-tickets  09-reconcile-verdict
```
