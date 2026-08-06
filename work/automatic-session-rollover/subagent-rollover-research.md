# Research: parent-managed rollover of subagent sessions

**Date:** 2026-08-06 · **Status:** research/design note (no implementation)
**Question:** the automatic-session-rollover plan gave the *main* session a
measured, deliberate rollover path (budget hooks → WARN/STOP → pruned handoff →
successor launch). Can those learnings extend to **subagent (child) sessions,
where the parent session — not a human — is the manager?** What extra
requirements, files, and locking changes does that need? How does it behave at
depth (2nd-level children), and what resilience is required?

**Companion files (full evidence, kept verbatim):**
- `subagent-rollover-stats.md` — local transcript measurements, method + caveats.
- `subagent-vendor-survey.md` — 4-runtime capability survey with citations.

---

## TL;DR

1. **The problem is real, today.** Of 30 subagent transcripts in this project's
   history, 3 (10%) crossed the 120K WARN line; the largest peaked at **141,800
   tokens — within 6% of STOP** — and got there *because* it was resumed for a
   fix round. None crossed 150K yet, but only because tasks happened to be sized
   right.
2. **The core learnings transfer.** Measure-don't-guess, escalation-only/
   throttled/fail-open signaling, launcher/ledger file split, artifact-mtime
   liveness — all apply to children. Child transcripts are separate on-disk
   files in Claude Code (`<project-dir>/<parent-uuid>/subagents/agent-*.jsonl`),
   so the existing measurement CLI points at them with no new math.
3. **The rollover verb changes.** For a child near the limit, *resume* is the
   wrong verb — a resumed subagent "retains its full conversation history", so
   resuming makes context **worse**. Child rollover = **successor dispatch**: a
   fresh child + a pruned disk handoff. The SDD skill's fix-loop escalation
   (round ≥4: fresh implementer + report file) is already exactly this move.
4. **The human's role maps onto the parent, with one policy change:** children
   never ask the human. Main-session policy is "WARN asks, STOP goes"; child
   policy is "WARN → parent decides, STOP → parent rolls the child over".
   Escalation to a human happens only at the top level.
5. **The user-proposed invariant holds, refined:** a parent must not roll over
   while it has live children — because successor parents cannot adopt a
   predecessor's children (resume is keyed to the *parent session id*). The
   enforceable form is **drain mode**: at parent-WARN with children in flight,
   stop dispatching, drain, then roll. This needs *child-aware headroom* (see
   §7) to avoid draining past the parent's own hard limit.
6. **Vendor-agnostic is feasible but asymmetric.** Every surveyed runtime has
   *some* subagent notion, but only Claude Code (and plausibly Copilot) exposes
   child identity + transcript artifacts. The portable core is the *contract
   and file protocol*; where a runtime exposes no child handles, the design
   degrades gracefully to dispatch-contract discipline (§11).

---

## 1. Empirical evidence: do children actually approach 150K?

From `subagent-rollover-stats.md` (peak context = max over each transcript of
`input + cache_read + cache_creation` tokens; n=30 subagent transcripts across
this project's sessions):

| Metric | Value |
|---|---|
| Subagent transcripts measured | 30 |
| Max peak context | **141,800** |
| Median peak context | ~66,900 |
| ≥ 120K (WARN) | **3** |
| ≥ 150K (STOP) | 0 |

Top peaks: Task 9 implementer (141.8K), final whole-branch reviewer (133.6K),
Task 8 implementer (133.6K), Task 5 implementer (105.6K), vendor-hooks
researcher (96.1K).

Two design-relevant readings:

- **The heavy children are the ones we care most about being smart** —
  implementers late in their task and whole-branch reviewers are deep in the
  "dumb zone" risk band exactly when their judgment matters most. The main
  rationale for main-session rollover (quality degrades past ~150K regardless
  of advertised window) applies with equal force.
- **Resumption is a context accretor.** The 141.8K peak was an implementer
  *resumed* for a review fix round (SDD rounds 1–3 resume the same agent).
  Every resume stacks a full round of history onto an already-large context.
  This is direct evidence for §4's claim that resume ≠ rollover.

Claude Code's SDK auto-compacts a subagent that approaches its window
([agent-loop.md](https://code.claude.com/docs/en/agent-sdk/agent-loop.md#automatic-compaction)),
so children don't hard-fail — but that is precisely the outcome the whole
rollover project exists to pre-empt: automatic compaction decides what
survives, instead of a deliberate, pruned handoff (ADR-0003 rationale).

## 2. What transfers from main-session rollover, unchanged

| Learning (main session) | Transfers? | Notes |
|---|---|---|
| Measure, don't guess (D1: model can't introspect usage) | ✅ verbatim | Children equally cannot self-report; parent-side measurement of the child's artifact file replaces the human-side status line. |
| Token math on the transcript artifact | ✅ verbatim | Child artifacts are ordinary jsonl with usage envelopes; `context-budget.sh check --transcript <path>` already computes this. |
| Thresholds in one place (`context-budget.env`) | ✅ | Same 120K/150K to start; a per-role override (reviewers vs implementers) is possible later but YAGNI now. |
| Escalation-only, throttled, fail-open signaling | ✅ | Any child-watching mechanism must obey the same three rules or it will spam/block the parent. |
| Launcher/ledger file split (forward `next-session.md` vs append-only `handoff.md`) | ✅ shape, ⬇ scope | At *task* scope, not project scope: the SDD brief/report pair is the existing instance (§5). |
| Artifact-mtime liveness (`LOCK_STALE`) | ✅ | Child liveness = age of the child's transcript file; same check, different path. |
| Deliberate handoff beats auto-compaction | ✅ | Claude subagents auto-compact; that's the fallback we're pre-empting, not the mechanism to rely on. |
| Relaunch knobs / `.rollover-options` | ⚠ transformed | Children have no CLI launch flags; the analog is the parent's **dispatch record** (§5). |

## 3. What changes when the parent is the manager

The main-session design has a human at the top of every decision. Mapping each
human touchpoint to the parent:

| Main-session mechanism | Child-session analog |
|---|---|
| Hook pushes WARN/STOP into the session for the *human+agent* to act on | Parent-side check pushes child status into the *parent's* context (it is the parent's decision loop that must see it) |
| WARN asks the user; declined = write-ahead | WARN → parent decides: instruct child to checkpoint now, or let it finish if near-done. No human involved. |
| STOP → roll over immediately, no ask | STOP → parent stops waiting for a clean finish: instruct child to flush + return, then successor-dispatch |
| User pastes the bootstrap prompt / `launch-next-session.sh` relaunches | Parent composes the successor child's dispatch prompt from the child's disk handoff |
| `attach-session.sh` re-attaches a human terminal | No analog needed — the parent "attaches" by resuming the agent id (continuation, not rollover) |
| Human notices a dead session and relaunches | Orphan sweep via lock hierarchy (§6) + parent re-dispatch from dispatch records |

**The signal path is the hard part.** For main sessions, all five runtimes have
an in-band hook that injects into the running loop. For a *running child*:

- Claude Code fires `SubagentStart`/`SubagentStop` (with `agent_id`,
  `agent_type`) and `PreToolUse`/`PostToolUse` *inside* the child with
  `agent_id` populated ([hooks.md](https://code.claude.com/docs/en/hooks.md)).
  Documented context injection lands "at the start of the subagent's
  conversation" — reliable at dispatch, **not** verified as a mid-flight push.
- No surveyed runtime documents per-child usage reporting to the parent, and
  none has a confirmed child-scoped lifecycle hook besides Claude's
  (`subagent-vendor-survey.md`, caveats 4–5).

**Consequence — requirement R2 (§10):** the reliable, portable signal is the
**dispatch-time rollover contract**, written into every long-running child's
prompt: the report-file path, the instruction to checkpoint durable state to it
at each work-unit boundary, and a defined `ROLLOVER_NEEDED` status the child
returns when *told* (by an injected hook line, where the runtime supports it)
or *asked* (parent resume with "checkpoint and return now"). Mid-flight hook
injection, where it works, is an accelerator — never the load-bearing path.
This mirrors the main-session design's layering: hooks are the push channel,
but the disk protocol is what correctness rests on.

## 4. The rollover verb: successor dispatch, not resume

Claude Code supports resuming a subagent by `agentId`, and "a resumed subagent
retains its full conversation history"
([subagents.md](https://code.claude.com/docs/en/agent-sdk/subagents.md#resume-subagents)).
That makes resume the analog of `attach-session.sh` — a *continuation* verb,
useful for fix rounds and follow-ups on a child that has headroom. It is not a
rollover verb: it carries the entire context forward, including everything a
deliberate handoff would prune.

**Child rollover is therefore always a successor dispatch:**

1. Predecessor child flushes state to its report/ledger file (ideally on
   instruction at WARN; at worst, whatever its last checkpoint captured).
2. Parent composes a fresh dispatch: the same brief (launcher) + a "read the
   report file first — a prior agent attempted this; you own it now" preamble +
   the open items.
3. Fresh child starts at zero context, demand-loads from disk.

This is *exactly* SDD's round-4 escalation ("fresh implementer, more capable
model, read the report file for what was tried") — which means the
superpowers SDD skill has been field-testing child rollover all along, minus
the measurement trigger. The missing piece is not the protocol but the
**trigger**: today a child is only "rolled over" when a review loop stalls;
with measurement, the parent would also roll it over when its transcript
crosses WARN/STOP mid-task.

## 5. Files: what a child rollover needs on disk

Main-session rollover writes project-scoped files (`handoff.md`,
`next-session.md`, `.rollover-options`). Children need the same *shape* at
task scope — and SDD already defines most of it:

| Role | Main session (project scope) | Child (task scope) |
|---|---|---|
| Forward launcher (REPLACED) | `work/<proj>/next-session.md` | Task **brief** — already exists in SDD (`task-N-brief.md`); requirements + pointers, never history |
| Backward ledger (append-only) | `work/<proj>/handoff.md` | Task **report/log** — already exists (`task-N-report.md`, fix reports appended) |
| Progress map surviving controller amnesia | (the ledger) | SDD `progress.md` at plan scope — records which children completed |
| Launch reproduction | `.rollover-options` | **Dispatch record** — NEW: the parent persists each child's dispatch spec (agent type, model, effort, brief path, report path, status, and for Claude the `agent_id`) |
| Registry entry | `.context-budget/sessions/<id>.json` | **Agent record** — NEW: same registry, extended schema: `{runtime, session_id, agent_id, parent_session_id, depth, project, artifact}` |

The **dispatch record** is the genuinely new file, and it earns its place
twice over:

- It lets the parent re-dispatch a crashed/rolled child faithfully (the child
  analog of option inheritance, which the main-session work just shipped for
  the same reason).
- It is what makes **parent rollover safe in the presence of children**: a
  successor parent cannot adopt predecessor children (resume is keyed to
  `resume: <parent sessionId>` — a fresh parent session has a different id),
  but it *can* reconstruct the orchestration from dispatch records + report
  files and re-dispatch unfinished subtrees fresh. Without dispatch records,
  a parent rollover silently loses the fleet.

Suggested placement, following existing conventions: dispatch records live
with the plan/task state that owns them (SDD workspace for SDD-driven work;
`work/<proj>/agents/` for ad-hoc orchestration), not in `.context-budget/`
(which stays a *registry*, not a store of prompts).

## 6. Locking: from a flat lock to a hierarchy

Today: one `work/<proj>/.active-session` lock, one holder, liveness by
artifact mtime vs `LOCK_STALE`, released at rollover, `attach-session.sh` and
`launch-next-session.sh` both key off it.

Children break the flat model: they do project work *under* the parent's
authority and must not compete for the project lock. Minimal extension:

- **Parent keeps the project lock.** Children never touch it. (A child that
  needs the project lock is a design smell — it means two agents believe they
  own the project.)
- **Per-child lock records** under the parent's lock: either per-child files
  (`work/<proj>/.agent-locks/<agent_id>.json`) or a `children[]` array in the
  existing lock file. Per-child files are the better fit — append/remove
  without rewriting shared state (same reasoning as session-keyed registry
  files, docs/context-budget.md §"Multi-session model").
- **Each child lock carries a parent pointer** (`parent_session_id`, and at
  depth ≥2 the full chain or the immediate parent's lock id). Child liveness =
  child artifact mtime, same `LOCK_STALE`.
- **Transitive validity rule:** a child lock is valid only while its parent's
  lock is valid. A stale parent invalidates the whole subtree — this is what
  makes orphan *detection* a single tree walk, with no new liveness mechanism.
- **Release-order invariant (enforces the user's rule mechanically):**
  `context-budget.sh release --project <p>` on the parent should refuse (or
  loudly warn) while live child locks reference it — the lock system itself
  then guarantees "no parent rollover with live children", rather than
  trusting skill prose.

## 7. The no-rollover-with-live-children invariant, and drain mode

The user's proposal — *a parent cannot (and should not) be rolled over until
all children are done* — is correct, and the research adds the mechanism and
one refinement.

**Why it's correct (not just prudent):**
- Successor parents cannot adopt predecessor children (§5): rolling over with
  children in flight strands them — their results return to a session that no
  longer processes them (or nothing at all).
- The parent's rollover artifacts cannot be complete while children are
  mutating state: "flush — make disk fully current" (rollover step 3) is
  unsatisfiable with writers still running. The existing skill already hints
  at this ("verify any sub-agent-claimed outputs actually exist on disk");
  children-in-flight make it impossible rather than merely careful.

**The mechanism — drain mode:** when the parent hits WARN with children in
flight:
1. **Stop dispatching new children.** Every new child both spends parent
   tokens on its return and extends the drain window.
2. **Let synchronous/short children complete; nudge long ones** — resume each
   live child with "checkpoint to your report file and return with status +
   open items" (continuation verb used for what it's good at).
3. **When the last child lock clears, roll the parent over** per the normal
   skill; the parent's handoff includes the orchestration state (§5), so the
   successor resumes the fleet by re-dispatch, not adoption.

**The refinement — child-aware headroom:** draining is not free. Each
returning child costs the parent tokens (its report contract), and the parent
must still afford the rollover ceremony afterwards. So the parent's effective
WARN must move *earlier* as a function of children outstanding — the simple,
honest form is a dispatch guard, not a new threshold:

> Don't dispatch a child if `current_tokens + (outstanding_children + 1) ×
> expected_return_cost + rollover_reserve > STOP`.

Return costs are boundable because the dispatch contract caps them (SDD's
"under 15 lines — detail lives in the report file" rule is precisely this cap,
another main-session learning — pointers over content — already doing the
work). A measured starting value can come from the stats file's per-transcript
data before any implementation.

**One escape hatch is still required (resilience, not policy):** a child that
*never* finishes (hung, looping) must not pin the parent past its own hard
limit forever. At parent-STOP with a child that ignores the checkpoint nudge,
the parent kills the child's task, marks its lock abandoned with a ledger
ruling (the report file holds whatever the last checkpoint captured), and
proceeds. Losing one child's uncheckpointed tail beats losing the parent's
entire orchestration to auto-compaction. This is the drain-mode analog of the
STOP-goes rule.

## 8. The checkpoint/yield protocol: parent↔child communication for rollover

The requirements above imply a small protocol. Its governing constraint is
asymmetric reachability: a parent can always *start* a child and always
*receives its return*, but cannot reliably message a running child (mid-flight
hook injection is unverified, resume only works between stops); a child can
always *write disk* but never *interrupt* the parent. So the protocol follows
the workspace's standing rule:

> **Disk is the authoritative channel; every in-band message is advisory and
> has a disk counterpart.** The protocol must survive the loss of any in-band
> leg — a lost nudge or a truncated return degrades to "the parent reads the
> report file", never to lost state.

### Channels

| Channel | Direction | When usable | Standing |
|---|---|---|---|
| Dispatch prompt | P→C | child start | guaranteed, portable |
| Return message | C→P | child end | guaranteed, size-capped by contract |
| Resume message | P→C | after a child stops (claude: by `agent_id`) | runtime-dependent |
| Hook injection | P→C | child start (documented); mid-flight (unverified) | accelerator only, never load-bearing |
| Brief file | P→C | any time (child re-reads on instruction) | authoritative |
| Report file | C→P | any time | authoritative |
| Dispatch record + child lock | parent bookkeeping | any time | authoritative |

### Message vocabulary

Parent → child:

- **`DISPATCH(brief, report, contract, gen)`** — the opening message. The
  *contract* clauses ride inside it: checkpoint at every work-unit boundary,
  return cap (≤15 lines, detail to the report file), the status vocabulary
  below, and "if asked to checkpoint, flush and yield — don't push on".
- **`CHECKPOINT_REQUEST`** — the nudge (sent as a resume message): "flush
  state to your report file now, then return status + open items." Must be
  idempotent: a child that already finished just repeats its final status.
  This is the *only* new runtime demand the protocol makes, and where resume
  doesn't exist the parent skips straight to the kill row of §12's matrix.
- **`FINDINGS(list)`** — existing SDD continuation (fix rounds). Not a
  rollover message, but it participates in the budget: every resume stacks
  history (§1), so the parent charges continuations against the child's
  remaining headroom before choosing resume over successor dispatch.

Child → parent:

- **`CHECKPOINT`** — disk-only: append a progress block to the report file.
  Deliberately doubles as the **heartbeat**: report-file mtime is the child's
  liveness signal (no separate keepalive mechanism, same artifact-mtime
  principle as everywhere else in the system).
- **`YIELD(status)`** — the capped return message. Status extends SDD's
  existing contract by exactly one value:
  `DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT | ROLLOVER_NEEDED`.
  `ROLLOVER_NEEDED` means: "context spent, task incomplete, report current as
  of my last checkpoint; open items are listed there." A child never emits it
  from self-assessment (D1: it cannot measure itself) — only in response to a
  `CHECKPOINT_REQUEST`, or to a WARN line its own runtime hook pushed into it
  (claude accelerator). Existing SDD flows are thus already
  protocol-conformant; `ROLLOVER_NEEDED` is the only addition.

Parent actions without a message to the child: **probe** (measure the child's
transcript artifact — R1; throttled, escalation-only, at the parent's own turn
boundaries) and **kill** (no cooperative leg exists or the child ignored the
nudge: stop the task, mark the child lock abandoned with a ledger ruling,
successor-dispatch from the last checkpoint).

### Sequences

```
Happy path:      P: DISPATCH(gen 1) → C: CHECKPOINT* → C: YIELD(DONE) → P: release child lock
Measured roll:   P: probe ⇒ WARN → P: CHECKPOINT_REQUEST → C: flush, YIELD(ROLLOVER_NEEDED)
                 → P: DISPATCH(gen 2: brief + "read report first" + open items) → … → YIELD(DONE)
Hung child:      P: probe ⇒ STOP / heartbeat stale → P: CHECKPOINT_REQUEST (no yield)
                 → P: kill + ledger ruling → P: DISPATCH(gen 2 from last checkpoint)
Parent drain:    P at WARN: no new DISPATCHes → CHECKPOINT_REQUEST broadcast to live children
                 → collect YIELDs → last child lock clears → parent's own rollover (§7)
```

### Generation fencing

The dispatch record carries a **generation counter**; gen N+1 is dispatched
only after gen N's lock is cleared (clean yield or kill), and each report
append is labeled with its generation. This guarantees at most one live writer
per report file and keeps the ledger readable as history ("gen 1 attempted X,
gen 2 finished it") — the child-scope analog of the handoff ledger's
newest-block-on-top append discipline, and the fencing that makes R3's
successor dispatch safe to automate.

The protocol packages the delta requirements: probe = R1, contract = R2,
successor dispatch = R3, records/fencing = R4, drain broadcast = R6.

## 9. The rollover inventory: what a parenting session must account for

A session with no children rolls over by flushing *its own* state. A parenting
session holds much more than its context, and each item below is something a
rollover (its own, or a child's) must reckon with. The completeness test:

> Every inventory item is either **drained** to completion, **persisted** in
> its authoritative disk home, or **explicitly ruled lost** in the ledger.
> The handoff is complete exactly when nothing on the board is implicit.

| # | Element | Why it matters at rollover | Authoritative home | If unaccounted |
|---|---|---|---|---|
| 1 | **Outstanding (live) children** | The drain set (§7); successors can't adopt them | Child locks + registry agent records | Stranded children; results returned to a dead session |
| 2 | **Dispatch queue + dependency edges** | Tasks planned but not yet dispatched, and which of them wait on in-flight results | Plan file / SDD `progress.md` (order + deps explicit) | Successor re-derives the plan wrong or re-runs finished work |
| 3 | **Arrived-but-unprocessed returns** | A `YIELD` the parent received in-context but hasn't acted on is conversation-only state | Child report files (returns are pointers by contract) | The one rollover-fatal case is a return that *only* lived in the return message — the size cap exists to prevent exactly this |
| 4 | **Open review/fix loops** | Round count, open findings, which agent owns the loop | Ledger fix-round lines + report files | Successor restarts review from zero or, worse, merges unreviewed work |
| 5 | **Resumable agent handles** (`agent_id`s) | Expiring assets — keyed to the parent's session id, worthless to a successor | Dispatch records (recorded, but marked non-portable) | Successor wastes turns attempting resumes that can't work |
| 6 | **The lock set** | Project lock + child locks + generations; release order is the invariant's enforcement | `work/<proj>/.active-session` + child lock files | Orphan subtrees undetectable; two sessions believe they own the project |
| 7 | **Dispatch records + generation counters** | The fleet's reconstruction map (§5) and write-fencing state (§8) | With the owning plan/task state | Fleet silently lost; or two generations write one report |
| 8 | **Shared workspace mutations** | Uncommitted files, per-child worktrees, branch state — children may hold half-written trees | `git status` per touched repo, worktree list in the state snapshot | Successor commits over (or nukes) a child's half-finished tree |
| 9 | **Background processes & monitors** | Watchers, servers, workflow runs the parent started for its children | State snapshot in `next-session.md` (existing convention) | Zombie processes; successor double-starts them |
| 10 | **Session-scoped scratch artifacts** | Scratchpad dirs die with the session — anything a child wrote there is on a timer | Promote to `work/<proj>/` before rollover (this research hit exactly this: agents' findings files copied out of scratchpad) | Research/intermediate outputs silently evaporate |
| 11 | **Per-child equipment config** | Model, effort, agent type, tool restrictions, MCP fragments each child needs | Dispatch records; parent's own launch flags in `.rollover-options` | Successor re-dispatches children under-equipped or over-privileged |
| 12 | **Promises made to children** | Contract clauses like "you will be resumed with findings" — a successor cannot honor them by resume | Dispatch records note the obligation; successor honors it by fresh dispatch + report pointer | A child's parked expectations rot; loops never close |
| 13 | **Human-pending items** | A `BLOCKED` child waiting on a user decision must survive as a question, not a stalled process | Handoff ledger + `next-session.md` open items | The question dies with the parent; work stays blocked invisibly |
| 14 | **Budget/registry state** | The parent's own record trail and each child's artifact path (the successor's probe targets) | `.context-budget/` registry + ledger | Successor can't measure inherited children it re-dispatches |

Rows 1–7 are new with parenting; rows 8–14 exist for plain sessions too but
gain a multiplier — *N children each carry their own slice of them*. The
main-session skill's flush step ("verify sub-agent-claimed outputs actually
exist on disk") was this inventory's row 3 in embryo; a parenting-aware
rollover skill walks all fourteen.

## 10. Extra requirements beyond main-session rollover (the delta)

R1. **Parent-side measurement of child artifacts.** No runtime reports
    per-child usage to the parent; the parent (or its hook, on the parent's
    turn boundaries) must measure child transcript files directly.
    Claude-shaped: `context-budget.sh check --transcript
    <project-dir>/<parent-uuid>/subagents/agent-<hash>.jsonl`, discovered via
    the `.meta.json` siblings. Escalation-only + throttled, or a busy parent
    gets spammed by N children's WARN lines.
R2. **Dispatch-time rollover contract** in every long-running child prompt:
    report-file path, checkpoint-at-boundaries discipline, capped return size,
    defined `ROLLOVER_NEEDED` status. The disk protocol is load-bearing;
    hook injection is an accelerator where the runtime supports it.
R3. **Successor dispatch as the only rollover verb** (resume = continuation
    only, and resumes count *against* headroom — the 141.8K child was a
    resumed one).
R4. **Dispatch records** persisted by the parent per child (spec + status +
    agent id), enabling faithful re-dispatch and making parent rollover
    fleet-safe.
R5. **Lock hierarchy:** per-child locks with parent pointers, transitive
    validity, release-order enforcement (parent release refuses with live
    children).
R6. **Drain mode + child-aware headroom** (§7), with the kill-and-ledger
    escape hatch for hung children.
R7. **Policy relabeling:** "WARN asks, STOP goes" becomes, at child level,
    "WARN → parent decides, STOP → parent rolls the child". Humans are only
    ever consulted at L0. (ADR-0003's trigger-policy table gains one row; the
    hybrid principle — ask only where a decision-maker exists in-loop — is
    unchanged, which is why this is a mapping, not a redesign.)
R8. **Recursive application with subsidiarity** (§12): each level manages only
    its direct children; requirements R1–R7 apply at every parenting level.

## 11. Vendor-agnostic layering

Same split as ADR-0003/0004: the *contract* is runtime-neutral; runtime
specifics live in `scripts/` adapters + vendor config. From
`subagent-vendor-survey.md` (versions: codex 0.142.4, gemini 0.46.0, opencode
1.18.14, copilot 1.0.78):

| Capability | claude | codex | gemini | opencode | copilot |
|---|---|---|---|---|---|
| Subagent concept | ✅ Task/Agent tool | docs-only | docs-only (v0.38.1+) | ✅ `task` tool | ✅ `/fleet`, `--agent` |
| Child identity visible | ✅ `agent_id` + transcript files | ✗ none found | ✗ none found | partial (session nav) | ✅ task IDs in `--session-id` |
| Child transcript on disk | ✅ `subagents/agent-*.jsonl` | ✗ | ✗ | undetermined | undetermined |
| Child resumable | ✅ by agent id | ✗ | ✗ | undetermined | inferred (task-ID reuse) |
| Per-child usage | ✗ (measure files) | ✗ | ✗ | ✗ (session-level) | ✗ (session-level) |
| Nesting | ✅ 3 levels default (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`) | conflicting docs | undetermined | **forbidden** (documented) | undetermined |
| Child lifecycle hooks | ✅ SubagentStart/Stop | ✗ | ✗ | ✗ (JS plugin, no event found) | suggestive (`agentStop`), unconfirmed |

Layering that survives this asymmetry:

- **Portable core (works everywhere, no child handles needed):** R2's dispatch
  contract, the brief/report file protocol, dispatch records, the drain
  invariant, and *task sizing as prevention* — keep child tasks scoped so the
  expected peak stays under WARN (the median child here is ~67K; the tail is
  what measurement catches). Where a runtime's children are opaque
  (codex/gemini), this discipline **is** the whole mechanism, and it degrades
  exactly to "SDD done carefully".
- **Measured tier (adapter per runtime, only where artifacts exist):** child
  artifact discovery + `check --transcript` + per-child locks. Ship the claude
  adapter first (all handles confirmed); copilot is the next candidate (task
  IDs live-confirmed; artifact location undetermined).
- **Accelerator tier (optional per runtime):** in-flight WARN injection into
  running children via native hooks. Claude-only today, and unverified for
  mid-flight delivery — treat as enhancement, never dependency.

The two survey caveats worth pinning: codex/gemini subagents are *runtime*
features invisible to `--help` (the workspace's verify-against-live-help rule
applies doubly — there may be nothing to verify against); and opencode's
documented nesting prohibition means depth-related requirements (R8) are
claude-specific until proven otherwise elsewhere.

## 12. Depth: second-level children and the resilience model

With Claude's default depth of 3, an L1 child can itself parent L2 children.
The design stays sane only with **subsidiarity**: each session manages its
*direct* children and nothing deeper.

- L0 (human-managed) applies R1–R7 to its L1 children.
- An L1 that parents L2 children applies R1–R7 itself: its own dispatch
  records, its own drain-before-return. "Return" at L1 *is* its rollover
  event: an L1 child must not return (or be rolled over) while its L2 children
  are live — the invariant recurses verbatim.
- The grandparent never reaches around to grandchildren; it sees only its L1
  child's lock, whose validity transitively vouches for (or invalidates) the
  L2 subtree (§6).

**Failure/recovery matrix:**

| Failure | Detection | Recovery |
|---|---|---|
| Child crashes/hangs | Child artifact mtime stales past `LOCK_STALE`; parent sees it at its next boundary check | Parent re-dispatches from dispatch record + report file (fresh successor; whatever the last checkpoint captured survives) |
| Parent crashes with live children | Parent artifact stales → parent lock invalid → subtree transitively orphaned | Children finish or stall harmlessly (their writes are task-scoped files); next session on the project sweeps stale locks, reads parent's dispatch records, re-dispatches unfinished work |
| L1 rolls over correctly | — (drain mode ran; L2 subtree empty by invariant) | Successor L1 rebuilds from records |
| Whole tree torn down (machine dies) | All locks stale on next register | Standard main-session recovery — ledger + report files + git are the record; this is why every level writes to disk, not memory |

The resilience posture is inherited from the main-session design and is worth
stating as the closing principle: **liveness is always inferred from artifact
freshness, never asserted by the agent; recovery is always re-dispatch from
disk, never adoption of a live context.** Both properties were load-bearing in
the main-session system; the child design keeps them absolute, which is what
lets every failure above degrade to "re-read files, dispatch fresh".

## 13. Evaluation model: states, invariants, scenarios, faults, costs

To judge the design functionally, for resilience, and for performance, the
prose above reduces to a checkable model. Everything here is phrased so it can
become a test or a measurement, in the workspace's existing harness style
(mktemp fixtures, `touch -t` mtimes, stub CLIs).

### 13.1 State machines

**Child lifecycle** (states live in the dispatch record; transitions are
protocol events from §8):

```
QUEUED ──DISPATCH(gen N)──▶ RUNNING ──YIELD(DONE|DONE_W_CONCERNS)──▶ COMPLETE
                              │  ▲
                              │  └──FINDINGS (fix round, headroom permitting)
                              ├──CHECKPOINT_REQUEST──▶ WRAPPING ──YIELD(ROLLOVER_NEEDED)──▶ ROLLED ──▶ QUEUED(gen N+1)
                              ├──YIELD(BLOCKED|NEEDS_CONTEXT)──▶ WAITING ──(input/context)──▶ RUNNING
                              └──heartbeat stale ∨ nudge ignored──▶ KILLED(+ledger ruling) ──▶ QUEUED(gen N+1)
```

RUNNING self-loops on `CHECKPOINT` (disk append = heartbeat). Terminal states:
COMPLETE, and KILLED-with-no-successor (only by explicit parent ruling).

**Parent budget modes** (orthogonal to its work):

```
NORMAL ──WARN ∧ children live──▶ DRAINING ──last child lock clears──▶ ROLLING ──handoff done──▶ RELEASED
   │                                │
   └─WARN ∧ no children──▶ ROLLING  └─parent STOP ∧ child unresponsive──▶ KILL child, stay DRAINING
```

In DRAINING: no new `DISPATCH`es, `CHECKPOINT_REQUEST` broadcast, probes
continue. A parent crash in any mode is handled by the fault model (13.4),
not the state machine — crashes don't transition, they stale.

### 13.2 Invariants (each names its enforcement point)

- **I1** At most one valid project-lock holder per work item. *(existing lock
  acquire/steal logic)*
- **I2** Child lock valid ⇒ its parent's lock valid (transitive validity —
  §6). *(lock validation walks the parent pointer)*
- **I3** At most one live generation per task; report appends carry their
  generation. *(fencing rule: gen N+1 dispatched only after gen N's lock
  cleared — §8)*
- **I4** Parent in ROLLING ⇒ zero live child locks (the drain invariant, §7).
  *(release-order guard in `release`; skill step ordering)*
- **I5** Every child terminal state leaves a ledger/report entry — no silent
  discard, including KILLED. *(protocol rule + skill discipline; testable by
  auditing terminal records)*
- **I6** Report files are append-only within and across generations; briefs
  are replaced only between generations. *(write discipline; testable by
  content diffing across a rollover)*
- **I7** Liveness is inferred only from artifact mtime vs `LOCK_STALE`, never
  from any agent's assertion. *(all checks route through the one age
  function)*
- **I8** Anything `CHECKPOINT`ed survives any single failure thereafter.
  *(follows from I5–I7 + disk-authoritative channels; the property
  fault-injection must confirm)*

### 13.3 Functional evaluation — scenario suite

Each scenario is an acceptance test; pass criteria in terms of end state +
invariants held throughout.

> S1–S10 below are the seed suite. The full catalog (S11–S52, grouped by
> evaluation dimension, incl. the dimensions added after review) lives in
> `rollover-scenarios.md` — authoritative for everything beyond S1–S10 —
> and is mirrored in the HTML rendition §7.

| ID | Scenario | Pass criteria |
|---|---|---|
| S1 | Happy path: dispatch → checkpoints → DONE | COMPLETE; lock released; report has ≥1 checkpoint + final block |
| S2 | Measured child roll: probe WARN → nudge → ROLLOVER_NEEDED → gen 2 → DONE | Gen 2 resumes from report, no re-done work; I3, I6 hold |
| S3 | Hung child: heartbeat stales, nudge ignored → kill → gen 2 | KILLED has ledger ruling (I5); gen 2 starts from last checkpoint; loss limited to post-checkpoint tail |
| S4 | Parent drain: WARN with 3 live children → broadcast → drain → parent rolls | No new dispatches after WARN; parent ROLLING only at 0 child locks (I4); successor parent re-dispatches queue from records |
| S5 | Parent crash mid-fleet | All child locks invalid via I2 within `LOCK_STALE`; sweeper + dispatch records reconstruct; no adoption attempted |
| S6 | Child crash mid-write | Half-written report tail tolerated (last full checkpoint wins); gen 2 dispatched; I8 holds |
| S7 | BLOCKED child with human-pending question, then parent rolls | Question survives into handoff/`next-session.md` (inventory row 13); successor re-raises it |
| S8 | Two-level: L1 with live L2 children told to drain | L1 refuses to yield until its own drain completes (I4 recursively); grandparent never touches L2 |
| S9 | Dependency queue: task B depends on in-flight A when parent rolls | Successor dispatches B only after A's gen completes; edge came from disk (inventory row 2) |
| S10 | Opaque runtime (no child handles): same plan | Degrades to contract discipline: capped returns + report files still yield S1/S2-equivalent outcomes minus measurement trigger |

### 13.4 Resilience — fault model and required properties

Faults in scope: crash of any node (parent or child, any depth) at any point;
loss/truncation of any in-band message (return, nudge, hook line); stale or
slow children; concurrent unrelated sessions on the same workspace. Out of
scope: disk loss (git + push is the existing answer), clock skew beyond
mtime granularity (same exposure as the shipped lock system).

Required properties, each mapping to fault-injection tests in the existing
harness style:

- **P1 No lost committed state:** any state that reached a `CHECKPOINT`
  survives every in-scope fault (I8). *Inject: `kill -9` child between and
  during report appends.*
- **P2 No orphan writers:** post-fault, at most one generation can append to
  any report (I3). *Inject: crash parent after dispatching gen 2, restart,
  attempt gen 3.*
- **P3 Bounded detection:** any dead node is detectable within `LOCK_STALE`
  by artifact age alone (I7). *Inject: manufacture stale mtimes with
  `touch -t`, assert sweep verdicts.*
- **P4 Idempotent recovery:** re-dispatch from records + reports is safe to
  repeat — a duplicate successor is prevented by fencing, and a successor
  re-reading a complete report re-completes without redoing side effects
  (side effects live in git-visible files, so "redo" is detectable). *Inject:
  run recovery twice.*
- **P5 Graceful message loss:** drop any single in-band message; the system
  reaches the same end state via disk, at worst one probe/nudge cycle later.
  *Inject: stub runtime that swallows returns/nudges.*

### 13.5 Performance — cost model and metrics

The costs that matter are parent-context tokens (the scarce resource this
whole system protects) and wall-clock latency. Parameters marked ★ should be
measured from the existing registry/ledger data (the stats file already
carries per-transcript numbers) before implementation fixes them.

| Cost | Model | Notes / current evidence |
|---|---|---|
| Parent overhead per child | `dispatch_prompt + return_cap + probe_lines` | Dispatch ~1–2K tokens; return capped (SDD's ≤15 lines ≈ ≤500 tokens ★); probes ≈ 0 in steady state (escalation-only) |
| Child rollover cost | child writes handoff (≈1 checkpoint) + successor re-reads brief + report | Successor start-up read is the price of pruning; compare against the alternative — auto-compaction's unbounded quality loss in the dumb zone |
| Resume vs successor | resume: +full history retained; successor: reset to re-read cost | The 141.8K resumed child (§1) is the measured argument ★ |
| Drain latency | `max(remaining runtime of live children)`, bounded by nudge response time | Nudge converts unbounded to ~one child turn; the S3 kill path caps even that at parent-STOP |
| Max safe concurrent children | `N ≤ (STOP − current − rollover_reserve) / return_cap` | The §7 dispatch guard, solved for N; all parameters measurable ★ |
| Probe cost at scale | O(children) file stats per parent boundary, throttled by `CHECK_EVERY` | Filesystem-only; zero tokens unless escalating — same profile as the shipped hooks |

Evaluation questions these let you answer concretely: at what N children does
a parent's orchestration overhead alone push it to WARN? (≈ N × (dispatch +
return) + coordination turns); is a child roll cheaper than one fix-round
resume at a given transcript size? (successor re-read vs history retained —
crossover computable from ★ values); does drain latency fit inside the
parent's WARN→STOP token runway at its observed burn rate ★?

## 14. Suggested next steps (not started)

1. **Registry/lock schema extension** in `context-budget.sh`: agent records
   with `parent_session_id`/`depth`, per-child locks, release-order guard —
   the smallest testable slice (R4/R5).
2. **`check --transcript` sweep helper**: given a parent session, enumerate
   `subagents/*.jsonl` + `.meta.json` and report per-child status (R1),
   escalation-only. Claude adapter only.
3. **SDD dispatch-contract hardening** (R2/R3): fold the rollover contract and
   the "roll instead of resume when the child is fat" rule into the workspace's
   orchestration guidance — cheap, portable, and it addresses the 141.8K
   pattern directly.
4. Wayfinder-style decision tickets for the open questions: mid-flight hook
   injection into running claude children (verify empirically); copilot child
   artifact location; whether per-role thresholds earn their keep.

## Sources

- Local measurements: `subagent-rollover-stats.md` (30 subagent + 20 main
  transcripts under `~/.claude/projects/…ai-workspace-template*/`, method and
  jq commands inline).
- Vendor survey: `subagent-vendor-survey.md` (live `--help` on installed
  CLIs + official docs, cited per claim).
- Claude Code / Agent SDK docs: subagents (storage, resume, nesting depth),
  agent-loop (auto-compaction, budget scope), hooks (SubagentStart/Stop,
  agent_id in tool hooks, additionalContext injection) —
  https://code.claude.com/docs/en/agent-sdk/subagents.md,
  https://code.claude.com/docs/en/agent-sdk/agent-loop.md,
  https://code.claude.com/docs/en/hooks.md.
- This workspace: `docs/context-budget.md`, `docs/adr/0003*`, `docs/adr/0004*`,
  `skills/session-rollover/SKILL.md`, superpowers SDD skill (fix-loop
  escalation = field-tested successor dispatch).
