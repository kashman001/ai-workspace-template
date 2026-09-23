# Decisions — plans

Tier-2 decision notes, newest last. Format: `skills/decision-log/SKILL.md`.
Notes marked **(settled)** were agreed with the user in session 1.
Notes marked **(proposed)** were put forward by the agent and not yet
explicitly confirmed; the grill confirms or overturns them.

## 2026-09-23 — A node is sized to one session's context budget (settled)
**Chose:** A plan is a graph of nodes. A node is a unit of work that should fit
one session's budget; a large node may take several whole sessions, each
within budget, but the node stays the unit of accounting. A node that hits
WARN unfinished is split at rollover into a done part and a remainder node.
**Because:** It turns the context budget from a defensive measure into the
unit of planning, and makes "where are we" a count over nodes.
**Rejected:** nodes of arbitrary size resumed blindly across sessions — the
budget rule would be decorative.
**Blast radius:** node file format; session-rollover step for overrun.
**Promote?:** maybe — if the format ships, this is the ADR's core claim.

## 2026-09-23 — Plans live inside a work item, one active at a time (settled)
**Chose:** `work/<item>/plans/NN-<slug>/`. One plan open at a time per item,
run as a chain of sessions via `session-loop.sh`; closed in place with
`status: closed`, never moved. A new plan gets the next number.
**Because:** Major work already has a work item; the plan is the structured
core of it, not a parallel container. Numbered directories make "latest" a
directory listing.
**Rejected:** a plan as its own work item — duplicates README/launcher/ledger;
several plans active at once — the loop would not know which one to drive.
**Blast radius:** `docs/work-directory-conventions.md` files table.
**Promote?:** no.

## 2026-09-23 — Each chain session is an orchestrator (settled)
**Chose:** A session in a plan-driven chain reads the plan, picks frontier
nodes, dispatches subagents for the work, verifies results on disk, records,
and hands off. Subagent results are claims until verified.
**Because:** Keeps the orchestrator's window for coordination; matches the
orchestrator-workers pattern already taught in the workspace.
**Rejected:** the session doing leaf work itself — burns the budget that the
node-equals-budget rule depends on.
**Blast radius:** launcher wording for plan-driven items.
**Promote?:** no.

## 2026-09-23 — Waves end in a named reconcile node (settled)
**Chose:** A wave is a set of nodes that may run in parallel, followed by one
reconcile node that joins results, verifies, and is where replanning happens.
The reconcile node is written into the plan, not implied.
**Because:** The user asked for a synchronization point; research-wave shows
the join (independent fact-check, orchestrator rules) but only in prose.
**Rejected:** implicit join at the next wave — nowhere to hang verification
or replanning.
**Blast radius:** plan index sections; `check` lint (wave without reconcile).
**Promote?:** no.

## 2026-09-23 — Parallelism is subagents within a session; sessions stay serial (settled)
**Chose:** `parallel: N` on a node caps subagents in flight inside it;
`parallel: N` on a wave caps nodes one session works at once. Both are
ceilings; the orchestrator's own budget is the real limit. Across sessions
the chain is serial, a wave simply continues in the next session.
**Because:** `session-loop.sh` runs one foreground child; every subagent
result lands in the parent's window.
**Rejected:** parallel sessions on separate checkouts — out of scope for v1;
needs merge reconciliation and a multi-supervisor record.
**Blast radius:** node/wave frontmatter; out-of-scope list.
**Promote?:** no.

## 2026-09-23 — Tiers are abstract, uniform by default, a lookup when auto (settled)
**Chose:** `tier: frontier | standard | cheap | auto` on a node. Uniform: the
node's tier applies to every subagent it fans out. `auto`: a tier policy
table (kind of leaf work → tier), one per workspace, overridable per plan;
unknown kinds fall back to the wave default. Tier rises at fan-in (reconcile
defaults to frontier); human-in-the-loop nodes are always frontier. Tier
names map to per-runtime models in a small env mapping, like rlm's knobs;
a runtime with no knob runs at the session model and logs the tier as
unavailable.
**Because:** The decision must be fast: a table, not a judgement. Plans stay
runtime-neutral.
**Rejected:** per-subagent model choice by the orchestrator's judgement —
slow and non-reproducible; naming models in the plan — runtime-specific.
**Blast radius:** tier policy file; per-runtime mapping next to
`context-budget.env`; node log stamps.
**Promote?:** maybe — the abstract-tier mapping is reusable beyond plans.

## 2026-09-23 — Replan: capture immediately, restructure at the reconcile node (settled)
**Chose:** Discoveries are captured any time with `plan.sh note` into the
index's "Not yet specified" (wayfinder's fog rule). Structural changes happen
at the reconcile node, each as a decision note. Authority by blast radius:
local (split a node, add a follow-up in the same wave) — agent, any time;
structural (new wave, cross-wave re-edge, drop) — orchestrator at reconcile,
hands-off only if the plan's `replan:` line allows; goal — human, always,
by closing the plan and opening a new one. `check` flags a wave that grew
past a size limit.
**Because:** Restructuring mid-wave under parallel subagents is unsafe;
capturing is cheap and never blocks.
**Rejected:** restructure whenever discovered — graph edits under concurrent
work; fully automatic goal changes — wayfinder's destination rule.
**Blast radius:** `plan.sh note/check`; plan index `replan:` line.
**Promote?:** no.

## 2026-09-23 — The session loop knows its plan, or knows it has none (settled)
**Chose:** Optional `chain.plan` in `session-state.json` (additive, schema
stays 1), set by `--plan <slug>` or resolved from the single open plan.
Between children the supervisor runs `plan.sh sync` and `check`; a failed
check refuses the next session like `staged_invalid`. New verdict
`plan_closed` ends the chain when the terminal node is done. No plan: the
loop behaves exactly as today.
**Because:** The plan, not the session cap, should end a plan-driven chain;
items without plans must not pay for the feature.
**Rejected:** requiring a plan for every chain — the template must stay lean
for small items.
**Blast radius:** `scripts/session-loop.sh`, `scripts/lib/session-lib.sh`,
`docs/context-budget.md`.
**Promote?:** no.

## 2026-09-23 — State tooling, not a runner (settled in principle; scope proposed)
**Chose:** `scripts/plan.sh --project <item> --plan <slug> <verb>`, bash + jq,
tests under `scripts/tests/`. Read verbs: `status`, `frontier`, `remaining`,
`show`, `check`, `graph`. Write verbs: `add`, `start`, `done`, `drop`,
`block`, `note`, `verify`, `sync`. Text by default, `--json` for agents, exit
codes as contract. Project resolves: flag → session registry binding →
`TF_SESSION_PROJECT` → current directory → refuse. Plan resolves: flag →
`chain.plan` → single open plan → refuse if several → latest for read verbs
only. Everything it prints is derived from node files; it never calls a model.
**Because:** The user wants "what is the plan, what is done, where are we,
what remains" and end-of-session sync to be fast and done by code.
**Rejected:** a runner that drives sessions or models — `session-loop.sh`
plus an orchestrator reading the frontier already is the runner; guessing
between two open plans — silent writes to the wrong graph.
**Blast radius:** new script + tests; session-rollover and checkpoint skills
gain a sync step; a Stop/SessionEnd hook may run `check`.
**Promote?:** maybe — the derive-don't-decide rule is ADR-shaped.

## 2026-09-23 — Node files are the truth; the index is rendered (proposed)
**Chose:** One markdown file per node, `nodes/NN-<slug>.md`, flat YAML
frontmatter (`id`, `title`, `status`, `blocked_by`, `wave`, `tier`,
`parallel`, `loop`, `check`, `sessions`, `isolated`), sections Goal,
Acceptance, Log. `plan.md` holds hand-written Goal / Not yet specified /
Out of scope / Replans and a generated waves board between marker comments.
Only the orchestrator writes `plan.md`; subagents write only their node file.
The launcher gets a generated Position/Frontier block the same way.
Status set (proposed): `todo | doing | done | blocked | dropped`.
**Because:** Targeted reads and writes, no collisions between parallel
subagents, and a to-tickets issue converts by adding lines.
**Rejected:** one file holding everything — whole-file loads and write
collisions; a new DSL — nothing in the workspace could read it.
**Blast radius:** `docs/agents/issue-tracker.md` conventions; to-tickets
template; a marker convention (none exists yet).
**Promote?:** no.

## 2026-09-23 — Plan vocabulary says "work item", never "worktree" (settled)
**Chose:** Plans, nodes, waves, docs, and `plan.sh` flags use "work item".
"worktree" is listed under aliases to avoid. Isolation of parallel
file-editing subagents is an orchestrator detail; a node may say
`isolated: yes` without naming the mechanism; the reconcile node absorbs
the merge. State never lives in an isolated tree.
**Because:** The two words were confused once already in session 1.
**Rejected:** exposing worktrees in the plan — confuses the two audiences.
**Blast radius:** glossary in `concept.md`; CONTEXT.md Language section.
**Promote?:** no.

## OPEN — How plans integrate into the template and how agents learn them
Raised by the user at the end of session 1; proposed answer, to be grilled:
- **Front door:** a short "Plans" section in `CONTEXT.md` (next to Decision
  Records and Work Directory Convention): what a plan is in three lines, when
  to use one, the `plan.sh status` one-liner, and a pointer to the reference.
- **Reference:** `docs/plans.md` (format, verbs, tier policy, the replan
  tiers, worked example) indexed from `docs/README.md`; the files table in
  `docs/work-directory-conventions.md` gains the optional `plans/` entry.
- **Skill:** `skills/plans/SKILL.md` (agent-agnostic, `/plan` shortcut in
  `.claude/commands/`) for the workflows a script cannot do: create a plan
  from a spec or tickets, run a reconcile node, replan. Listed in the
  Workspace Skills section like the others.
- **Hooks into existing skills:** `session-rollover`, `checkpoint`, and the
  launcher template gain one conditional step: "if a plan is open, run
  `plan.sh sync` first". `create-work-item` scaffolds nothing extra; a plan
  is opt-in via `plan.sh add`/a `new` verb.
- **Mechanical nudge:** the Stop/SessionEnd hook runs `plan.sh check` when a
  plan is open, the way SessionStart runs the budget register.
- **Downloaders:** documented for every runtime (Codex, Gemini, OpenCode,
  Copilot), a backlog card, `TEMPLATE_VERSION` bump, non-engineer note in
  `docs/for-non-engineers.md`.
- **Rejected (proposed):** teaching plans only through the launcher of one
  item — nothing would survive into a fresh workspace.

## OPEN — Build / no-build verdict
Not yet recorded. Everything above assumes "build a format plus state
tooling, no runner"; the grill should confirm and the README status line
should then say so.
