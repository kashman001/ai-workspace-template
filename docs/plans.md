# Plans — node-file format and `plan.sh`

A **plan** is a dependency graph of work for one work item, kept as one
markdown file per node under `work/<item>/plans/NN-<slug>/`. `scripts/plan.sh`
reads and writes it. Node files are the truth; `plan.md` is hand-written prose
plus a rendered board. Concept and glossary: `work/plans/concept.md`; spec:
`work/plans/spec.md`; procedures (create, reconcile, replan, subagent prompt):
`skills/plans/SKILL.md`. Front door: `CONTEXT.md` → "Plans" and the glossary
under "Language".

## Format

```
work/<item>/plans/NN-<slug>/
  plan.md            frontmatter + Goal / Not yet specified / Out of scope / Replans + board
  nodes/NN-<slug>.md one file per node
```

**`plan.md` frontmatter** — `plan: NN-<slug>`, `status: open | closed`,
`replan: local | structural`, `default_tier: frontier | standard | cheap | auto`,
optional `wave_max: <integer>` (nodes per wave before `check` complains;
default `PLAN_WAVE_MAX` in `context-budget.env`, 6 when unset), optional
`tier_<label>: frontier | standard | cheap` lines — this plan's override of
the workspace tier table for one `leaf` label (see "Tiers").
The board is rendered between `<!-- plan:begin board -->` and
`<!-- plan:end board -->`; nothing outside the markers is ever generated.
The item's launcher (`work/<item>/next-session.md`) opts in the same way
with a `position` pair, and `sync` writes a two-line block there:
`Position: plan NN-<slug>, <status>, wave n of m, done d/t, doing n, todo n,
blocked n, dropped n, sessions n.` then `Frontier: <ids | none (<id> doing)>.
Remaining: r of t — wave n: <id status, …>.` Markers are added by hand and
never invented (convention: `docs/work-directory-conventions.md` →
"Generated blocks").
One plan is open per item at a time; a plan closes in place (`status: closed`)
and the next one takes the next number, so "latest" is a directory listing.

**Node frontmatter** — flat YAML, one `key: value` per line, `# comment`
allowed after two or more spaces (a `#` glued to text, as in a `grep '^##'`
inside `check`, is kept). Sections below it: `## Goal`, `## Acceptance`, `## Log`.

| Field | Values | Default |
|---|---|---|
| `id` | the file's stem, `NN-<slug>` | required |
| `title` | free text | `""` |
| `status` | `todo` `doing` `done` `blocked` `dropped` | required |
| `kind` | `work` `reconcile` `hitl` | `work` |
| `wave` | integer, waves run in order | required |
| `blocked_by` | `[id, id]` — node ids in this plan | `[]` |
| `tier` | `frontier` `standard` `cheap` `auto` | plan `default_tier`; `frontier` for `reconcile` and `hitl` |
| `leaf` | a label, `[a-z][a-z0-9_]*` — the kind of leaf work, looked up when `tier` is `auto` | none |
| `parallel` | integer, subagents in flight inside the node | `1` |
| `loop` | integer, attempts before `blocked` | `1` |
| `check` | a shell command, kept verbatim | none |
| `sessions` | `[n, n]` — session numbers that worked the node | `[]` |
| `isolated` | `yes` / `no` | `no` |

`blocked` is explicit, with the reason as the latest Log line; "waiting on
edges" is derived, never written. Anything else — a missing opening or closing
`---`, a line that is not `key: value`, a value outside the sets above — is
refused with exit 1 and a line on stderr naming the file.

## `plan.sh`

```
scripts/plan.sh <verb> [args] [--project <item>] [--plan <name>] [--json]
```

| Verb | Does | Text output |
|---|---|---|
| `new <slug>` | creates the next-numbered plan with an empty `plan.md` skeleton; refuses (exit 1) while a plan is open | `created work/<item>/plans/NN-<slug>` |
| `status` | derived from the node files | `plan NN-<slug>  open  wave 2 of 3  done 5/9  doing 1  todo 3  blocked 0  dropped 0  sessions 2` |
| `show <id>` | one node: the file in text, its parsed frontmatter plus `path` in `--json` | the file |
| `frontier` | `todo` nodes whose blockers are all `done` or `dropped`, in the lowest wave that still has unfinished nodes; exits 1 with the reason when that wave has nothing ready | `06-reconcile-write     reconcile  frontier` (id, kind, resolved tier; ` (auto)` appended when the node's own tier is `auto`) |
| `remaining` | every node that is neither `done` nor `dropped`, by wave then id | `07-spec                doing    wave 3` |
| `graph` | the whole plan, one block per wave, each node with its blockers | `  08-tickets  todo  work  <- 07-spec` under a `wave 3` heading |
| `check` | lints the plan against the rules below; every violation at once, exit 1 when any, silent and exit 0 on a clean plan | `<node path>: hitl node has a check` or `wave 3: 0 reconcile nodes (want exactly one)` |
| `start <id>` | `todo` → `doing` for a frontier node (`--force` for one off it), or `blocked` → `doing`; adds the session to `sessions`, logs `started, tier <t>` (see "Tiers" for the unavailable forms) | `08-tickets doing` |
| `done <id>` | `doing` → `done` once the node's `check` passes (`--force` allows `todo` → `done`); a `kind: hitl` node needs `--by human`; a failing check is refused, and the Nth failure (`loop: N`) writes `blocked` | `07-spec done` |
| `verify <id>` | runs the check and reports; changes nothing; exit 1 on failure | `07-spec: check passed` / `check failed (exit 4)` / `no check` |
| `block <id> <reason>` | `doing` → `blocked`, the reason as the latest Log line | `07-spec blocked` |
| `drop <id> [reason]` | any → `dropped` | `08-tickets dropped` |
| `add <slug> --wave <n> [--title …] [--kind …] [--tier …] [--leaf label] [--blocked-by a,b] [--parallel n] [--loop n] [--check …] [--isolated]` | writes `nodes/NN-<slug>.md` (next number, `status: todo`, empty Goal/Acceptance/Log); refuses a taken slug or a blocker naming no node; does not lint | `10-board-renderer todo` |
| `note <text>` | appends `- s<n> · <text>` to `plan.md` → "Not yet specified"; touches no node file and never the board | (silent) |
| `sync` | re-renders the board into `plan.md` and the position block into `work/<item>/next-session.md`, each strictly between its markers; idempotent; both marker pairs are checked before either file is written, and a missing one is exit 1 naming the file and the marker (nothing written). Resolves the plan read-style, so a closed plan still syncs | `synced work/<item>/plans/NN-<slug>/plan.md, work/<item>/next-session.md` |

"Wave n of m" is the lowest wave with a node that is neither `done` nor
`dropped`, of the highest wave number. "Sessions" is the count of distinct
session numbers across every node's `sessions`. `--json` mirrors each verb:
`status` gives `{plan, status, wave:{current,total}, counts:{todo,doing,done,blocked,dropped,total}, sessions_used}`;
`frontier` and `remaining` give an array of node objects as `show` prints them
(every node object carries `tier_resolved` and `model`, null for the session model);
`graph` gives `{plan, nodes:[{id,title,status,kind,tier,wave,blocked_by}], edges:[{from,to}]}`
with one edge per `blocked_by` entry, blocker → node. `sync` gives
`{plan, files:[…]}`, the two paths relative to the workspace root.

**Frontier.** "Waiting on edges" is derived here, never stored. The frontier
is empty in two ways: nothing is unfinished (exit 0, no output, `[]`), or the
current wave has nothing ready (exit 1, `plan: frontier empty: wave 3 has
nothing ready — 07-spec doing; 08-tickets waits on 07-spec`, with `; ready
only in a later wave: …` appended when a later wave has an unblocked node —
waves run in order, so it is not offered). A `blocked_by` naming no node in
the plan is refused (exit 1, naming the file) by every verb. No DOT output
yet; `graph --json` carries the edges for anything that wants to draw.

**State machine.** `todo → doing → done`, `doing → blocked → doing`, any →
`dropped`; every other transition is refused with exit 1 and the file
untouched. Write verbs edit one node file in place — the frontmatter keeps
its line order and comments, and a `- <who> · <what>` line is appended under
`## Log` — so `done` written by anything but `plan.sh done` is outside the
contract (nothing stops a hand edit; the Log just will not say why). `<who>`
is `--by <actor>` when given, else `s<n>` with the session number from
`--session <n>` or `seq` in the item's `session-state.json`; `start` always
needs a number (the `doing-sessions` rule), the other write verbs accept
either. A node's `check` runs from `work/<item>/` with `WORKSPACE_ROOT` in
the environment and its output on stderr. Failed attempts are counted from
the node's own Log lines since it was last `started`, so a resumed node gets
its `loop` again. Write verbs resolve the plan strictly — `--plan`,
`chain.plan`, the single open plan, else refuse — and refuse a closed plan.
`start` does not lint; the session loop runs `check` between children.

**Check rules.** `check` parses leniently — a bad node is one violation, not a
refusal — so one run lists everything. Text is `<where>: <message>` (the node
file, `plan.md`, or `wave N`); `--json` is an array of
`{rule, id, wave, path, message}` (`id`/`wave`/`path` null where they do not
apply). The rules, by `rule` slug:

- `malformed` — a node or `plan.md` whose frontmatter any other verb would
  refuse (missing `---`, a non-`key: value` line, a value outside the sets
  above, a non-integer `wave_max`, a `tier_<label>:` outside
  `frontier|standard|cheap`). The node is left out of the other rules.
- `blocked-by` — a `blocked_by` entry naming no node in this plan (a typo, or
  a node in another plan). Other verbs refuse the plan on this; `check` lists it.
- `reconcile-count` — a wave with zero or several `kind: reconcile` nodes.
- `reconcile-last` — the wave's reconcile node is not the last id in the wave
  (ids sort by number; the join comes after what it joins). Only checked when
  the wave has exactly one.
- `hitl-check` — a `kind: hitl` node with a `check` (the human's tick is the
  acceptance).
- `doing-sessions` — a `status: doing` node with an empty `sessions`.
- `wave-size` — more nodes in a wave than `wave_max` (plan) or `PLAN_WAVE_MAX`
  (explicit env, then `context-budget.env`, then 6).

**Tiers.** A node's `tier` is what runs it; `auto` defers the choice. `auto`
resolves, first match wins: the plan's `tier_<label>:` line → `PLAN_TIER_<LABEL>`
in the workspace's `plan-tiers.env` → the plan's `default_tier` → `standard`,
where `<label>` is the node's `leaf:`; a node with no `leaf`, or a label neither
file names, skips straight to the plan default (no violation, no warning). A
`default_tier: auto` bottoms out at `standard`. `reconcile` and `hitl` nodes
default to `frontier` and resolve `auto` to `frontier` (fan-in reads every
sibling's output, so it gets the strongest model). A `tier_<label>:` or
`PLAN_TIER_*` value outside `frontier|standard|cheap` is refused (exit 1,
naming `plan.md` or `plan-tiers.env`); `auto` is not a policy value. The board
keeps the written tier — the orchestrator reads `frontier`.

The same file maps tiers to model knobs, one row per runtime:
`PLAN_MODEL_<RUNTIME>_<TIER>` is what that runtime's model flag takes
(`claude --model`, `codex --model`, `gemini --model`, `opencode --model`,
`copilot --model`); shipped set for claude only (`opus`/`sonnet`/`haiku`), the
others present but commented out. The runtime is `--runtime <r>` →
`PLAN_RUNTIME` → the `runtime` of the session's registry record → unknown.
Node JSON carries `model` (null when the runtime has no knob for the resolved
tier, or is unknown — either way the session runs on its own model). `start`
stamps what was decided, never what ran: `started, tier cheap` when a knob
exists, `started, tier cheap unavailable on gemini (session model)` when the
runtime has none, `started, tier cheap unavailable (no runtime; session model)`
when no runtime is known. No model name reaches a plan or node file;
`plan-tiers.env` is the one place a model is named, so a model change is one
line there and no plan edit.

**Exit codes** are the contract: `0` ok; `1` lint or state refusal (malformed
node, unknown value, unknown id, a plan already open, an illegal transition,
a failing check); `2` usage or resolution failure. Refusals print `plan: <detail>` on stderr.

**Resolution.** The work item: `--project` → the session registry binding
(a `.context-budget/sessions/*.json` record with a `project` whose `pid` and
`pid_start` name an ancestor of the calling process) → `TF_SESSION_PROJECT`
→ the `work/<item>/` the current directory is inside → refuse. The plan:
`--plan` → `chain.plan` in the item's `session-state.json` → the single open
plan → refuse when none or several are open; read verbs (`status`, `show`)
fall back to the latest plan by number instead of refusing. The supervisor
(`scripts/session-loop.sh`) writes `chain.plan` when it starts a chain, so
every session in that chain resolves the same plan without `--plan`
(`docs/context-budget.md` → "The supervisor", "Plans").

**Replans.** Capture at once, restructure at the join: a discovery is a
`note` (into "Not yet specified") the moment it is made; the graph changes at
the wave's reconcile node, each change as a line under `## Replans` in
`plan.md`. Authority is by blast radius — **local** (split a node, add a
follow-up node in an existing wave): the agent, any time; **structural** (a new
wave, a cross-wave re-edge, a drop): the reconcile node, hands-off only when
`plan.md` says `replan: structural`, else a `kind: hitl` node carries the
proposal to a person; **goal**: a person, always, by closing the plan and
opening the next. A node added to a wave that already has its reconcile node
takes the number of the node it follows plus a suffix (`add`, then rename the
file and its `id:`), so the join stays the wave's last id. Procedures:
`skills/plans/SKILL.md`.

**Wayfinder and plans.** A wayfinder map (`work/<item>/map.md` plus decision
tickets under `issues/`, one resolved per session; `skills/wayfinder/SKILL.md`)
is a plan whose nodes are all decisions: the map is `plan.md`, each decision
ticket is a `kind: hitl` node, and the wave's reconcile node is the session
that records the answer. The two coexist untouched for now — wayfinder for a
chain of decisions a person makes, a plan for work an agent performs against
checks — and wayfinder becomes a plan template (or retires) only after the
first real plan has closed (backlog card L48).

## Per runtime

`plan.sh` is bash plus the standard tools, so every runtime runs it as is; the
skill is plain markdown, so every runtime drives it by reading
`skills/plans/SKILL.md` and following the named procedure. What differs:

| Runtime | Invoking the skill | Model knobs (`plan-tiers.env`) |
|---|---|---|
| Claude Code | `/plan <create\|reconcile\|replan> [args]` (`.claude/commands/plan.md`), or by name | `PLAN_MODEL_CLAUDE_<TIER>` shipped (`--model` aliases) |
| Codex | "run the plans skill, procedure <name>" — the skill is listed in `CONTEXT.md` → Workspace Skills, which `AGENTS.md` links | `PLAN_MODEL_CODEX_<TIER>` present, commented out |
| Gemini CLI | same, via `GEMINI.md` | `PLAN_MODEL_GEMINI_<TIER>` present, commented out |
| OpenCode | same, via `AGENTS.md` | `PLAN_MODEL_OPENCODE_<TIER>` present, commented out |
| Copilot | same, via the entrypoint its hook wiring names (`docs/context-budget.md` → "Vendor hook deployments") | `PLAN_MODEL_COPILOT_<TIER>` present, commented out |

Uncommenting a runtime's rows is the whole setup for tiers there; until then a
node resolved to a tier that runtime has no knob for runs on the session model
and `start` logs `unavailable on <runtime>`. Binding a session to the item
(`scripts/context-budget.sh register --project <item>`) is what lets the verbs
omit `--project`; the `SessionStart` hooks do it for Claude Code and Copilot,
the other runtimes register by instruction (`docs/context-budget.md` →
"Session registration"). The runtime `plan.sh` reports in `model` is the one
the session registered as, so an unregistered session sees `null` and
`unavailable (no runtime; session model)` in the Log.

## Worked example

The fixture plan `scripts/tests/fixtures/plan-01-concept/` is the concept
item's own history written as a plan: three waves, nine nodes, each wave
closed by a reconcile node, one `hitl` node per wave where a person decided.
Its `plan.md` opens:

```
---
plan: 01-concept
status: open
replan: local        # structural replans need a person
default_tier: standard
---
```

and one node, `nodes/03-reconcile-ground.md`, is the whole format:

```
---
id: 03-reconcile-ground
title: Join the inventory and the discussion
status: done
kind: reconcile
wave: 1
blocked_by: [01-seam-inventory, 02-concept-discussion]
tier: frontier
sessions: [1]
---

## Goal
Join the inventory and the discussion.

## Acceptance
- [ ] Done when the orchestrator says so.

## Log
```

With `07-spec` doing and `08-tickets` waiting on it, a session reads the plan
so (all from the workspace root, the item bound or `--project plans` added):

```
$ scripts/plan.sh status
plan 01-concept  open  wave 3 of 3  done 6/9  doing 1  todo 2  blocked 0  dropped 0  sessions 2
$ scripts/plan.sh frontier; echo "exit $?"
plan: frontier empty: wave 3 has nothing ready — 07-spec doing; 08-tickets waits on 07-spec; 09-reconcile-verdict waits on 07-spec, 08-tickets
exit 1
$ scripts/plan.sh done 07-spec --session 3      # runs the node's check first
07-spec done
$ scripts/plan.sh frontier
08-tickets             work       standard
$ scripts/plan.sh start 08-tickets --session 3
08-tickets doing
$ scripts/plan.sh check && scripts/plan.sh sync
synced work/plans/plans/01-concept/plan.md, work/plans/next-session.md
```

The board between the markers in `plan.md` and the Position block in the
launcher now say the same thing as `status`. `scripts/tests/test-plan.sh` runs
the verbs against this fixture; `scripts/tests/test-session-loop.sh` covers the
supervisor's use of `frontier` and `check` between children.
