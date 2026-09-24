# Decisions — plans

Tier-2 decision notes, newest last. Format: `skills/decision-log/SKILL.md`.
Notes marked **(settled)** were agreed with the user in session 1.
Session 2 grilled the remaining OPEN items with the user; every note below
is now settled. The two former OPEN sections are kept as a record of what
was asked and point to the notes that resolved them.

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

## 2026-09-23 — Node files are the truth; the index is rendered (settled in session 2; see the two refinements below)
**Chose:** One markdown file per node, `nodes/NN-<slug>.md`, flat YAML
frontmatter (`id`, `title`, `status`, `blocked_by`, `wave`, `tier`,
`parallel`, `loop`, `check`, `sessions`, `isolated`), sections Goal,
Acceptance, Log. `plan.md` holds hand-written Goal / Not yet specified /
Out of scope / Replans and a generated waves board between marker comments.
Only the orchestrator writes `plan.md`; subagents write only their node file.
The launcher gets a generated Position/Frontier block the same way.
Status set (settled): `todo | doing | done | blocked | dropped`.
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

## OPEN (resolved in session 2, see "How plans enter the template" below) — How plans integrate into the template and how agents learn them
Raised by the user at the end of session 1; the proposal as grilled:
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

## OPEN (resolved in session 2, see "Verdict: build" below) — Build / no-build verdict
Was: not yet recorded; everything above assumed "build a format plus state
tooling, no runner".

## 2026-09-23 — Verdict: build the format and plan.sh, no runner (settled)
**Chose:** Build. Ship the node-file format under
`work/<item>/plans/NN-<slug>/`, `scripts/plan.sh` (bash + jq, tests under
`scripts/tests/`), and the `chain.plan` / `plan_closed` hook in
`session-loop.sh`. No runner. Next steps in this item: `to-spec` → `spec.md`,
`to-tickets` → `issues/`.
**Because:** The seam inventory shows three genuinely new parts (tier as a
plan property, a check-based loop with a cap outside code, a reconcile step
named on disk) and the rest is joining; the user wants "where are we" and
end-of-session sync done by code, not by an agent reading prose.
**Rejected:** no-build — the four "genuinely missing" items in `seams.md`
stay missing; format-only, defer plan.sh — hand-maintained node files
re-create the prose-reading cost the format is meant to remove.
**Blast radius:** this item's README status line, `spec.md`, `issues/`.
**Promote?:** maybe — as part of the format ADR if one is written.

## 2026-09-23 — Status refinements: `blocked` is explicit, `done` is verified (settled)
**Chose:** `blocked` means a node is explicitly stuck, with the reason as the
latest Log line; a node merely waiting on `blocked_by` edges is *waiting*, a
state `plan.sh` derives and never writes. `done` is written only by the
orchestrator (or a human) after verifying the acceptance on disk; a
subagent's completion claim goes into the node's Log, never into `status`.
**Because:** Two meanings of "blocked" would make `frontier` lie; a
subagent that can flip `done` defeats "results are claims until verified".
**Rejected:** a sixth `verified` status — two hands on the status field and
a `done` that means nothing; the plain five-state proposal — ambiguous
`blocked`, unowned `done`.
**Blast radius:** `plan.sh done/block/frontier`; node-file Log convention;
subagent prompt template in the plans skill.
**Promote?:** no.

## 2026-09-23 — HITL nodes have no `check`; the human's tick is acceptance (settled)
**Chose:** A human-in-the-loop node carries no `check`; `plan.sh check`
rejects one that does. It is marked done by a person, via
`plan.sh done <id> --by human` or an edit of the node file. When the frontier
holds only HITL nodes, the chain rolls over with `--loop-mode interactive`
so the successor re-poses the question to a person instead of stalling
hands-off.
**Because:** No command can pass on a human decision; pretending otherwise
makes `check` a formality. The loop mode following the frontier is what
makes an unattended chain stop exactly where a human is needed.
**Rejected:** a `check` that greps its own file for a ticked box — uniform
but empty; `tier: human` — conflicts with "HITL nodes are always frontier
tier", which is about the agent that prepares the question.
**Blast radius:** `plan.sh check` lint; `session-loop.sh` loop-mode
selection; `docs/context-budget.md` rollover contract.
**Promote?:** no.

## 2026-09-23 — Generated blocks sit between `<!-- plan:begin <name> -->` markers (settled)
**Chose:** `plan.sh` renders into prose files only between
`<!-- plan:begin <name> -->` and `<!-- plan:end <name> -->`, replacing
exactly what lies between; everything outside is hand-written and never
touched. Used for the waves board in `plan.md` and the Position/Frontier
block in the launcher. Documented once in
`docs/work-directory-conventions.md` as the workspace's marker convention
(none existed before; verified by grep).
**Because:** Targeted, idempotent writes into files agents also edit by
hand; a tool prefix keeps a future generator from clashing.
**Rejected:** a generic `generated:` prefix — the name would have to carry
the tool anyway; no generated blocks, print only — the launcher would stop
being a projection of the plan, which the seam inventory chose.
**Blast radius:** `plan.sh sync`; launcher template in `create-work-item`;
`docs/work-directory-conventions.md`.
**Promote?:** no.

## 2026-09-23 — A node declares its sort with `kind: work | reconcile | hitl` (settled)
**Chose:** One frontmatter field, default `work` when absent. Lint rules
hang off it: every wave ends in exactly one `reconcile` node; a `hitl` node
has no `check`; `reconcile` defaults to `tier: frontier`.
**Because:** Reconcile and HITL nodes are settled as named things in the
plan, and the proposed frontmatter had no field to name them.
**Rejected:** two booleans — a node could be both; inference from position
and wording — breaks on reordering.
**Blast radius:** node frontmatter; `plan.sh check`; to-tickets conversion.
**Promote?:** no.

## 2026-09-23 — How plans enter the template (settled)
**Chose:** Five of the six proposed parts: (1) a short Plans section in
`CONTEXT.md`; (2) `docs/plans.md` as the reference, indexed from
`docs/README.md`, plus the optional `plans/` row in
`docs/work-directory-conventions.md`; (3) `skills/plans/SKILL.md`
(agent-agnostic, `/plan` shortcut) for what a script cannot do: create a
plan from a spec or tickets, run a reconcile node, replan; (4) one
conditional step in `session-rollover`, `checkpoint`, and the launcher
template: if a plan is open, `plan.sh sync` first; (6) downloader work: every
runtime documented, backlog card, `TEMPLATE_VERSION` bump, non-engineer note.
`create-work-item` scaffolds nothing extra; a plan is opt-in.
**Because:** Teaching plans only through one item's launcher would not
survive into a fresh workspace; the template rule is "ship and document for
downloaders".
**Rejected:** (5) a Stop/SessionEnd hook running `plan.sh check` — at
session end it can only warn, the supervisor already runs the same check
before the next child and refuses on failure, and it would be wired into six
runtimes' hook files; revisit if hand-run plans go stale. Docs-and-skill
only — the sync step would depend on the agent remembering.
**Blast radius:** `CONTEXT.md`, `docs/README.md`, `docs/plans.md` (new),
`docs/work-directory-conventions.md`, `skills/plans/` (new),
`.claude/commands/plan.md` (new), `skills/session-rollover/SKILL.md`,
`skills/checkpoint/SKILL.md`, `skills/create-work-item/SKILL.md`,
`docs/for-non-engineers.md`, the template backlog, `TEMPLATE_VERSION`.
**Promote?:** no.

## 2026-09-23 — Wayfinder coexists untouched in v1 (settled)
**Chose:** `wayfinder` is not edited. `docs/plans.md` carries one paragraph
mapping a wayfinder map onto a plan (map = `plan.md`, decision tickets =
`hitl` nodes, one per session). "Wayfinder becomes a plan template" goes on
the template backlog, to be taken up after plans have run a real item.
**Because:** Retiring or rewriting a vendored, adapted skill before the
replacement has run once is premature.
**Rejected:** wayfinder emits a plan now — larger blast radius before plans
exist; retire wayfinder — loses a working skill.
**Blast radius:** `docs/plans.md`; one backlog card.
**Promote?:** no.

## 2026-09-23 — A `blocked_by` naming no node is refused by every verb (settled)
**Chose:** `load_nodes` refuses (exit 1, naming the file and the id) when a
`blocked_by` entry matches no node in the plan, so `status`, `show`,
`frontier`, `remaining` and `graph` all stop on it.
**Because:** `frontier` treats an unknown blocker as never satisfied, so a
typo would silently keep a node off the frontier forever; a refusal at load
is three lines and the only place the id set is known.
**Rejected:** treat it as unsatisfied and let `check` (ticket 03) report it —
hides the typo from every read verb until someone runs the lint.
**Blast radius:** `scripts/plan.sh` `load_nodes`; ticket 03's "dangling
blocked_by" rule becomes a report of what the loader already refuses.
**Promote?:** no.


## 2026-09-23 — `check` parses leniently and lists every violation at once (settled)
**Chose:** `check` has its own lenient pass (`node_parse`: a bad node becomes a
`malformed` violation carrying the file stem as its id, and stays in the id
set so its dependants are not reported as dangling). The dangling-`blocked_by`
rule shares one jq fragment with the loader's refusal, so the two cannot drift.
"Reconcile last" means the reconcile node has the highest id in its wave. Wave
size is `wave_max:` in `plan.md`, else `PLAN_WAVE_MAX` (env, then
`context-budget.env`, then 6).
**Because:** a lint that stops at the first problem is run N times for N
problems; the ticket asks for one line per violation. Id order is what the
board shows and what "followed by a reconcile node" reads as.
**Rejected:** (a) treating the dangling blocker as a load-time refusal inside
`check` too — one line, exit 1, hides the rest; (b) "last" as "blocked by every
other node in the wave" — a stronger join rule the spec does not ask for, and
one a plan author may legitimately relax (a reconcile node that reads files,
not node outputs); (c) a separate env file for plan knobs — one knob does not
earn a file, `context-budget.env` is already where the budget-shaped constants live.
**Blast radius:** `scripts/plan.sh` (`node_parse`, `DANGLING_JQ`, `cmd_check`),
`context-budget.env`, `docs/plans.md`.
**Promote?:** no.

## 2026-09-23 — Write verbs: who stamps, where checks run, how attempts count (settled)
**Chose:** The Log stamp is `--by <actor>`, else `s<seq>` from `--session`
or the item's `session-state.json`; `start` needs a number, the rest accept
either. A node's `check` runs from `work/<item>/` with `WORKSPACE_ROOT`
exported. Failed attempts count Log lines since the last `started`, so
`blocked → doing` gets `loop` fresh. Write verbs resolve the plan strictly
and refuse a closed one; `start` does not lint.
**Because:** A human ticking a hitl node has no session; the loop's children
do. Item-relative paths (`seams.md`, `issues/`) are what checks name;
root-relative ones can use the variable. Counting from the file keeps
`plan.sh` stateless. A closed plan is the wrong graph for a write.
**Rejected:** a `--session` requirement everywhere — blocks the human tick;
a failure counter field — a second hand on the frontmatter for what the Log
already says; `start` running `check` — the loop does it between children
(ticket 07), twice is noise.
**Blast radius:** `plan.sh` write verbs; `docs/plans.md` "State machine".
**Promote?:** no.

## 2026-09-24 — `sync` is a projection: read-style resolution, renders a closed plan too (settled)
**Chose:** `plan.sh sync` resolves the plan like the read verbs (`--plan` →
`chain.plan` → single open → latest) and never refuses a closed plan; it
validates both marker pairs (`board` in `plan.md`, `position` in
`next-session.md`) before writing either, so a missing marker leaves both
files untouched. The board's wave column is the number alone; the footer and
the launcher block name the doing/blocked nodes when the frontier is empty.
**Because:** Closing a plan is a hand edit after the last reconcile; the board
and launcher must still be re-renderable afterwards, and a half-written pair
would be worse than none. Wave names live in no frontmatter (ledger block 3).
**Rejected:** `resolve_plan write` (refuses closed plans — a projection is not a
transition); rendering the launcher block even when `plan.md` lacks markers;
inventing missing markers (settled: reported, never invented).
**Blast radius:** `cmd_sync`, T18, the fixture board (re-rendered by `sync`).
**Promote?:** no.

## 2026-09-24 — Tiers: `leaf:` is the lookup key, `tier_<label>:` the plan override, one `plan-tiers.env` (settled)
**Chose:** `auto` resolves node `tier` → `plan.md` `tier_<label>:` → `PLAN_TIER_<LABEL>`
in `plan-tiers.env` → the plan's `default_tier` → `standard`; the label is
the node's optional `leaf: <label>` (`[a-z][a-z0-9_]*`), absent or unknown
labels skip to the default. Reconcile and hitl nodes default to `frontier`
and resolve `auto` to `frontier` (fan-in). Model knobs are
`PLAN_MODEL_<RUNTIME>_<TIER>` in the same file; the runtime is `--runtime` →
`PLAN_RUNTIME` → the bound registry record → unknown. Node JSON carries
`tier_resolved` and `model` (null = session model); `frontier` text prints
the resolved tier with ` (auto)`; `start` logs `started, tier <t>` or
`…, tier <t> unavailable on <runtime> (session model)`. Model names never
reach a plan or node file. The board keeps the written tier.
**Because:** "kind of leaf work" needs a key `kind:` does not carry; a
frontmatter line is visible in the node and needs no new file. One env file
beside `context-budget.env` matches rlm's knob shape and is what every
runtime's hook can source. Stamping the tier (not the model) keeps node
files runtime-neutral while the Log still says what ran.
**Rejected:** deriving the label from the slug (fragile, invisible); a
per-plan `tiers.env` (a second file for two lines); `auto` as a policy
value (circular); stamping the model into the Log (box 3 of ticket 06).
**Blast radius:** `load_nodes`, `cmd_frontier`, `cmd_start`, `cmd_add
--leaf`, `plan-tiers.env`, `docs/plans.md` → "Tiers".
**Promote?:** maybe — with the 2026-09-23 note, if the mapping outgrows plans.

## 2026-09-24 — Loop plan hook: one code `plan_invalid`, broken mid-chain, refused at start (settled)
**Chose:** A failing `plan.sh sync` or `check` between children is `broken
reason=plan_invalid leg=sync|check` (exit 1, notify hook, staged command
kept, no close) — the shape of `staged_invalid` mid-chain; a `--plan` that
does not resolve or several open plans with no `--plan` is `refused
reason=plan_invalid leg=unresolved|ambiguous` at start (exit 4, record
untouched). `plan_closed` follows the `staged` verdict of the child that
finished the plan and writes `chain.closed.reason`, so a restart refuses
`chain_closed` until `--reopen`. The interactive choice is made by the
supervisor from `frontier --json` (non-empty, every node `kind: hitl`): it
writes `launch.mode = interactive` and pauses; the child's `--loop-mode` is
not consulted for it.
**Because:** Mid-chain the plan is what the child left behind and a human
must fix it — the staged command must survive for the restart, exactly as a
bad staging does. At start nothing has run, so a refusal leaves no trace. One
code with legs keeps the reason-code table to one new row per emitter.
**Rejected:** (a) `refuse` (exit 4) mid-chain — would read as a start gate
and the doc's exit contract says the supervisor mid-flight is 0 or 1;
(b) separate codes `plan_sync_failed` / `plan_check_failed` /
`plan_ambiguous` — three doc rows for one situation ("the plan is not
usable"); (c) having the child pick `--loop-mode interactive` from the
frontier — the supervisor already reads the plan between children and never
trusts the child's judgement for a verdict.
**Promote?:** no.
