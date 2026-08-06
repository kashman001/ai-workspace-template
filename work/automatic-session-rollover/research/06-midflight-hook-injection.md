# Ticket 06 — mid-flight hook injection into running claude children: experiment log

Session 24, 2026-08-06. Method: use the workspace's *production* wiring (the
committed `PostToolUse` → `context-budget-claude-hook.sh` hook, live in this
session via the main checkout's `.claude/settings.json`) rather than a
synthetic settings file — the classifier blocks nested `claude -p --settings`
runs, and the production path is the one the accelerator tier would use anyway.

## Phase A — do child tool calls fire the parent's PostToolUse hook, and keyed how?

Setup: armed a Monitor (poll script, no hook fires of its own) on
`.context-budget/hook-*` stamp/status files; spawned a probe subagent
(general-purpose) doing 8 × `python3 time.sleep(10)` Bash calls, one per tool
call; parent made zero tool calls during the window. The ticket-07 research
subagent was also live in the same session.

Observed:

- 15:02:47 — `hook-claude-<parent-session-id>` stamp+status touched;
  attributable to the parent's own agent-spawn tool call (baseline).
- 15:03:51 — same files touched again **while the parent was fully idle**
  (>60s throttle gap, no parent tool calls). Only running actors: the two
  subagents. No new `hook-claude-*` file for any child session id appeared.

Findings (phase A):

1. **Subagent tool calls DO fire the session's PostToolUse hooks.**
2. **Hook stdin `session_id` is the parent's** — children share the parent's
   throttle stamp and escalation-state files. Per-child keying by
   `session_id` alone is impossible; a per-child accelerator needs another
   discriminator from hook stdin (e.g. `agent_id`/transcript path — phase B).
3. Corollary for the current wiring: the 60s throttle and escalation-only
   state are *shared* across parent + all concurrent children — whichever
   context fires first after an escalation consumes the single WARN emission.

Probe child completed 8/8 (~150s, 15:02–15:05); stamp touched at 15:03:51,
15:04:51, 15:06:00 during the run (60s throttle pacing). Its final summary:
no "CONTEXT BUDGET" text (correct — status stayed OK), but it *did* observe
harness-level mid-run injections after tool results (token-budget lines,
agent-roster/MCP updates) — so the append-into-a-running-child channel
exists at the harness level; phase B tests whether hook exit-2 stderr rides
it.

Additional phase-A facts:

4. Child-call hook fires are logged in **neither** transcript: the parent
   JSONL's `hook_success` records (`PostToolUse:Bash` / `PostToolUse:Agent`)
   match only the parent's own tool calls; the child task JSONL has none.
   Stamp mtimes are the only trace — hook execution for child calls is
   harness-side and unlogged.
5. Gotcha (registry): `EnterWorktree` mid-session RELOCATES the main
   transcript to the worktree's project slug
   (`…-claude-worktrees-<name>/<session>.jsonl`); the `.context-budget`
   session record registered pre-worktree still points at the old artifact
   path. Hook-side `check` is immune (uses stdin `transcript_path`), but
   registry-artifact-based liveness/token checks go stale on worktree entry.

## Phase B — does hook stderr/exit-2 output land in the child's conversation mid-flight?

Design pivot: no threshold flip needed. At 15:08 the parent session measured
117.5K tokens — 2.5K under the real 120K WARN. Phase B runs as a *natural*
experiment with production settings:

- The parent transcript crosses 120K within a few exchanges.
- Phase-A corollary ("throttle shield"): the shared 60s stamp + gen-2's
  high tool cadence means gen-2 consumes nearly every check slot; the
  parent's own occasional calls land inside the throttle window and perform
  no check. The crossing check will therefore almost certainly execute on a
  **gen-2 tool call** — the exact mid-flight-delivery condition under test.
- Watcher (persistent monitor) emits status-file changes plus both
  transcript sizes at the moment of change.

Outcome decision table (parent idle after crossing):

- Status→WARN while parent idle **and** gen-2 reacts (yields
  ROLLOVER_NEEDED citing the WARN / text in its task JSONL) → mid-flight
  injection into a running child WORKS via PostToolUse exit-2 stderr;
  if the WARN's token figure ≈ parent transcript, child fires measure the
  PARENT transcript (accelerator = parent-budget push, not per-child).
- Status→WARN while parent idle, gen-2 unaffected → hook runs on child
  calls but stderr is NOT delivered into the child conversation →
  accelerator tier refuted for this channel.
- Status never flips while parent idle; parent's own eventual fire gets
  the WARN → child fires measure the child's own transcript (per-child
  semantics); child-delivery question then needs the forced-threshold
  variant after gen-2 yields.

### Phase B outcome (15:10–15:18)

- 15:10:35 — status file flipped OK→WARN (parent transcript ~120K crossed;
  gen-2 live and firing checks at 60s cadence; parent's only near-window
  call was one Edit whose result carried no hook feedback).
- The emitted WARN text (`CONTEXT BUDGET WARN: this session is at N tokens…`
  with numbers substituted) appears in **no transcript**: not the parent's
  main JSONL, not gen-2's task JSONL, not any of the five task/sub-subagent
  transcripts (`grep -l` across the tasks dir: zero hits).
- Subsequent checks (15:13:47, 15:14:59, 15:16:20 — parent idle, gen-2
  active) rewrote status WARN→WARN, which escalation-only never re-emits.
- Gen-2 ran to natural completion at ~15:16:30 (DONE_WITH_CONCERNS),
  unaware of any budget signal.

**Verdict: REFUTED for the hook channel.** PostToolUse hooks DO run on a
child's tool calls (phase A), but their exit-2 stderr is dropped by the
harness for those fires — it reaches neither the child's nor the parent's
conversation. Mid-flight WARN push into a running claude child is NOT
buildable on PreToolUse/PostToolUse output; the dispatch-time contract
remains the only *hook-automatic* parent→child channel (R2/ADR-0005
layering confirmed empirically).

Two load-bearing corollaries:

1. **Swallowed-WARN bug (template defect):** shared session_id keying means
   a busy child consumes the one-shot escalation on a fire whose output is
   dropped — the parent then NEVER receives the in-band WARN (WARN→WARN
   never re-emits). Sessions running long children lose their WARN push
   with high probability (the child wins the throttle race ~always at high
   tool cadence). Mitigation candidates: skip state-write/emit on child
   fires if hook stdin distinguishes them; or make `record`-driven
   measurement the only WARN source when dispatch records show open
   children. → backlog.
2. **Surviving mid-flight channels:** the harness itself DOES append into
   running children after tool results (token-budget lines, agent-roster
   updates observed by the phase-A probe), and the parent can message a
   running background child via SendMessage — a *model-mediated* push (the
   contract's "if asked to checkpoint" clause is exactly this). So the
   accelerator tier is refuted as *hook wiring* but exists as a *parent
   behavior*: at parent WARN, SendMessage each open child a checkpoint
   order per its contract.

### Addendum (15:2x, during rollover)

The WARN→STOP escalation (157K) fired on a PARENT Bash call and WAS
delivered into the parent conversation as PostToolUse blocking-error
feedback. Parent-fire delivery works; only child-fire output is dropped —
confirming the 15:10:35 WARN was consumed on a child fire. The swallowed-WARN
defect is therefore precisely: escalations consumed by child fires are lost;
escalations consumed by parent fires deliver normally.
