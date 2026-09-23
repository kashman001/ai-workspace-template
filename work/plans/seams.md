# Seam inventory — what the workspace already does, against the plan concept

Written 2026-09-23 (session 1). A one-time reference: for each existing
mechanism, what part of a **plan** it already covers, what it lacks, and what
a plan should do with it (**wrap** it, **replace** it, or **leave it alone**).
The verdict column is a proposal from the session-1 discussion; each becomes
binding only when recorded in `decisions.md`.

The plan concept it is measured against (see `README.md`): a **graph** of
**nodes** with dependencies; **waves** = a parallel fan-out ending in a
**reconcile** node; **loops** = a node repeats until a check passes, with a
cap; **sessions** = a node is sized to one context budget and a plan spans
many sessions; **tiers** = a node names the cheapest LLM tier that can do it.

Every line-number claim below was verified on disk this session.

## Coverage at a glance

| Mechanism | Graph | Waves | Loops | Sessions | Tiers | Verdict |
|---|---|---|---|---|---|---|
| `to-tickets` issue files | edges | – | – | – | – | **wrap** (a node is a ticket plus a few fields) |
| `wayfinder` map + tickets | edges, frontier | – | – | one ticket per session | – | **wrap** (replan model; a decision plan is a wayfinder map) |
| Workflow tool | in-script DAG | `parallel`/`pipeline` | JS loops | single session | `model`, `effort` | **leave alone**, use inside a node |
| `research-wave` | phases | fan-out + fact-check join | second round | dispatch records as resume points | – | **leave alone**, the model for a reconcile node |
| `loop` skill (built-in) | – | – | ticks, judgement exit | one conversation | – | **leave alone**, not a plan loop |
| `session-loop.sh` | – | – | outer loop, caps | chains sessions | – | **wrap** (tell it which plan; add a plan-closed verdict) |
| `launch-next-session.sh` | – | – | – | one rollover, gates | – | **leave alone** |
| `fleet.sh` dispatch records | – | per-task records, no join | generations | child resume points | `--model`, `--effort` recorded | **wrap** (node dispatch writes a record) |
| `rlm` | fixed 4 steps | `llm_query_map` + root aggregation | depth cap | REPL state persists | root/leaf knobs | **leave alone**, a tier-aware leaf tool |
| launcher / ledger | – | – | – | carries work across sessions | – | **wrap** (launcher becomes a projection of the plan) |

Nothing on this list covers **tiers as a plan property**, a **check-based loop
exit with a cap** outside code, or a **reconcile step named on disk**. Those
three are the genuinely new parts of a plan. Everything else is joining.

## The mechanisms

### to-tickets issue files (`skills/to-tickets/SKILL.md`, `docs/agents/issue-tracker.md`)

- **Covers.** A ticket is one file, `work/<effort>/issues/NN-<slug>.md`,
  numbered from 01 (issue-tracker.md:27–29). It carries "What to build",
  acceptance boxes, and a "Blocked by" list (SKILL.md:105–115). A ticket with
  no blockers can start; the **frontier** is "any ticket whose blockers are
  all done" (SKILL.md:78). That is a node with edges.
- **Lacks.** No wave, no tier, no loop check, no session count, no log of what
  happened. Status is a triage state, not an execution state (issue-tracker.md:30–33).
- **Verdict: wrap.** A node file is a ticket file plus flat frontmatter
  (`status`, `blocked_by`, `wave`, `tier`, `parallel`, `loop`/`check`,
  `sessions`) and a `## Log`. Existing tickets convert by adding lines.

### wayfinder map and decision tickets (`skills/wayfinder/SKILL.md`, `docs/agents/issue-tracker.md:132–160`)

- **Covers.** The map is an index with Destination, Notes, Decisions so far,
  Not yet specified, Out of scope (SKILL.md:40–63). Tickets are children with
  `Blocked by: NN, NN`; frontier = open, unblocked, unclaimed
  (issue-tracker.md:143–147). One ticket per session (SKILL.md:116). HITL vs
  AFK ticket types (SKILL.md:86). The **fog of war** rule: chart only what
  you can state precisely, graduate the rest later (SKILL.md:93–104).
- **Lacks.** Tickets are decisions, not work; the map forbids execution by
  default (SKILL.md:22–24). No parallel tickets, no tier, no loop, no
  reconcile step, no session accounting beyond "one per session".
- **Verdict: wrap.** The plan index reuses the map's sections verbatim; "Not
  yet specified" is the plan's capture queue for discoveries, and a plan whose
  nodes are all decisions *is* a wayfinder map. Wayfinder's own workflow stays
  untouched.

### Workflow tool (built-in; `workflow-authoring` reference)

- **Covers.** A script builds an agent DAG: `agent()` with `model`, `effort`,
  `isolation: 'worktree'`, `schema`; `parallel()` as a barrier; `pipeline()`
  with no barrier; `phase()` for grouping; plain JS `while` loops with budget
  or count exits. Resume via `resumeFromRunId` replays cached agent results.
- **Lacks.** Same-session only; resume is bound to one run and one script.
  No on-disk state another runtime can read. Claude Code only. Model choice is
  a literal in the script.
- **Verdict: leave alone.** A node's *work* may be a Workflow run (the
  orchestrator's fan-out inside one session). The plan never encodes a
  Workflow script; it records the fan-out and tiers used in the node log.

### research-wave (`skills/research-wave/SKILL.md`)

- **Covers.** Fixed phases Gate → Launch → Check → Rule → Sweep, each with a
  "Done when" line (:49–168). One directory per subject for write isolation
  (:76–77); one dispatch record per subject = "N independent resume points"
  (:78–80). The join is a **fact-checker that did not produce the result**,
  launched as each pass returns (:93–96), then the orchestrator rules and a
  corrections agent applies (:41, :124). A second round is expected (:139–140).
- **Lacks.** No tier field (only `disable-model-invocation: true`, :6). No
  cap on rounds. No edges between subjects. Context is called the binding
  constraint but never measured.
- **Verdict: leave alone.** It is the worked example of a wave: fan-out, a
  verifying join, a reconcile by the orchestrator. A plan's reconcile node
  should say "do what research-wave Phase 2–3 does", not re-specify it.

### loop skill (built-in; loaded via the Skill tool, no file on disk)

- **Covers.** Repeats a prompt on an interval or self-paced via
  `ScheduleWakeup` (`delaySeconds`, `prompt`, `noop`, `stop`); can gate a tick
  on a `Monitor`. Stops by judgement; "three or more consecutive checks found
  nothing" is the only cap-like rule.
- **Lacks.** No pass/fail check, no numeric cap, no state on disk, no fan-out,
  no tier. Lives inside one conversation.
- **Verdict: leave alone.** It is a polling loop, not a plan loop. A plan loop
  is a node with a `check` command and a cap; the orchestrator may *use* the
  loop skill to wait on something, but the plan does not reference it.

### session-loop.sh (`scripts/session-loop.sh`)

- **Covers.** The outer loop: `while :` runs one child session at a time in
  the foreground (:268, :284); strictly linear, next session only if `seq`
  advanced by one (:337). Caps: `--max-sessions` (default 10, :73),
  `--stall-limit` (default 3 hands-off sessions that commit nothing outside
  README/launcher/ledger, :75, :356–362), `--min-lifetime`, a watchdog.
  Owns the record's `chain` block: `supervisor`, `used`, `cap`, `closed`
  (:165–166, :328). Exports `TF_SESSION_LOOP`, `TF_SESSION_LOOP_PROJECT`
  (:162–163) and `TF_SESSION_PROJECT`/`TF_SESSION_SEQ` to the child (:300).
  Verdicts `staged`, `quit_stop`, `quit_plain`, `cap`; broken codes include
  `stall`. Never talks to a model (:10).
- **Lacks.** Knows nothing about *what* the sessions are doing: no plan, no
  nodes, no check-based exit. Progress = "did git commit anything"
  (`session_made_progress`, :357). No parallelism, no tier.
- **Verdict: wrap.** Add an optional `chain.plan` to the record (additive,
  schema stays 1), run the plan's sync/check between children, and add a
  `plan_closed` verdict so the plan's terminal node ends the chain instead of
  the cap. Without a plan, behaviour is unchanged.

### launch-next-session.sh (`scripts/launch-next-session.sh`)

- **Covers.** One rollover: atomically writes `seq`, `launch{...}`,
  `session=null`, `staged` (:427–435). Gates in order: `schema_mismatch`,
  `chain_closed`, `runtime_path_unsupported`, `supervised_stage_only`,
  `no_supervisor`, `owner_live`, `not_owner`, `worktree_unsynced`,
  `launcher_stale`, `launcher_unchanged`, `ledger_shape`,
  `ledger_seq_mismatch` (:29–32); `--dry-run` runs them all and writes nothing.
  `ROLLOVER_RELAUNCH` precedence: env → `work/<p>/context-budget.env` →
  global → `off` (:136–163). Runtimes: claude, codex, gemini, opencode,
  copilot variants (:396–403).
- **Lacks.** Never writes `next-session.md` (:32); only checks it exists and
  changed (:367–368). No model or tier flag to any runtime. One successor only.
- **Verdict: leave alone.** The plan's sync writes the launcher's generated
  block *before* this script runs, so its `launcher_unchanged` gate is
  satisfied naturally. No change needed.

### fleet.sh dispatch records (`scripts/fleet.sh`)

- **Covers.** One record per task at `work/<proj>/.agent-dispatch/<task>.json`
  (:226–231); record-level `task`, `project`, `report`, `brief`,
  `agent_type`, `model`, `effort`; per-generation `gen`, `dispatched_at`,
  `status`, `agent_id`, `closed_at`. Close statuses `DONE`,
  `DONE_WITH_CONCERNS`, `BLOCKED`, `NEEDS_CONTEXT`, `ROLLOVER_NEEDED`,
  `KILLED` (:270). `dispatch-list` exits 1 while any generation is open, the
  drain check a rolling parent uses (:286–299). `children` grades each
  child's transcript against the same thresholds as the parent (Claude only,
  :53–54). The dispatch contract makes the child append `[gen N]` progress
  blocks to its report and return ≤15 lines with a status word first.
- **Lacks.** `--model`/`--effort` are recorded, not enforced, and overwritten
  per open. No edges between tasks, no join, no check exit.
- **Verdict: wrap.** When a node fans out a long-running subagent, the
  orchestrator opens a dispatch record named after the node; the node log
  cites it. The tier actually used comes from this record. The join stays the
  reconcile node's job.

### rlm (`skills/rlm/SKILL.md`, `scripts/rlm_repl.py`)

- **Covers.** A four-step loop (Initialise, Probe, Decompose + sub-query,
  Aggregate) over a context too big to read. Leaves run in parallel via
  `llm_query_map(prompts, max_workers=8)` (:205); the join is root
  aggregation in Python. Tier knobs: `RLM_SUB_MODEL` (haiku),
  `RLM_ROOT_MODEL` (sonnet), `RLM_MAX_DEPTH` (1), `RLM_MAX_WORKERS` (:36–37,
  :85, :91). Mandatory `context-budget.sh record` at each phase boundary;
  WARN hands off via session-rollover because the REPL state persists
  (:242–244).
- **Lacks.** No independent verifier (self-run coverage counts only). No
  dependency graph. Leaves are `claude -p`, so the runtime-neutral claim
  holds for the driver, not the leaves.
- **Verdict: leave alone.** It is the existing proof that abstract tiers map
  to concrete models through env knobs. The plan's tier policy should use the
  same shape (a name → a per-runtime model), and a node may simply *be* an
  rlm run.

### launcher and ledger (`docs/work-directory-conventions.md`)

- **Covers.** Launcher `next-session.md`: forward-only, replaced each
  rollover, mandatory work under START HERE (:20–68). Ledger `handoff.md`:
  append-only, newest on top, two blocks live, checked by `check-ledger.py`
  (:70–119). One owner per item, the `session` in the record (:35–44). `seq`
  is the one source of truth for session numbers (:93–103). Two doors to end
  a session: session-rollover (continue) or checkpoint (stop) (:134–150).
  Everything is plain Markdown/JSON so any runtime or human can pick it up
  (:3–7). `STATUS.md` is an optional human snapshot (:160); `map.md` +
  `issues/` is the optional wayfinder map (:162).
- **Lacks.** No generated sections and no marker convention: the launcher is
  hand-written prose, so "what next" and "where are we" are re-derived by the
  agent every rollover. No node, wave, loop, or tier vocabulary.
- **Verdict: wrap.** The launcher gains a generated block (between marker
  comments) rendered from the plan's frontier; the ledger keeps its role
  unchanged and cites nodes by id. The plan index, not `STATUS.md`, becomes
  the human snapshot while a plan is open.

## Vocabulary already in use

The local teaching item (`work/learn-agentic-workflows`, gitignored) grounds
its terms in Anthropic's "Building Effective Agents" only: **node** ("one
unit of work"), **edge** ("when this finishes, that runs next"), fan-out /
fan-in, **workflow** = DAG, **agent** = cyclic graph with an exit condition;
and five patterns: prompt chaining (with a **gate**), **routing** ("the cost
lever", small vs big model), parallelization (sectioning, voting),
orchestrator-workers, evaluator-optimizer ("the loop"). The plan glossary
should reuse these names: a wave is parallelization plus a gate, tier choice
is routing, a loop node is evaluator-optimizer, the orchestrator session is
orchestrator-workers.

## What is genuinely missing

1. **A named reconcile step on disk.** research-wave does it in prose;
   Workflow does it in code; nothing records "this is where the wave joins".
2. **A check-based loop with a cap, outside code.** `loop` exits by
   judgement, `session-loop.sh` by count or stall, rlm by depth. None runs a
   command and stops on pass.
3. **Tier as a plan property.** rlm and fleet.sh carry a model per run; no
   file says which tier a unit of work *should* get, or maps abstract tiers
   to per-runtime models.
4. **A machine-readable "where are we".** Frontier, status, and remaining are
   computed by an agent reading prose every session; wayfinder's frontier is
   the only scripted-in-spirit query, and it is described, not implemented.
