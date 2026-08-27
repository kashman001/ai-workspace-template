# Session-loop automation — design

**Date:** 2026-08-21 (probes folded in 2026-08-24; reviewed 2026-08-25) ·
**Status:** **design approved.** The full spec was reviewed and cleared on
2026-08-25 — including the three-layer worktree treatment, session numbering,
build order, and failure modes 10–11. All five open questions are answered. Next
step is the implementation plan.
**Origin:** session 57 design conversation (`/clear` vs `/compact` vs `session-rollover`)

## Problem

`ROLLOVER_RELAUNCH=auto` already decides *when* to roll over, but a human still
performs one action per rollover. Root cause, verified this session:

- `scripts/launch-next-session.sh:441-444` execs the successor only when
  `[ -t 0 ] && [ -t 1 ]`. An agent's Bash tool shell is **not** a TTY, so the
  attached path always falls through to `note "not an interactive terminal"`.
- `--bg` sidesteps the TTY check but detaches; the human then runs
  `attach-session.sh`. Either way: one human command per rollover.

The constraint is structural, not a bug: **an agent cannot replace the process
attached to the human's terminal.** Only a process that owns the terminal can.

Goal: keep every agent working inside an optimal context window with no
per-rollover human action, without changing how sessions behave.

## Rejected alternatives

- **`/compact` at 150K.** Loss compounds across cycles (each summary summarizes a
  summary), and it is not reliably schedulable — Claude Code auto-compacts near
  ~200K, which is why `CONTEXT_DUMB_ZONE_TOKENS=150000` sits below it
  (`docs/context-budget.md:147`). Rollover re-anchors to disk every cycle.
- **`/loop` driving rollover.** `/loop` schedules a prompt back into the *same*
  session, so every tick spends tokens in the window it is meant to protect, and
  it can neither `/clear` nor exit a process. Wrong layer: the fix must live
  outside the session.
- **`/clear` + re-read, automated.** Requires tmux (`send-keys`) — not installed,
  VS Code terminal — plus an agent typing into its own terminal. Its advantages
  (no terminal churn) are already provided by the supervisor, and in interactive
  work the scrollback is the *human's* context, so destroying it is a cost, not a
  saving. Dropped entirely; remains available as a manual convenience.
- **Supervisor polls for the sentinel and kills its own child.** A supervisor
  blocked in `wait` needs a background poll loop racing its child; the `Stop`
  hook fires deterministically at a turn boundary with the PID already in
  `$PPID`. Dropped once termination was verified clean.

## Verified facts (this machine)

### Claude Code 2.1.228

- `"Stop" | "SubagentStop"` is a real hook event union in the binary.
- A `Stop` hook fires in both headless and **interactive TUI** sessions;
  payload carries `hook_event_name`, `stop_hook_active`, `session_id`.
- Inside the hook, `$PPID` **is the claude process** — no process-tree walk needed.
- `kill -TERM $PPID` from the hook exits the session in the same second
  (`rc=143`), and Claude Code's SIGTERM handler **restores the terminal**: mouse
  reporting off, charset reset, `modifyOtherKeys`/kitty keyboard popped, focus and
  bracketed paste off, cursor shown, scroll region reset, title cleared. No
  `stty sane` required.
- A supervisor running claude as a foreground child regains the terminal on that
  exit (measured end-to-end: 9s including trust dialog and a model turn).
- Claude Code's **workspace-trust dialog blocks a fresh directory on startup** —
  a relaunch into an untrusted cwd hangs on a prompt nobody is watching.
- `code chat` exists on VS Code 1.134.0 with `-m agent|ask|edit|<custom mode id>`,
  `-r/--reuse-window`, `-n/--new-window`.

### opencode 1.18.15

- A plugin's `event` hook receives `session.idle` **exactly once** per turn,
  after the assistant message completes — the turn boundary.
- `process.kill(process.pid, "SIGTERM")` from that hook exits `opencode run` with
  `rc=143`, synchronously (the log line after the `kill` call never writes).
- Under a pty the plugin runs **inside** the terminal-owning process (`process.stdout.isTTY === true`; its `ppid` is the pty wrapper), so `process.pid` is
  the right target — the analogue of Claude's `$PPID`.
- SIGTERM restores the terminal in 1s: leaves the alternate screen, shows the
  cursor, and turns off mouse reporting, bracketed paste, and theme-change
  notifications. No `stty sane` needed.

## Architecture

Four components, each with one job.

### 1. `scripts/session-loop.sh <project>` — the supervisor

The only new process. Started once by the human; owns the terminal; never talks
to a model.

```
export TF_SESSION_LOOP=1                 # opt-in marker; inherited by the agent and its hooks
ROOT=$(resolve_workspace_root)           # via --git-common-dir; NEVER a bare relative path
cd "$ROOT"                               # the chain runs in the main checkout (layer 2, point 4)
S="$ROOT/work/<proj>"
write $S/.session-loop  (pid)
loop:
  eval "$(cat $S/.next-command)"         # foreground child — inherits the TTY
  wait
  assert seq(after) == seq(before) + 1   # failure mode 10; halt+notify on any other delta
  read $S/.rollover-complete
    absent          -> exit (human quit, or crash)
    unreadable      -> halt LOUDLY (failure mode 4 — never a quiet exit)
    mode=handsoff   -> relaunch immediately
    mode=interactive-> "session #N ended. Press Enter to start #N+1." then relaunch
```

Every path is anchored to `$ROOT`. That is not a style choice — a bare
`work/<proj>/.rollover-complete` is the exact defect described in "Worktrees" →
layer 3, rule 1, and its signature is a false report of clean shutdown.

Full interactivity is preserved: the child inherits stdin/stdout, so the session
behaves exactly as a directly-launched one. This is the same TTY inheritance the
repo already relies on at `launch-next-session.sh:443`.

### 2. `launch-next-session.sh --emit <path>` — one new mode

`exec` cannot be used (it would replace the supervisor); `--dry-run` cannot be
used (it deliberately mutates nothing — no `.session-seq` bump, no
`.rollover-options` adopt, no lock release). `--emit` performs **every** real-run
side effect including `write_pending`, then writes the `%q`-quoted command to a
file instead of exec'ing.

The load-bearing prompt wording, options replay, sequence counter, work-item
lock, and stale-launcher freshness guard all stay where they already live.

### 3. `work/<proj>/.rollover-complete` — the sentinel

Written by rollover step 7, at a path **resolved through the git common dir** —
never a bare relative path (see "Worktrees" → layer 3, rule 1). Not a flag: a
record carrying the identity of the session that wrote it, so absence has exactly
one meaning (layer 3, rule 2):

```json
{"mode":"interactive","seq":58,"reason":"STOP mid-design-discussion",
 "session_id":"eaefac37-…","runtime":"claude","cwd":"/…/.claude/worktrees/session-loop-automation"}
```

Meaning: *this session ended on purpose, with disk current.* A crash leaves no
sentinel, so a crash-loop is impossible by construction. `cwd` records where the
writer actually ran, which is what lets the supervisor distinguish "no session
ended" from "a session ended somewhere I did not look."

### 4. The exit mechanism — a tiered, vendor-neutral contract

The **only** vendor-specific surface in this design. Everything else is already
runtime-agnostic: `launch-next-session.sh:355-366` builds the correct invocation
for all six runtimes, and the supervisor merely evals it.

| Tier | Mechanism | Boundary | Availability |
| --- | --- | --- | --- |
| A | Vendor turn-end hook → `SIGTERM $PPID`, **or** a vendor-native stop where one exists | Turn boundary (clean) | claude `Stop` (verified); copilot CLI `agentStop` (wired); gemini `AfterAgent` + `continue:false`; opencode `session.idle` (verified) |
| B | Agent self-terminates from its shell tool, last action of rollover | Mid-turn; loses the final assistant message | **No current occupants** — every runtime probed reached Tier A. Retained as the fallback for a runtime with no turn-end hook |
| C | No exit; supervisor prints the command | — | Today's behavior, preserved |

Implementation belongs in `scripts/hooks/context-budget-hook-lib.sh`, which
exists precisely to hold logic that must not drift between runtimes, behind thin
per-vendor wrappers.

Turn-end event status per runtime:

| Runtime | Event | Status |
| --- | --- | --- |
| Claude Code | `Stop` | Verified end-to-end |
| Copilot CLI | `agentStop` | Wired already (`context-budget-copilot-hook.sh:26`), guards `stop_hook_active` |
| Copilot VS Code | `Stop` | Wired; not needed (see Editor-hosted agents) |
| Codex | `Stop` (also `SessionEnd`) | Tier A. Hook-event enum in the 0.149.0 binary lists `Stop`; firing test pending |
| Gemini CLI | `AfterAgent` | Tier A. Shipped hooks reference (0.46.0): fires "once per turn after the model generates its final response"; `continue:false` **stops the session** outright. Firing test pending |
| opencode | plugin `event` → `session.idle` | **Verified end-to-end** (1.18.15) — best-evidenced Tier A path after Claude Code |

## Editor-hosted chat agents — no supervisor needed

The supervisor exists because a process owns a terminal. Chat agents in VS Code
have no such process: sessions are UI panes. Killing is neither possible nor
necessary, and a successor already launches headlessly:

`launch-next-session.sh:362-366` runs `code chat -r -m agent "$PROMPT"` for
runtime `copilot-vscode` — "opens a NEW agent session in the last-active VS Code
window and returns immediately" (verified session 28). The dying agent runs this
from its own shell tool, so `ROLLOVER_RELAUNCH=auto` **already achieves zero
human action there.** The dead pane is simply abandoned.

**Probed (VS Code 1.134.0): neither extension inherits this path.** `code chat -m`
takes `ask`/`edit`/`agent` or a custom **mode** — a `chatModes` contribution.
`anthropic.claude-code` 2.1.241 makes no chat contribution at all (it renders its
own view container), so it is definitively not addressable this way. `openai.chatgpt`
26.818.61809 contributes a `chatSessions` type (`openai-codex`) but no `chatModes`,
so `-m openai-codex` is unlikely to resolve — not tested live, because doing so
starts a real agent in the user's editor and needs a go-ahead.

Both therefore fall back to the emit-the-prompt path.

### `code agent` — a vendor supervisor for the editor-hosted case

VS Code ships `code agent`, a session-lifecycle API over an agent-host socket:
`host`, `ps` (enumerate sessions, `--json`), `stop` (**cancel a session's active
turn**), `kill`, `logs` (stream live session events), `endpoints`. Live editor
windows publish themselves to it — `code agent ps --json` discovered a running
editor advertising a socket under `$TMPDIR/vscode-ah-*/`.

That is turn-boundary control, session enumeration, and a progress feed — the
same three things the supervisor and stall detection (failure mode 2) need, supplied
by the vendor for panes that have no process to own a terminal.

**It is unusable on this machine today.** The bundled CLI speaks agent-host
protocol 0.7.0; the running editor requires `^0.8.0`, so `initialize` fails with
`rpc error -32005`. Anything leaning on `code agent` needs a version handshake and
a fallback to emit-the-prompt. Treated as a **future option, not a dependency.**

## Modes — interactive vs hands-off

Mode is a property of the **moment**, not of the launch: a day shifts between
designing and executing. So it is not a supervisor flag.

**Source (decided):** the dying agent infers mode — mid-conversation with a human
vs mid-execution of a plan — and writes it into the sentinel. Human override via
`touch work/<proj>/.hands-off` / `.interactive`.

| | Interactive | Hands-off |
| --- | --- | --- |
| Relaunch | Wait for **Enter** | Immediate |
| Successor's first act | Re-pose the open question, then wait | Resume executing |
| Mission anchor | May be re-narrated | **Must** point at a fixed artifact |
| Guards needed | None — the human is the stall detector | Chain cap, stall detection, notification |

A keypress, not a countdown: if the human is typing when a countdown fires, the
unsubmitted text dies. Waiting also lets them scroll back and copy from the dead
session first.

The rollover skill's existing clause — mid-discussion, carry "the live question
verbatim into the launcher's START HERE so the successor re-poses it" — stops
being a nicety under automation and becomes what makes interactive rollover
survivable.

**Mission anchoring (hands-off).** Each successor reads a `next-session.md`
written by a model. Over a 10-session unattended chain a re-narrated mission is a
telephone game; disk anchors facts but not intent. Hands-off launchers must
therefore carry only *position* ("ticket 4 of 9, 3 done") against a fixed spec,
plan, or ticket — never a re-told goal.

## Worktrees — the three layers

The supervisor cannot treat worktrees as a compatibility note, because worktrees
are not optional here: **the harness forces background jobs to isolate before
editing**, so any rolling chain containing a bg session contains a worktree
session whether the design plans for one or not.

Three layers stack, and each must hold before the next is coherent:

1. **The workspace** — what a worktree does to coordination state at all.
   *Settled by ADR-0006*, with one residue named below.
2. **Rollover** — what a worktree does to a human-driven handoff. *Already
   mechanized*; this section states the inherited contract.
3. **Automated rollover** — what removing the human changes about layers 1–2.
   The new work.

### Layer 1 — worktrees in this workspace

ADR-0006 made the governing choice: **coordination state is keyed to repository
identity, never to a checkout.** Five scripts resolve `WORKSPACE_ROOT` through
`git rev-parse --git-common-dir`, so every worktree of this repo converges on one
`.context-budget/`, one lock per work item, one ledger.

That leaves exactly **two sanctioned transports** between a worktree session and
the rest of the workspace:

| Transport | Carries | Mechanism |
| --- | --- | --- |
| **git** | tracked artifacts — `handoff.md`, `next-session.md`, `decisions.md`, this spec | commit → push → main ff-pulls |
| **common dir** | untracked coordination state — `.context-budget/`, `.active-session` | `--git-common-dir`, resolved inside the script |

**Anything that is neither is a defect.** That is the one-line test every new file
in this design must pass.

**The residue — files the *agent* writes, not a script.** Every script here
resolves the common dir; the agent is the only actor that does not. Two files are
written by agent hand at a bare relative path, and both strand:

- `.session-seq` — `session-rollover` step 6 says `echo <N> > work/<project>/.session-seq`.
- `.rollover-options` — step 1 permits hand-edits for `ROLLOVER_OPT_MODEL` / `ROLLOVER_OPT_EXTRA`.

`launch-next-session.sh` compensates at *read* time, reconciling across
`git worktree list`: numeric max wins for the counter (`:187`), newest mtime for
the options (`:250`). This works, and it is a workaround rather than a fix — it
tolerates stranded copies but **never prunes them**, and, as "Session number
progression" shows, the max-wins rule it depends on is itself why one class of
error became permanent.

Two further layer-1 facts the supervisor inherits:

- **Vendor `~`-side state forks per checkout.** Entering a worktree moves Claude's
  transcript path (`~/.claude/projects/<cwd-slug>/`) and **context-budget
  measurement silently stops** until the session re-registers. Observed
  2026-08-24; reproduced 2026-08-25 while writing this section. ADR-0006 named
  this exact pattern as its cautionary tale, and it sits outside the ADR's reach
  because the path is the vendor's, not ours.
- **Worktrees accumulate unevenly across vendors.** Claude auto-removes an
  unchanged worktree; Gemini never cleans, leaving a worktree *and* a branch per
  session. See "Vendor landscape" below.

### Layer 2 — worktrees and rollover, with no automation

Rollover already works from a worktree, and it is more mechanized than the
`work/` conventions suggest. Stated as a contract, because the supervisor
inherits every line:

1. **The rolling session may be in a worktree** — forced, for a bg job.
2. **Tracked artifacts move only through git.** `launch-next-session.sh:84` holds
   three loud preconditions before anything launches: the worktree has no
   uncommitted changes under `work/<proj>/`, no commits absent from every remote,
   and the main checkout is clean under `work/<proj>/`.
3. **The work branch is already merged unattended.** Invoked from a worktree, when
   the work branch is a clean fast-forward of `origin/main`, the launcher runs
   `push origin <branch>:main`, ff-pulls the main checkout, and proceeds (`:115`,
   the stale-launcher self-heal). Real divergence still refuses, loudly, to a
   human.
4. **The successor never inherits the worktree.** The launcher `cd`s to
   `WORKSPACE_ROOT` and launches from the main checkout (`:96`). Worktree
   isolation is scoped to a single session; it does not propagate down the chain.
5. **Untracked coordination state strands and is reconciled at read time**, per
   layer 1.

Points 3 and 4 were carried in earlier drafts of this spec as open questions —
"does the supervisor pin the main checkout or own worktree lifecycle?" and "one
branch per work item vs. unattended chains". **Both are already answered, in
code.** Verified against `launch-next-session.sh` on 2026-08-25.

### Layer 3 — what automation changes

The supervisor changes exactly one thing about layers 1–2, and it changes it
everywhere: **it removes the human.** Every item below is a place where a layer-2
guarantee turns out to have been a human-in-the-loop guarantee.

**Inherited for free — do not redesign:**

- **Supervisor and successor cwd: the main checkout.** Settled by layer 2 point 4.
  A session may isolate within its own life; the chain does not. The supervisor
  does *not* own worktree lifecycle.
- **Unattended merge of the work branch.** Settled by layer 2 point 3: ff-only,
  loud refusal on divergence. One branch per work item survives an unattended
  chain without inventing anything.

**What the supervisor must add:**

1. **Every coordination file resolves through the common dir.** The supervisor's
   three files (`.session-loop`, `.next-command`, `.rollover-complete`) are new
   untracked coordination state and must pass the layer-1 invariant — resolved via
   `git rev-parse --git-common-dir`, the pattern nine scripts here already use
   (`context-budget.sh:29`, `launch-next-session.sh:51`, `rollover-prep.sh:39`, …).
   **No coordination file is addressed by a bare relative path.** Unlike
   `.session-seq`, these have no read-time reconciliation to fall back on.

   *The failure this prevents, concretely:* a session isolates (forced, bg job);
   rollover writes `work/<proj>/.rollover-complete` relative to its own cwd,
   landing inside the worktree; the supervisor reads the main checkout and finds
   nothing; absent sentinel ⇒ *"human quit"* ⇒ the supervisor exits **reporting a
   clean shutdown.** The loop stops after one iteration and says nothing is wrong.
   The 2026-08-18 `.session-seq` decision note already named this mechanism
   verbatim — *"the agent's step-6 relative-path write (which lands in its own
   worktree — the actual stranding mechanism)."*

2. **The sentinel needs a positive discriminator.** `.session-seq` survives
   stranding by max-wins and `.rollover-options` by newest-mtime; both tolerate
   scattered copies. The sentinel can borrow neither, because it is a **presence
   test in which absence is the meaningful signal** — a stranded sentinel does not
   merge wrong, it reads as a deliberate quit. So it must carry the identity of
   the session that wrote it (seq, session id, and the cwd written from), letting
   the supervisor tell *"no session ended"* from *"a session ended somewhere I did
   not look."* An unreadable-but-expected sentinel halts loudly; it never exits
   quietly.

   **What makes a sentinel "expected."** Identity on the sentinel is necessary but
   not sufficient. Absence cannot be both the quit signal and the trigger for
   suspecting a stranded write, so the supervisor needs one fact it can read
   *without* the sentinel — and rule 5 of "Session number progression" already
   supplies one for free: **the counter.**

   | Counter | Sentinel in main checkout | Reading |
   | --- | --- | --- |
   | incremented | present | normal rollover — relaunch |
   | incremented | absent | **a session ended somewhere I did not look** — halt and notify |
   | unchanged | absent | nobody rolled over — deliberate quit, exit cleanly |

   The supervisor already reads the counter every iteration for rule 5, so the
   discriminator costs nothing. Without it, rule 2 is a requirement with no
   mechanism.

3. **A loud refusal is no longer loud.** Layer 2's guards — three launch
   preconditions, the stale-launcher refusal, divergence on ff-push — all `die`
   to a terminal a human is watching. Unattended, a `die` is just a stopped chain.
   Every inherited refusal needs a supervisor-side disposition: halt-and-notify,
   not halt-and-hope. This is the same class as the accepted gemini first-turn
   risk (`docs/context-budget.md:563`), accepted only because "caught by a human
   before it matters."

4. **The minimum-lifetime guard must verify its own measurement.** Per layer 1, a
   successor that isolates without re-registering measures nothing — under
   hands-off it then either never rolls over or rolls on a stale number. The guard
   must assert *this session's* measurement is live, not merely that some
   measurement exists.

5. **Worktree accumulation becomes a chain-cap input.** A 10-session gemini chain
   leaves 10 worktrees and 10 branches — more directories for untracked state to
   strand in, and a cost that grows with chain length (failure mode 3). Codex and
   Copilot cannot isolate locally at all, so any guard phrased in terms of
   worktrees is not vendor-neutral and belongs in the per-vendor wrapper, never in
   the supervisor.

### Vendor landscape

Relevant because the exit contract is already tiered per runtime, and worktree
support is **not** uniform across the six (verified 2026-08-24 against installed
versions):

| Runtime | Local worktrees | Isolation instead |
| --- | --- | --- |
| Claude Code | `.claude/worktrees/`; auto-removed if unchanged | — |
| Gemini CLI 0.46.0 | `.gemini/worktrees/`, `-w`; **never auto-cleans** | `--sandbox` |
| opencode 1.18.15 | TUI feature; unsupported in the new layout, mid-migration | — |
| Codex 0.149.0 | none | `codex sandbox` (seatbelt); `codex cloud` → `apply` |
| Copilot CLI 1.0.80 | none (zero mentions across all help topics) | MXC sandbox; `/delegate` → PR |

## Session number progression

The counter is the chain's only identity, and under a supervisor **nobody reads
it**. It has to be correct mechanically. It currently is not — verified by a live
off-by-one in this work item on 2026-08-25.

### How it works today

`.session-seq` holds the number of the **last-launched** session.
`launch-next-session.sh:187` computes `SEQ = max(over all checkouts) + 1`, writes
it back to the main checkout, and puts it in the bootstrap prompt. ADR-0007 makes
that prompt canonical: a session takes its number from its own prompt verbatim,
and on disagreement the ledger note is repaired, never the counter.
`session-rollover` step 6 closes the loop — the dying session writes **its own**
prompt number to `.session-seq`.

### The defect

**Step 6's write is redundant for every launcher-launched session, and dangerous
for all of them.** When the launcher starts session N it has *already* written N
to `.session-seq`; step 6 asks session N to re-derive and rewrite a number the
file already holds. The re-derivation is where it breaks: at step 6 the agent is
about to launch its successor, so the successor's number is the salient one.
Session 3 of this work item wrote `4`; the launcher added one and launched **#5**.
There was no session 4.

**And the error cannot be undone.** Cross-checkout reconciliation is *max-wins*
(`:194`) — justified because a counter only grows, and needed only because step 6
strands copies in worktrees. Max-wins cannot decrease, so an over-count is
absorbed and permanently ratified: every later session writes its own inflated
number, which is still the max. ADR-0007's self-heal is **one-directional** — it
corrects a counter that is too *low* (a hand-pasted, launcher-bypassing start)
and has no path back from one that is too high.

ADR-0007 anticipated the *ledger* drifting from the counter and ruled that the
counter wins. This is the inverse — the **counter** drifted — and the ADR's final
consequence already names why nothing caught it: *"No mechanical validator
exists."*

Under a human chain this costs one heading repair. Under a supervisor nobody
reads the prompt, so the drift is silent and compounding, and the number stops
being usable as evidence about the chain.

### Rules

1. **Step 6 becomes an assertion, not a write.** Read the counter through the
   common dir. Equal to your own prompt number ⇒ do nothing, the launcher already
   wrote it. Different ⇒ you started ad-hoc; write your own number and say so in
   the ledger block. **A write that is not a correction is a bug.**

   **This rule detects the 2026-08-25 direction; whether it can repair it depends
   on strays.** Max-wins reconciles *across checkouts* (`:187-194`), not against
   the file's own previous value — so a downward correction written to the main
   checkout is not discarded outright, it is **floored by any stranded copy
   holding a higher number.** Verified on disk 2026-08-25: this work item's main
   checkout holds `6` while the worktree copy still holds `4`, session 3's
   stranded write, never pruned.

   Two consequences for the implementer. First, the repair is contingent, so
   testing the upward case alone proves nothing about the downward one — pin both,
   and pin the floored case explicitly. Second, what unblocks a reliable downward
   correction is **routing every write through the common dir and pruning existing
   strays**, not retiring max-wins per se; once the counter has exactly one copy,
   max over a single file is the identity and rule 3 becomes safe rather than
   merely desirable.

   Note the lineage damage is permanent regardless. Session 3 wrote `4`, the
   launcher computed max+1 and launched `#5`, and no correction to the file can
   retroactively create a session 4 — which is why rule 5's per-iteration
   assertion, not after-the-fact repair, is the real guard.
2. **The agent stops writing coordination state by hand.** Step 6 becomes a script
   call — a `seq-sync --project <p> --session <N>` mode on `context-budget.sh` or
   `rollover-prep.sh` that resolves the common dir and validates before writing.
   This removes the last bare-relative-path write in the rollover path, and with
   it the only reason `.session-seq` ever strands.
3. **Once the counter has one home, retire max-wins** in favor of last-write-wins
   with validation, which *can* correct downward. Retire it only after rule 2
   ships — until then max-wins is load-bearing.
4. **Record provenance beside the counter.** `.session-seq` stays a bare integer
   for compatibility (`launch-next-session.sh:191` parses it with `tr -cd '0-9'`,
   which would silently mangle a JSON body into a garbage number), with a sidecar
   holding the writing session's id, runtime, prompt number, and cwd. That is what
   makes an over-count *detectable*: the writer claims #4 while the prompt that
   started it said #3.
5. **The supervisor asserts progression every iteration.** Exactly one increment
   per rollover; a delta ≠ 1 halts the chain and notifies. The counter is the
   cheapest available proof that the loop is doing what it believes it is doing.

Rules 1–4 are **workspace-level fixes that stand on their own merit** — they
improve the human-driven rollover today and are prerequisites for, not products
of, the supervisor. Rule 5 is supervisor-only.

## Failure modes and guards

1. **Gemini first-turn burn loop.** `docs/context-budget.md:563` records that a
   successor gemini session's first-turn check can read the *predecessor's*
   token count from the shared `.gemini/telemetry.log` and spuriously report
   STOP. It is marked **accepted** because "gemini chains are human-launched
   anyway … caught by a human before it matters." **The supervisor deletes that
   human.** Guard: a minimum session lifetime — no rollover-triggered exit before
   the session has recorded its own first measurement. Vendor-neutral, lives in
   the supervisor.
2. **Stall detection (hands-off only).** A stuck agent rolls into a successor
   stuck the same way, forever. Halt after N consecutive no-progress sessions and
   notify. Progress is a commit touching anything **outside the rollover
   bookkeeping set**, or a ticket-state transition under `work/<proj>/issues/`;
   files touched never count on their own. The exclusion is load-bearing —
   rollover commits the ledger and the launcher every session, so an unqualified
   commit test is a heartbeat rather than a signal. See open question 5. Without
   this guard the design is not trustworthy overnight.
3. **Chain cap / budget ceiling.** Max sessions per chain and/or a token or
   wall-clock ceiling, set before walking away.
4. **Crash vs deliberate quit.** Discriminated by the sentinel. No sentinel ⇒
   supervisor exits; covers `/exit`, Ctrl-D, and crashes identically. **Presence
   alone is not a sufficient test once worktrees are in play** — see "Worktrees"
   → layer 3, rules 1–2; the sentinel must be resolved through the git common dir
   and carry the identity of the session that wrote it.
5. **Runaway relaunch.** Sentinel is consumed (deleted) before relaunch, so a
   stale one cannot re-fire.
6. **Workspace trust.** Assert the target cwd is trusted before launching, and
   fail fast with a clear message rather than hanging on an unattended dialog.
7. **Signals.** Ctrl-C reaches the child as today; the supervisor traps it during
   the between-sessions pause so it stops the loop rather than being swallowed.
   Ctrl-Z suspends supervisor and child together; `fg` resumes both.
8. **Half-completed rollover.** The sentinel is written last, after flush and
   verification, so a rollover that dies partway leaves no sentinel. Note the
   ordering against the counter: `--emit` bumps the counter *before* the sentinel
   is written, so a death in that window presents as **counter incremented,
   sentinel absent** — which the layer-3 rule-2 discriminator already classifies
   as halt-and-notify rather than as a clean quit. The two guards agree, and this
   failure mode is the second reason the discriminator earns its place.
9. **Stop-hook etiquette.** Respect `stop_hook_active`; never block, only
   terminate. SIGTERM only — no SIGKILL escalation.
10. **Session-number drift.** The counter is the chain's only identity and nobody
    reads it unattended; an over-count is permanently ratified by max-wins. Guard:
    assert exactly one increment per iteration and halt on a delta ≠ 1. See
    "Session number progression" — rules 1–4 there are workspace fixes that must
    land before this guard means anything.
11. **Inherited refusals are silent unattended.** Every `die` in
    `launch-next-session.sh` (three launch preconditions, stale launcher, ff-push
    divergence) was written for a watching human. Guard: the supervisor gives each
    one a disposition — halt *and notify* — rather than treating a stopped chain
    as an ending. See "Worktrees" → layer 3, rule 3.

## Testing

- **Supervisor, no model:** stub child scripts that exit with/without a sentinel,
  in each mode. Asserts relaunch, keypress-wait, and clean exit paths.
- **`--emit`:** golden-file the emitted command against the existing `--dry-run`
  output for each of the six runtimes; assert side effects (`.session-seq` bump,
  options adopt, lock release, pending record) actually occurred.
- **Exit mechanism, per runtime:** the pty harness built this session
  (`script -q /dev/null` + a wrapper + a hook that SIGTERMs `$PPID`), asserting
  the supervisor's "terminal regained" line and a clean tty restore.
- **Guards:** simulate a no-progress chain and assert halt+notify; simulate a
  first-turn spurious STOP and assert the minimum-lifetime guard suppresses it.
- **Worktree resolution (layer 3, rule 1):** run the supervisor with the child
  isolated in a real worktree and assert every coordination file lands in the main
  checkout. The negative case is the one that matters — a sentinel written at a
  bare relative path must make the test **fail**, not pass quietly, since the
  defect's signature is a false clean exit.
- **Stranded sentinel (layer 3, rule 2):** plant a sentinel inside a worktree and
  none in the main checkout; assert the supervisor halts loudly rather than
  reporting a clean shutdown. Drive the discrimination from the counter and pin
  **both** directions: counter incremented with no sentinel in the main checkout
  must halt and notify, while an unchanged counter with no sentinel must read as a
  deliberate quit and exit cleanly. Testing only the alarming direction lets a
  supervisor that always halts pass.
- **Stall detection (open question 5):** run a chain whose every commit touches
  only the rollover bookkeeping set and assert it **halts** after N sessions. This
  is the test that fails if the exclusion clause is ever dropped — an unqualified
  commit test passes it trivially, which is precisely the defect.
- **Numbering (rules 1–5):** assert step 6 is a no-op when the counter already
  equals the session's own number; assert an ad-hoc start corrects it upward;
  assert a deliberate over-count is refused at write time rather than absorbed;
  assert the supervisor halts on a delta ≠ 1. Regression-pin the live 2026-08-25
  case: prompt "#3" writing `4` must not be able to produce a `#5` successor.
- Existing `scripts/tests/test-launch-next-session.sh` must keep passing
  unchanged — plain `claude` behavior is unmodified.

## Opt-in contract

`TF_SESSION_LOOP` is the single discriminator, exported by the supervisor and
inherited by the agent and its hooks.

| | Plain `claude` (today) | Under the supervisor |
| --- | --- | --- |
| Rollover step 6 | Prints the bootstrap prompt | Runs `--emit`, writes the sentinel |
| Exit hook | Inert | Terminates the session |
| Successor | Human runs the command | Supervisor relaunches |
| Interaction | Normal | Identical |

Both conditions false in a plain session ⇒ every new mechanism is inert ⇒
**today's behavior is preserved byte-for-byte.**

## Build order — the prerequisite the layering exposes

The three-layer reading changes *what gets built first*. The numbering fixes
(rules 1–4) and common-dir resolution are **layer-1 and layer-2 repairs that
stand on their own merit**: they make today's human-driven rollover correct, and
the supervisor is merely their first demanding consumer. They are prerequisites,
not deliverables of this design.

1. **Fix the counter** — step 6 becomes a validating script call; provenance
   sidecar; then retire max-wins. Ships and is testable with no supervisor.
2. **Close the last bare-relative-path writes** — `.session-seq` and
   `.rollover-options`, the two files an agent still writes by hand.
3. **Then build the supervisor**, whose new files inherit the layer-1 invariant
   by construction rather than by remembering to.

Building in the other order means the supervisor's first act is to add three more
untracked files to a workspace whose existing two already strand.

## Open questions

Two questions previously listed here — **supervisor cwd policy** and **one branch
per work item vs. unattended chains** — are **closed**, not by decision but by
discovery: `launch-next-session.sh` already pins successors to the main checkout
(`:96`) and already ff-merges the work branch unattended (`:115`). See
"Worktrees" → layer 2, points 3–4.

Questions 1–4 were probed on 2026-08-24; evidence and method are in
`work/session-loop-automation/probe-results.md`, and the answers are folded into the
tables above.

| # | Question | Answer |
| --- | --- | --- |
| 1 | Codex post-turn hook? | **Yes — `Stop`.** Tier A, firing test pending |
| 2 | Gemini `AfterAgent`? | **Yes**, and better than hoped — it documents a native session stop. Firing test pending |
| 3 | opencode plugin can kill its host? | **Yes — verified end-to-end** |
| 4 | Claude/Codex VS Code `code chat -m <id>` mode? | **No** (Claude), almost certainly no (Codex) |

**5. Stall-detection signal — ANSWERED 2026-08-25.** Commits are the primary
signal, **counting only commits that touch something outside the rollover
bookkeeping set**. Ticket-state transitions are a second signal for efforts that
run under `work/<proj>/issues/`. Files-touched never counts as progress on its
own — a stuck agent rewrites the same file every session.

The exclusion clause is what makes the signal real. **Rollover is itself a
commit:** writing the ledger and the launcher is what step 6 does, so every
session in a chain produces one by construction. Verified on this work item —
session 5's `7266007` touches `handoff.md` and `next-session.md` and nothing
else. Without the clause, "did this session commit?" is always yes, and the
signal measures the supervisor's own machinery instead of the agent's progress: a
perfectly stuck chain would show a clean commit every session, forever.

**The bookkeeping set.** A commit touching *only* these paths is rollover, not
progress:

- `work/<proj>/next-session.md`
- `work/<proj>/handoff.md` and `work/<proj>/handoff-archive.md`
- `work/<proj>/.session-seq` and its provenance sidecar (numbering rule 4)

Touch anything else and the session did work. Guard and threshold live in failure
mode 2; the test that pins the clause is in "Testing".

**Carried over from the probes — the one real gap.** The codex and gemini Tier A
claims rest on a serde enum and a shipped doc, not on a hook seen to fire. Both
need a live firing test before the supervisor relies on them; note codex's hook
trust gate (hash-recorded, re-prompts on edit, `--dangerously-bypass-hook-trust`
in CI). Everything else in questions 1–4 was re-verified against the installed
runtimes on 2026-08-24.

### Gemini needs no signal at all

`AfterAgent`'s documented output fields make the SIGTERM dance unnecessary there:

- `continue: false` — **stops the session** without retrying. A first-class exit at
  the turn boundary, which is exactly what Tier A is trying to synthesize.
- `stop_hook_active` — the same re-entrancy guard Claude's `Stop` carries, so
  failure mode 9 (stop-hook etiquette) applies verbatim, with no new rule.
- `hookSpecificOutput.clearContext: true` — clears LLM history while preserving the
  UI display. Noted for the record: gemini is the one runtime that *could* have
  supported the rejected `/clear` approach natively. The rejection stands on its
  other grounds (scrollback is the human's context, and the supervisor already
  delivers the benefit), but the option is real and vendor-supported here.
- `decision: "deny"` + `reason` re-prompts the agent — a retry channel the
  stall-detection guard (failure mode 2) could use to nudge before halting.
