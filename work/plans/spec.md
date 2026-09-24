<!--
Effort-level spec for work/plans/ — distinct from root SPEC.md
(product-level Z0). Convention: docs/agents/issue-tracker.md → "Spec conventions".
Synthesized by to-spec (session 2, 2026-09-23) from decisions.md, concept.md,
seams.md and the grill; no interview. Vocabulary: concept.md → Glossary.
-->

# Spec — plans: a node-file format, `plan.sh` state tooling, and the loop hook

Status: approved         <!-- draft | in-review | approved -->
Approved-by: Kashif Siddiqui (2026-09-23, session 2)
Date: 2026-09-23
Spec-of-record: —

## Problem Statement

Multi-session agent work in this workspace is planned in prose. Dependencies
live in ticket files, the frontier is recomputed by an agent reading the
launcher every session, parallel fan-out and model choice are decided ad hoc
inside a session, and nothing on disk says where a wave joins, when a loop
may stop, or which model tier a step deserves. Every session pays a reading
cost to answer "what is the plan, what is done, where are we, what remains",
and an unattended chain cannot tell that it has reached a step only a
person can complete.

## Solution

A **plan** is a folder of plain files inside a work item:
`work/<item>/plans/NN-<slug>/` holding `plan.md` and one file per node under
`nodes/`. Node files are the truth; boards and position blocks are rendered
from them between marker comments. A script, `plan.sh`, reads the files and
answers the four questions in text or JSON, lints the plan, and applies the
few state transitions; it never calls a model and never decides. The session
loop learns which plan a chain drives, runs sync and check between children,
refuses a broken plan, ends the chain when the plan closes, and rolls over
interactively when only human steps remain. A skill covers what a script
cannot: creating a plan from a spec or tickets, running a reconcile node,
replanning. All of it ships documented for every runtime and for
downloaders. See `concept.md` for the definition and glossary.

## Requirements

<!-- Stable IDs — never renumber; strike through retired items. Tickets
     reference these as `Spec: S3`. -->

### Format

- **S1** — As an orchestrator session, I want each node to be one markdown
  file with flat YAML frontmatter (`id`, `title`, `status`, `kind`, `wave`,
  `blocked_by`, `tier`, `parallel`, `loop`, `check`, `sessions`, `isolated`)
  and sections Goal / Acceptance / Log, so that subagents write only their
  own file and reads stay targeted.
- **S2** — As a plan author, I want `plan.md` to hold hand-written Goal /
  Not yet specified / Out of scope / Replans plus frontmatter (`plan`,
  `status: open|closed`, `replan`, `default_tier`), with the waves board
  rendered between `<!-- plan:begin board -->` and `<!-- plan:end board -->`,
  so that one file gives the shape of the work without being the truth.
- **S3** — As any agent, I want the status set to be exactly
  `todo | doing | done | blocked | dropped`, where `blocked` is explicit with
  the reason as the latest Log line and "waiting on edges" is derived, never
  written, so that `frontier` never lies.
- **S4** — As an orchestrator, I want `done` to be settable only by me or a
  human after verification, with a subagent's completion claim landing in
  the Log, so that results stay claims until verified.
- **S5** — As a plan author, I want `kind: work | reconcile | hitl` (default
  `work`), so that the lint can require one reconcile node per wave, forbid
  a `check` on a HITL node, and default reconcile nodes to frontier tier.
- **S6** — As a plan author, I want `tier: frontier | standard | cheap |
  auto` on a node, uniform across the subagents it fans out, with `auto`
  resolved through a per-workspace policy table (kind of leaf work → tier)
  that a plan may override, so that model choice is a lookup, not a
  judgement.
- **S7** — As a runtime operator, I want abstract tiers mapped to concrete
  models in a small env mapping next to `context-budget.env`, per runtime,
  with a runtime lacking a knob running at the session model and logging the
  tier as unavailable, so that plans stay runtime-neutral.
- **S8** — As a plan author, I want `loop: N` with `check: <command>` to mean
  "run, then check, up to N attempts; on the cap set `blocked` with the
  reason logged", so that a loop exits by a command, never by judgement.
- **S9** — As a plan author, I want `parallel: N` on a node to cap subagents
  in flight inside it and `parallel: N` on a wave to cap nodes worked at
  once, both as ceilings under the orchestrator's own budget, so that
  fan-out is declared, not improvised.
- **S10** — As a plan author, I want a node to say `isolated: yes` without
  naming the isolation mechanism, with the reconcile node absorbing the
  merge, so that plan vocabulary never says "worktree".
- **S11** — As a work-item owner, I want one open plan per item at a time,
  closed in place with `status: closed`, never moved, and a new plan taking
  the next number, so that "latest" is a directory listing.

### `plan.sh` — read verbs

- **S12** — As any agent or person, I want `plan.sh status` to print plan
  name, open/closed, current wave of total, counts by status, and sessions
  used, so that "where are we" is one command.
- **S13** — As an orchestrator, I want `plan.sh frontier` to list `todo`
  nodes whose blockers are all `done` or `dropped`, in the lowest wave with
  unfinished nodes, each with kind and tier, so that I can pick work without
  reading prose.
- **S14** — As any agent, I want `plan.sh remaining` and `plan.sh show <id>`
  to list what is left and print one node, so that targeted reads replace
  whole-plan loads.
- **S15** — As a supervisor or agent, I want `plan.sh check` to lint the
  plan and exit non-zero on: a wave without exactly one reconcile node, a
  reconcile node not last in its wave, a `check` on a HITL node, a dangling
  or cross-plan `blocked_by`, a node in `doing` with no session listed, a
  wave grown past its size limit, or malformed frontmatter, so that a
  broken plan is refused before a session runs on it.
- **S16** — As a person, I want `plan.sh graph` to print the graph in a
  form I can read (text; a DOT option is acceptable), so that I can see the
  shape of the work.
- **S17** — As an agent, I want `--json` on every read verb and stable exit
  codes documented as the contract (0 ok, 1 lint or state refusal, 2 usage
  or resolution failure), so that skills and hooks can branch on results.

### `plan.sh` — write verbs

- **S18** — As an orchestrator, I want `plan.sh add`, `start`, `done`,
  `drop`, `block <reason>`, `note`, `verify`, and `sync`, each editing only
  the fields and Log lines it owns and refusing illegal transitions (for
  example `done` on a node whose `check` fails, or `start` on a node not on
  the frontier unless forced), so that the state machine lives in one place.
- **S19** — As a person, I want `plan.sh done <id> --by human` to mark a
  HITL node done and log who did it, so that a human tick is recorded the
  same way as any other transition.
- **S20** — As any agent, I want `plan.sh note "<text>"` to append to
  `plan.md` → "Not yet specified" at any time, so that capture never blocks
  and never edits the graph.
- **S21** — As an orchestrator, I want `plan.sh sync` to re-render every
  generated block (the board in `plan.md`, the Position/Frontier block in
  the item's launcher) between its markers and touch nothing outside them,
  idempotently, so that prose files stay a projection of the node files.
- **S22** — As an orchestrator, I want `plan.sh new <slug>` to create the
  next-numbered plan directory with an empty `plan.md` skeleton, so that a
  plan is opt-in and `create-work-item` scaffolds nothing extra.

### Resolution and safety

- **S23** — As any caller, I want the project resolved as flag → session
  registry binding → `TF_SESSION_PROJECT` → current directory → refuse, and
  the plan resolved as flag → `chain.plan` → the single open plan → refuse
  when several are open (read verbs may fall back to the latest), so that a
  write never lands in the wrong graph.
- **S24** — As a template maintainer, I want `plan.sh` in bash + jq with the
  same dependency set as the existing scripts, so that it runs on every
  runtime and machine the template already supports.

### Session loop

- **S25** — As a chain operator, I want an optional `chain.plan` in
  `session-state.json` (schema stays 1), set by `--plan <slug>` or resolved
  from the single open plan, so that the loop knows its plan or knows it has
  none, and items without plans behave exactly as today.
- **S26** — As a chain operator, I want the supervisor to run `plan.sh sync`
  and `plan.sh check` between children and to refuse the next session on a
  failed check the way it refuses `staged_invalid`, so that no session runs
  on a broken plan.
- **S27** — As a chain operator, I want a new verdict `plan_closed` that ends
  the chain when the plan's terminal reconcile node is `done` and the plan
  is closed, so that the plan, not the session cap, ends a plan-driven chain.
- **S28** — As a person running an unattended chain, I want the rollover to
  choose `--loop-mode interactive` when the frontier holds only HITL nodes,
  so that the chain stops exactly where I am needed.
- **S29** — As an orchestrator that hits WARN mid-node, I want the rollover
  step to split the node into a done part and a remainder node (same wave,
  same edges, `sessions` carried), so that the node stays the unit of
  accounting.

### Skill and docs

- **S30** — As an agent in any runtime, I want a `plans` skill
  (`skills/plans/SKILL.md`, `/plan` shortcut) covering: create a plan from a
  spec or a set of tickets (each ticket becomes a node by gaining
  frontmatter), run a reconcile node (join, verify on disk, record
  decisions, replan within authority), and replan, so that the parts a
  script cannot do have one written procedure.
- **S31** — As an orchestrator, I want the skill's subagent prompt template
  to tell a subagent to write only its node's Log and Acceptance ticks and
  never `status`, so that S4 holds in practice.
- **S32** — As an agent reading `CONTEXT.md`, I want a short Plans section
  (what a plan is in three lines, when to use one, the `plan.sh status`
  one-liner, a pointer to the reference), so that plans are discoverable
  from the front door.
- **S33** — As a reader, I want `docs/plans.md` (format, verbs and exit
  codes, tier policy and mapping, the three replan tiers, the wayfinder
  mapping paragraph, a worked example) indexed from `docs/README.md`, and
  the optional `plans/` row plus the marker convention in
  `docs/work-directory-conventions.md`, so that one reference holds the
  detail.
- **S34** — As a session ending with a plan open, I want `session-rollover`,
  `checkpoint`, and the launcher template in `create-work-item` to carry one
  conditional step, "if a plan is open, run `plan.sh sync` first", so that
  the launcher's Position block is fresh at every handoff.
- **S35** — As a downloader on Codex, Gemini, OpenCode, or Copilot, I want
  the plan tooling documented for my runtime, a backlog card, a
  `TEMPLATE_VERSION` bump, and a note in `docs/for-non-engineers.md`, so
  that plans are a first-class template addition, not a local convenience.
- **S36** — As a workspace maintainer, I want `CONTEXT.md` → Language to
  gain the plan glossary terms (plan, node, wave, reconcile node, HITL node,
  check, tier, frontier) with "worktree" under aliases to avoid, so that
  every skill reads the same vocabulary.

## Implementation Decisions

All recorded in `decisions.md` with rejected alternatives; the binding ones:

- Node files are the truth; `plan.md` and the launcher block are rendered
  between `<!-- plan:begin <name> -->` / `<!-- plan:end <name> -->` markers.
  This is the workspace's first marker convention; documented once.
- `plan.sh` derives, never decides: everything it prints comes from node
  files; it never calls a model. Text by default, `--json` for agents, exit
  codes as contract.
- The state machine: `todo → doing → done`, `doing → blocked → doing`,
  any → `dropped`. `done` requires the node's `check` (if any) to pass and is
  written by the orchestrator or a human. HITL nodes have no `check`.
- Frontier: `todo` nodes whose blockers are `done` or `dropped`, restricted
  to the lowest wave that still has unfinished nodes. Waves run in order.
- Tiers: abstract names; `auto` via a policy table (workspace default,
  per-plan override, wave default as fallback); rises at fan-in; per-runtime
  mapping in an env file beside `context-budget.env`.
- Replan authority by blast radius: local — any agent, any time;
  structural — orchestrator at a reconcile node, hands-off only if
  `plan.md` → `replan:` allows; goal — human, by closing and opening a plan.
- The loop: additive `chain.plan`, sync + check between children,
  `plan_closed` verdict, interactive rollover when only HITL nodes remain.
  No Stop/SessionEnd hook in v1.
- Wayfinder is untouched; the mapping (map = `plan.md`, decision tickets =
  HITL nodes) is a paragraph in `docs/plans.md`; "wayfinder becomes a plan
  template" is backlog card L48.
- Vocabulary: "work item", never "worktree"; glossary terms reuse the
  Building-Effective-Agents names already in use.

## Testing Decisions

- **Seams.** Two, both existing in kind. (1) The `plan.sh` command line:
  tests create a fixture plan directory, run verbs, and assert on printed
  text, `--json` output, exit codes, and the resulting files. (2) The
  session-loop supervisor: the plan hook is tested the way
  `scripts/tests/test-session-loop.sh` already drives the loop with a fake
  child, adding cases for `chain.plan`, a failed check refusing the next
  session, `plan_closed`, and the interactive-rollover choice. No new seam
  inside the scripts.
- **What a good test is.** Behaviour at the seam only: given these node
  files, this is what `frontier` prints and this is the exit code. Never the
  script's internal functions or jq expressions.
- **Cases the format demands.** Frontier with mixed `done`/`dropped`
  blockers; a wave without a reconcile node fails `check`; a HITL node with
  a `check` fails `check`; `done` refused when the node's `check` fails;
  `sync` is idempotent and leaves text outside markers byte-identical;
  resolution refuses when two plans are open; a plan-less item runs the
  loop exactly as before (regression against the existing loop tests).
- **Prior art.** `scripts/tests/test-session-loop.sh`,
  `test-session-lib.sh`, `test-context-budget-registry.sh` (fixture dirs,
  fake children, exit-code assertions); `scripts/tests/fixtures/`.
- **Docs consistency.** `test-doc-consistency.sh` gains the new doc and
  skill paths so a renamed file is caught.

## Non-goals

- A runner. `session-loop.sh` plus an orchestrator reading the frontier is
  the runner.
- Parallel sessions on separate checkouts; multi-supervisor records; merge
  reconciliation across sessions.
- A new DSL or any format that is not markdown plus flat YAML frontmatter.
- A Stop/SessionEnd hook that runs `plan.sh check` (deferred; revisit if
  hand-run plans go stale).
- Editing or retiring `wayfinder` (L48).
- Naming concrete models in a plan; per-subagent model choice by judgement.
- Automatic goal-level replanning.

## Further Notes

- Sizing rule of thumb for authors: if a node cannot be described in one
  Goal paragraph and three Acceptance lines, it is two nodes.
- The first real plan should be this workspace's own next multi-session
  item, run end to end, before L48 or any hook is reconsidered.
- The abstract-tier mapping and the derive-don't-decide rule are the two
  candidates for an ADR once the tooling has run once (`Promote?: maybe`
  in `decisions.md`).
