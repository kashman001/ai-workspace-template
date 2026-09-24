# Plans — node-file format and `plan.sh`

A **plan** is a dependency graph of work for one work item, kept as one
markdown file per node under `work/<item>/plans/NN-<slug>/`. `scripts/plan.sh`
reads and writes it. Node files are the truth; `plan.md` is hand-written prose
plus a rendered board. Concept and glossary: `work/plans/concept.md`; spec:
`work/plans/spec.md`. This doc grows one section per landed ticket.

## Format

```
work/<item>/plans/NN-<slug>/
  plan.md            frontmatter + Goal / Not yet specified / Out of scope / Replans + board
  nodes/NN-<slug>.md one file per node
```

**`plan.md` frontmatter** — `plan: NN-<slug>`, `status: open | closed`,
`replan: local | structural`, `default_tier: frontier | standard | cheap | auto`.
The board is rendered between `<!-- plan:begin board -->` and
`<!-- plan:end board -->`; nothing outside the markers is ever generated.
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
| `tier` | `frontier` `standard` `cheap` `auto` | plan `default_tier`; `frontier` for `reconcile` |
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
| `frontier` | `todo` nodes whose blockers are all `done` or `dropped`, in the lowest wave that still has unfinished nodes; exits 1 with the reason when that wave has nothing ready | `06-reconcile-write     reconcile  frontier` (id, kind, tier) |
| `remaining` | every node that is neither `done` nor `dropped`, by wave then id | `07-spec                doing    wave 3` |
| `graph` | the whole plan, one block per wave, each node with its blockers | `  08-tickets  todo  work  <- 07-spec` under a `wave 3` heading |

"Wave n of m" is the lowest wave with a node that is neither `done` nor
`dropped`, of the highest wave number. "Sessions" is the count of distinct
session numbers across every node's `sessions`. `--json` mirrors each verb:
`status` gives `{plan, status, wave:{current,total}, counts:{todo,doing,done,blocked,dropped,total}, sessions_used}`;
`frontier` and `remaining` give an array of node objects as `show` prints them;
`graph` gives `{plan, nodes:[{id,title,status,kind,tier,wave,blocked_by}], edges:[{from,to}]}`
with one edge per `blocked_by` entry, blocker → node.

**Frontier.** "Waiting on edges" is derived here, never stored. The frontier
is empty in two ways: nothing is unfinished (exit 0, no output, `[]`), or the
current wave has nothing ready (exit 1, `plan: frontier empty: wave 3 has
nothing ready — 07-spec doing; 08-tickets waits on 07-spec`, with `; ready
only in a later wave: …` appended when a later wave has an unblocked node —
waves run in order, so it is not offered). A `blocked_by` naming no node in
the plan is refused (exit 1, naming the file) by every verb. No DOT output
yet; `graph --json` carries the edges for anything that wants to draw.

**Exit codes** are the contract: `0` ok; `1` lint or state refusal (malformed
node, unknown value, unknown id, a plan already open); `2` usage or resolution
failure. Refusals print `plan: <detail>` on stderr.

**Resolution.** The work item: `--project` → the session registry binding
(a `.context-budget/sessions/*.json` record with a `project` whose `pid` and
`pid_start` name an ancestor of the calling process) → `TF_SESSION_PROJECT`
→ the `work/<item>/` the current directory is inside → refuse. The plan:
`--plan` → `chain.plan` in the item's `session-state.json` → the single open
plan → refuse when none or several are open; read verbs (`status`, `show`)
fall back to the latest plan by number instead of refusing.

Tests: `scripts/tests/test-plan.sh` against the fixture plan
`scripts/tests/fixtures/plan-01-concept/` (the worked example in the concept note).
