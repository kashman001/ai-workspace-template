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

## 2026-09-24 — Node split at rollover: rename the remainder to `<id>-b` after `add` (settled)
**Chose:** The split in `session-rollover` is existing verbs plus file edits:
`show` → `add` (same wave, kind, tier, blockers, check) → `mv` the new file to
the origin's number and set `id: <id>-b` and `sessions:` → dependants gain
`<id>-b` in `blocked_by` → drop `check:` from the origin → `done` → Log line →
`check` → `sync`.
**Because:** `add` always takes the next number, which lands the remainder
after the wave's reconcile node and trips `reconcile-last` (ids compare as
strings); sharing the origin's number keeps the pair together before the
join and needs no code. `done --force` does not skip a check, so the check
moves to the remainder rather than being forced past.
**Rejected:** (a) `add --number`/`--after` in `plan.sh` — a code change, docs
row and tests for one procedure; (b) relaxing `reconcile-last` to ignore
nodes the reconcile node is blocked by — weakens a lint every plan relies on;
(c) keeping the origin as the remainder and adding a done-part node — same
numbering problem, and the done part would carry no edges anyone reads.
**Promote?:** no.

## 2026-09-24 — Replan follow-ups: same wave when found mid-wave, next wave when found at the join (settled)
**Chose:** A follow-up node discovered while a wave is still running is added
to that wave (renamed below the reconcile node, the split's trick) and becomes
one of the join's blockers; one discovered *at* the reconcile node goes into
the next wave. The skill says so; `plan.sh` is unchanged.
**Because:** `done` checks the node's own `check`, not its blockers — an edge
added to the reconcile node mid-run would be closed over by the same `done`
that ends the reconcile, and nothing would ever join the follow-up.
**Rejected:** `done` refusing while a blocker is open — a `plan.sh` change
under a ticket that adds no code, and it would also refuse the legitimate
`--force` import of a half-finished ticket set; a follow-up as a new blocker of
the running reconcile node — silently skipped, see above.
**Blast radius:** `skills/plans/SKILL.md` (Reconcile step 5, Replan rule 1);
`docs/plans.md` → "Replans".
**Promote?:** no.

## 2026-09-25 — Dogfood (ticket 11): the first real plan opens before a spec or tickets exist
**Chose:** `jev-integration/plans/01-gated-integration`, a three-wave
"plan the planning" shape — 01 draft the fit note → 03 a person approves
(`hitl`) → 05 spec + tickets → 06 reconcile with `replan: structural`, which
adds the implementation waves from the tickets. Six nodes, `check` silent.
**Because:** the item was blocked on a human-only fit decision (four grill
questions open after session 6) with no spec and no tickets, and "Create a
plan" assumes one of the two exists. The structural replan at the wave-3 join
is the documented path for "a new wave", and it lets the chain run hands-off
from the first node instead of waiting for a person to write tickets by hand.
The user's direction (integrate, gated on Jev access — grill Q4 = a) is in
`plan.md` → Goal; the note itself stays node 01's work and the three still-open
questions ride with it, so the approval in 03 is a real `hitl` step.
**Rejected:** (a) drafting the note and tickets in the plans session, then
opening the plan from tickets — hides the `hitl` step ticket 11 wants
exercised and spends this session on another item's design; (b) a wayfinder
map for the decision and a plan afterwards — two mechanisms for one chain.
**Blast radius:** none in code. L48 evidence: waves 1–2 of this plan *are* a
wayfinder (decision → person → record); if the chain runs them cleanly,
wayfinder becomes a plan template with `kind: hitl` decision nodes.
**Promote?:** no.

### Dogfood findings (append one bullet per finding as the chain runs)
- 2026-09-25 (s15, plan creation) — `plan.sh add --leaf <label>` without
  `--tier auto` does nothing: the node gets the plan's `default_tier` and
  `plan-tiers.env` is never consulted. `frontier` showed `standard` for a
  `design` leaf until `tier: auto` was set by hand. Candidate fix: `--leaf`
  implies `tier: auto` unless `--tier` is given; say so in "Create a plan"
  step 3. Not fixed here.
- 2026-09-25 (s15) — `--blocked-by` takes full ids (`01-decision-note`), not
  numbers; the error `names no node 01` cost a round-trip. Cosmetic; the skill
  could show an example with a full id.
- 2026-09-25 (s15) — node checks run with cwd = the item directory
  (`plan.sh:336`, `cd "$ITEM"`), so `--check` paths are item-relative;
  `WORKSPACE_ROOT` is exported for the rest. Worth one sentence in the
  `docs/plans.md` `check` row if it is not there.
- 2026-09-25 (s15) — `session-loop.sh` page text for an `interactive` staging
  left open: jev session 6 sat idle from 2026-09-23 to 2026-09-25 while the
  supervisor paged `staged_alive seq=6 — session #6 staged a successor and is
  still running` every 15 min (28 KB log) although `session-state.json` said
  `staged: null`; the session had staged nothing — it was the one *staged
  by* session 5. When it quit, the supervisor closed the chain correctly
  (`quit_plain`). Two findings: the page names the wrong condition, and there
  is no idle policy for an interactive staging (perhaps by design — a human
  step). Session-loop, plans item.
- 2026-09-25 (s15) — two sessions on one checkout: session 6 of the dogfood
  item committed (524bb2a) ten minutes after this session started, so the
  first pass at its launcher and ledger was written against a stale snapshot
  and redone. A plan-creation step should re-read `git log -1` and the files
  it will rewrite right before writing; the skill's "Create a plan" could say
  so where it touches another item's launcher.
- 2026-09-27 (s16) — the s15 redo left its stale first pass in place: the
  jev-integration ledger carried the session-6 block twice and both versions
  of the 6→7 bridge (the stale one said session 6 "never closed"). A redo of a
  ledger write must delete the superseded block, not just prepend the new one;
  a `handoff.md` header-uniqueness check (`grep -c` of each `# Session Handoff`
  line) would have caught it. Deduped in s16; the stale bridge's one unique
  fact (two supervisor processes) folded into the kept bridge.
- 2026-09-27 (s16) — the s15 ledger block for *this* item was spliced into
  the ledger's HTML comment header (the write anchored on the first
  `# Session Handoff` text, which is the comment's own example, not a block).
  Second ledger-write defect from one session; both would be caught by a
  cheap `handoff.md` lint: header comment intact, block headers unique,
  first block header after `-->`. Candidate ticket 12 (with the dedupe
  finding above): a `scripts/check-ledger.sh` or a `plan.sh`/checkpoint
  step that runs it. Fixed by hand in s16.
- 2026-09-27 (s7 of jev-integration, first hands-off run of the plan) — a
  `work` node and its wave's reconcile ran in one session with no rollover
  split: node 01 (a Tier-2 note from closed research) cost ~35K tokens of
  work. The window opened at 60K tokens (39% of the 150K STOP) before any
  work — harness baseline (system prompt, tool schemas, skill list) — so a
  node has ~60K of real budget below WARN, not 120K. Worth a sentence in
  `docs/plans.md` sizing guidance; ticket 11's "did a split happen": no.
- 2026-09-27 (s7) — `plan.sh` rejects `--project <item>` when the flag and
  value arrive as one word (zsh `P="--project x"; plan.sh done id $P` →
  `unknown option --project jev-integration`); four verbs silently did not
  run and the session only noticed because `check` returned 2. Cosmetic
  (caller error), but a `--project=<item>` form would remove the trap.
- 2026-09-27 (s7) — the reconcile procedure's step 3 ("record forks as
  Tier-2 notes") is a no-op when the wave's only work node *is* a Tier-2
  note; fine, but the skill could say "unless the node's output already is
  one". Step 2 worked as written: `verify`, claim-id greps, `git diff`.
- 2026-09-27 (s7) — hitl handoff: the reconcile node 02's Goal told this
  session to rewrite the launcher prose for the person (what node 03 asks);
  that instruction lived in the node file, not in the skill. If it holds up,
  "Run a reconcile node" should say: when the next frontier is `hitl`, the
  launcher's prose carries the question and how to answer it
  (`done <id> --by human` / amend / `drop`).

## 2026-09-27 — Dogfood findings from jev-integration session 8 (plan 01-gated-integration, wave 3)
**Observed:** (a) `plan.sh add` writes empty `## Goal` / `## Acceptance`, so "Create a plan" step 4 (Ticket:/Spec: pointer, "What to build", the ticket's boxes) is a hand copy per node — done here with a one-off Python pass over six tickets; an `add --from-ticket <path>` would remove the step and the transcription risk. (b) `--project jev-integration` held in one shell variable is rejected ("unknown option") — the launcher already warns, it still cost one call; a `plan.sh` hint naming the fix, or accepting `--project=<item>`, would close it. (c) `frontier` exits 1 while the wave's reconcile node is `doing` — correct, but it fails a `&&` chain that only wanted the listing. No overruns; nodes 05 and 06 fit one session with ~40K headroom.
**Promote?:** no — fixes under the plans item (`issues/11-dogfood.md`).

## 2026-09-27 — Dogfood findings from jev-integration session 9 (plan 01-gated-integration, wave 4)
**Observed:** (a) A one-node wave's reconcile is mostly `verify` plus a Tier-2 note — fine, no procedure gap. (b) A `check:` that runs a test from `$WORKSPACE_ROOT` worked from `work/<item>/` as documented; the only trap was the operator's (`VAR=x cmd "$VAR"` does not expand on the same line), not the plan's. (c) A node's `check` proving the seam does not protect a session from an ad-hoc run against the live vendor: the plan has no place for "safe-run" guards beyond the launcher's Constraints; `note` carried it. No overruns; node 07 fit with ~60K headroom.
**Promote?:** no

- **s10 (jev-integration, node 09):** a standard-tier seam node (helper + tests + skill doc) consumed ~70K of the window on top of a 61K harness baseline, so one such node per session is the realistic budget; the launcher should size waves accordingly rather than list two work nodes as "do both".

- **s11 (jev-integration, node 11):** the node's `check:` named `scripts/jev.sh`
  relatively; `plan.sh done` runs a check from the work item directory
  (`cd "$ITEM"`), so it failed and the node went `blocked` although the same
  command passed from the workspace root. `plan.sh check` did not flag it.
  Fixed by prefixing `"$WORKSPACE_ROOT/"` (a reconcile-authority edit).
  **Suggest:** a Check rule — a `check:` that starts with a relative path
  (`scripts/`, `./`) is a violation — and one line in docs/plans.md stating
  the cwd a check runs in. Also: `done` streams the check's full output to the
  terminal (128 test lines here); a `--quiet` or tail-on-failure would spare
  the window. Promote?: no.

- **s14 (jev-integration, node 14):** ticket 06 ("requires a key, so it runs on
  the keyholder's machine after UAT") became a plain `work` node when the plan
  was created from the tickets, although its acceptance needs a person to
  authorize paid calls. Caught only at the wave 6 join; fixed with a hitl gate
  ahead of it (Replan rule 1 rename, `add` had numbered it after the join).
  **Suggest:** in "Create a plan from tickets", a ticket whose text says the
  user / a key / spend / a machine is required gets a `hitl` node in front of
  its work node at creation, not at the join. Promote?: no.

- **s15 (jev-integration, node 16, the last join):** (a) `sync` run before
  `done` leaves the launcher's Position block one state stale — the block is a
  snapshot, so the order is `done` → `sync`; the skill's step 5 lists them in
  that order but does not say why. (b) "Create a plan from tickets" never
  touches the tickets again: all six `Status:` lines still read
  `ready-for-agent`/`ready-for-human` after every node closed, and the triage
  vocabulary has no terminal state for an implementation ticket (only the
  wayfinder's `claimed`/`resolved`); this join used `resolved` + the node id.
  **Suggest:** the reconcile step flips the ticket a node's `Ticket:` line
  names, or the tracker doc names the terminal state. (c) No `plan.sh` verb
  closes a plan although the loop reports `plan_closed`; closing is a hand
  edit of `status: closed` in plan.md, and write verbs refuse a closed plan,
  so it must be the last write. Fine for a person, but the skill's replan
  ladder should say so in one line. Promote?: no.
- 2026-09-27 (jev-integration s16): closing a plan by hand works as s15
  described — `status: open` → `closed` in `plan.md` as the last write, then
  `sync`; `status` prints `closed`, the launcher's Position block re-rendered
  `closed`, no verb complained. The dogfood plan therefore never produced a
  chain-side `plan_closed` verdict (ticket 11 box 1 stays open, noted under
  its Comments). Post-close, a one-session ticket (07) ran with no plan at
  all, as the assessment proposed — the right size for it.
- s17 (jev-integration dogfood, 2026-09-28): with a closed plan 01 on disk, `plan.sh add` without `--plan` targets the closed plan and is refused ("writes need an open plan") even though `new` just created plan 02 — the default plan should be the open one, or `new` should print the `--plan` flag the next writes need. Also confirmed: `--project <item>` inside a shell variable is refused (unknown option); flags must be literal words.
- s18 (jev-integration dogfood, 2026-09-28, second strike on the stale default plan): `session-loop.sh` binds `PLAN` from the record's `chain.plan` at start — here `01-gated-integration`, left from the earlier chain — while plan `02-follow-on` was the open one. Two effects: its between-children `plan_sh sync` re-rendered the launcher's Position block to plan 01's `closed` line (the s17 rollover commit had plan 02's), and its post-child check finds plan 01 closed with reconcile 16 done → `plan_closed` verdict, chain ended, the staged successor never launched. Proposed fix (this item may not edit the loop): when `chain.plan` names a closed plan and exactly one other plan is open, rebind to the open one (or refuse `plan_invalid leg=closed` naming `--plan`); recovery today is `scripts/session-loop.sh <item> --plan <open> --reopen`.

## 2026-09-30 — L48 verdict: wayfinder as a plan template — adopt as a recipe, keep the wayfinder skill
**Decision:** Take L48 up as a *recipe* in `skills/plans/SKILL.md` ("Create a plan before a spec exists": draft note → `hitl` approval → spec + tickets → structural replan at the join), not as a replacement for `wayfinder`.
**Why:** The dogfood plan `jev-integration/plans/01-gated-integration` ran exactly that shape: waves 1–2 were a one-ticket wayfinder (decision note, a person approves), wave 3's join added waves 4–7 from the tickets, and it closed 18/18 over 8 sessions with no split. The plan carried the decision gate as a `hitl` node at no extra cost and kept one board from decision to delivery.
**Rejected:** (a) retire `wayfinder` in favour of plans — a wayfinder map with many open decisions and no delivery waves is lighter than a plan and still the right tool when nothing will be built yet; one dogfood is not evidence for a map of ten decisions. (b) Leave L48 deferred — the evidence exists now and the recipe costs one skill section.
**Promote?:** no — lands with ticket 15.

## 2026-09-30 — ticket 11 closed; findings triaged into tickets 12–15
**Decision:** Bugs first (12 ledger lint, 13 stale default plan), then CLI ergonomics (14), then docs/skill wording (15). `add --from-ticket` (s8 a) and `frontier`'s exit 1 while a reconcile is `doing` (s8 c) are not taken: the first is a feature, the second is correct behaviour.
**Promote?:** no
