# Context Budget — Measurement, Warning, and Rollover

LLM performance degrades past ~150K context tokens (the "dumb zone") regardless
of advertised window size. This workspace measures every agent session's live
context usage **exactly, from disk**, warns before the threshold, and rolls work
over to a fresh session via a deliberate handoff instead of uncontrolled
automatic compaction.

Pieces: `scripts/context-budget.sh` (the measurer: `check`, `register`,
`record`, `release`, `close`, `supervised`, `watch`) ·
`scripts/launch-next-session.sh` (the launcher: gates, then launch or stage
the successor) · `scripts/session-loop.sh` (the supervisor: runs sessions as
an unattended chain) · `scripts/hooks/context-budget-hook.sh` (one hook
dispatcher over `context-budget-adapters.conf`, one row per runtime) ·
`scripts/lib/session-lib.sh` (the one record writer) · `scripts/fleet.sh`
(sub-agent fleet verbs) · `skills/session-rollover/SKILL.md` (the rollover
workflow) · `context-budget.env` (thresholds + relaunch knobs) ·
`work/<item>/session-state.json` (the per-item session record) ·
`.context-budget/context-ledger.jsonl` (measurement ledger). The design these
implement: ADR-0010 (one record, three writers), ADR-0011 (mechanical gates
and reason codes), ADR-0012 (runtime contract).

> **Minimal mode — solo dev, one session at a time?** You need exactly three
> things: `register` at session start (automatic via hook in Claude Code),
> `scripts/context-budget.sh record --label "<what just finished>"` at
> work-unit boundaries, and the `session-rollover` skill when a WARN/STOP
> fires. That's the whole daily loop. Everything beyond the two Quickstarts —
> the supervisor, the fleet verbs, the per-runtime hook matrix — is for
> unattended chains and subagent fleets, safe to skip until you run those.

> **Agents — don't read this file whole (~9K tokens).** Pick your section from
> the index below, `grep -n '^## '` for its header, and Read with
> offset/limit from there. The two Quickstarts immediately below cover the
> common cases; go deeper only when a pointer names a specific section.

Section index:

- **Quickstart — developer** / **Quickstart — agent** — the commands and
  exit-code protocol; most visits end here.
- **Why you can't ask the model (D1)** — why usage is measured from disk.
- **Thresholds** — WARN/STOP values and where they live.
- **Rollover trigger policy** — what to do on exit 1 (WARN) vs 2 (STOP).
- **Relaunch knobs** — `ROLLOVER_RELAUNCH` modes; per-work-item override.
- **The session record** — the one state file per work item, and who writes what.
- **The launcher** — its gates, in order, and the two relaunch paths.
- **Who owns a work item** — liveness by process id; takeover; the successor's number.
- **The supervisor** — unattended chains: start refusals, the three verdicts, knobs, pages.
- **What the chain tells you** — each signal, what it means, what to do.
- **Verbs and reason codes** — the canonical list a test pins to the scripts.
- **Worktrees** — workspace-root anchoring.
- **Per-child sweep (`children`)** *(fleet-only)* — monitoring subagent context.
- **Dispatching long-running children** *(fleet-only)* — dispatch records +
  the rollover contract for child prompts.
- **Per-runtime adapters** — how each runtime's usage artifact is read.
- **How warnings reach the agent** — layered in-band delivery (D8).
- **Vendor hook deployments** — the dispatcher, the adapter table, the wiring per runtime.
- **Session registration** — what `register` pins and why.
- **Ledger** — measurement log format.
- **Known limitations**

## Quickstart — developer

```sh
scripts/context-budget.sh check                  # auto-detect runtime, one status line
scripts/context-budget.sh check --runtime codex  # or claude|copilot-vscode|copilot-cli|gemini
scripts/context-budget.sh watch --interval 30    # hook-less runtimes: poll + macOS notification
scripts/fleet.sh children                        # per-subagent sweep, WARN/STOP only (claude)
```

Output is one line: `runtime= method= tokens= threshold= warn= pct= status= artifact=`.
Exit code: `0` OK · `1` WARN · `2` STOP · `3` error. Requires `jq`.

When an agent tells you it got a WARN/STOP: let it finish the current unit, have
it run the `session-rollover` skill, then start a fresh session with the
bootstrap prompt it emits — or let the agent relaunch the successor itself per
`ROLLOVER_RELAUNCH` (see "Relaunch knobs"). Don't push new work into a STOP'd
session.

**Session lifecycle:** registering a session (`register`, below) is the
*agent's* job, not yours. It's automatic-by-instruction, not by mechanism — the
standing "Context Budget" section in `CONTEXT.md` tells every agent to register
at session start, which only works for sessions started inside the workspace
tree (where the agent loads that file) by an agent that follows it. Claude Code
is the one confirmed exception — it registers **by mechanism**, not by
instruction, via the `SessionStart` hook in the committed `.claude/settings.json`.
Copilot-in-VS-Code registers the same way via
`.github/hooks/context-budget-vscode.json` →
`context-budget-copilot-vscode-hook.sh` (pinning THIS session's transcript from
the hook payload on the first `SessionStart`/`Stop`). **This auto-register is
CONFIRMED working** (verified 2026-08-11, VS Code 1.132.0): `.github/hooks/` is
a DEFAULT `chat.hookFilesLocations` location, so no settings entry is needed and
the hook loads and fires on every session. The earlier s78/s79 "DEAD END"
finding was a false negative — the hook fired, but a pre-register
`[ -f "$cs" ]` guard skipped registration when SessionStart fires seconds before
VS Code creates the `chatSessions/<sid>.jsonl` token file. Fixed by moving the
registration block above the measurement guard (commit 27010c7;
`register` handles a missing artifact as `method=deferred`). Manual registration
(fix-B prefixed form below) is retained only as a fallback for hook-less
contexts (e.g. hooks disabled by enterprise policy). Full evidence:
`work/context-decay/copilot-vscode-hook-research-findings.md`.
Unregistered sessions still measure — `check` falls back to
newest-mtime discovery — but only registration pins the exact artifact, which
is what keeps concurrent sessions from reading each other's counts.

> **⚠️ Copilot VS Code — the `record`/`check` reading can lag the TRUE count by
> a wide margin under tool-heavy sessions.** Confirmed 2026-08-11 (R11 s84 +
> s85): `method=exact` returned a flat `52480` (34%) for an entire wave-scale
> session (30 sub-agents) while the real count was `232996` (155%, past STOP) —
> the transcript token file (`chatSessions/<sid>.jsonl`) flushes on the runtime's
> own cadence, not per turn, so mid-session `record` readings can badly
> under-report and a wave-scale phase can silently blow past STOP unnoticed. The
> **`Stop`-event hook is the authoritative STOP signal** (it fires with the
> settled count and blocks completion); do NOT trust a low mid-session `record`
> value to mean you have headroom. Practical rule: at a wave-scale boundary,
> roll over on the WORK-UNIT boundary regardless of the reported %, and have the
> user confirm the number against the VS Code UI if it matters.

## Quickstart — agent

- **Session start:** `scripts/context-budget.sh register` — pins your session
  artifact so later checks aren't confused by concurrent sessions. (Claude
  Code and Copilot VS Code: the hook already ran it mechanically — don't
  re-run; register manually only as a fallback if the hook was disabled.)
- **Every work-unit boundary:** `scripts/context-budget.sh record --label
  "<skill>: <unit> done"` — measures, appends to the ledger, and returns the
  status via exit code.
- **Exit 1 (WARN):** finish the current unit's bookkeeping, then ask the user
  whether to roll over; if declined, write ahead incrementally (see "Rollover
  trigger policy"). **Exit 2 (STOP):** finish only the current atomic step,
  then run `skills/session-rollover/SKILL.md` — no ask. Never start a new work
  unit in WARN/STOP state.
- **Dispatching a long-running subagent:** `scripts/fleet.sh
  dispatch-open --project <p> --task <slug> --report <path>` — persist the
  dispatch record and emit the rollover contract for the child's prompt in
  one step; `dispatch-close --status <S>` at yield (see "Dispatching
  long-running children").
- **What is IN the context (composition, not just size):**
  `scripts/context-inspect.sh [--phases] [transcript.jsonl]` — exact
  per-turn totals from the usage envelope plus a per-component breakdown
  (harness attachments turn-1 vs later, disk-side CLAUDE.md/memory stack,
  harness-fixed remainder). `--phases` adds a per-turn diff table — exact
  delta vs the attributed estimate (attachments / user+tool messages /
  prior assistant output) with the residual — for settling what a turn's
  growth actually was. Use it when optimizing what the session floor is
  spent on; claude-runtime transcripts only.
- **Reproducible composition experiment:** `scripts/context-experiment.sh
  [--workload <prompt-file>]` — runs two headless claude sessions (baseline
  "hi" + your workload), analyzes both with `--phases`, and prints the
  three-snapshot summary (S1 pre-turn-1 prediction, S2 turn-1 exact, S3
  post-workload exact). Re-run after template changes to see what they cost
  at session start. Bills real tokens (two sessions).

## Why you can't ask the model (D1)

Token usage lives in the API response envelope, which the model never sees;
agents guess their own usage badly (and optimistically). So the number always
comes from the runtime's on-disk session artifact, and the agent's role is
inverted: it *invokes* measurement at checkpoints; it is never the source of
the number.

## Thresholds

`context-budget.env` (checked in, non-secret):

```sh
CONTEXT_DUMB_ZONE_TOKENS=150000        # STOP
CONTEXT_DUMB_ZONE_WARN_TOKENS=120000   # WARN (defaults to 80% of STOP if unset)
```

Absolute counts, not %-of-window — a 936K Copilot window doesn't move the dumb
zone. Raise here as models improve. **Keep STOP below the runtime's auto-compact
trigger** (150K < Claude Code's ~200K): if compaction fires first, the
deliberate rollover never gets its chance.

One shared pair for all sessions and roles — per-role thresholds were
considered and ruled YAGNI (2026-08-06): thresholds encode where the model
degrades, roles differ only in the *response* to crossing. Revisit only if
dispatch records show mid-task `ROLLOVER_NEEDED` closures clustering in one
role class, or pre-120K degradation attributable to a role. Full reasoning:
`repos/ai-workspace-template/work/automatic-session-rollover/issues/08-per-role-thresholds.md`.

## Rollover trigger policy (hybrid: WARN asks, STOP goes)

> **Status:** implemented 2026-08-05 (ADR-0003/ADR-0004); rebuilt on the
> session record 2026-09 (ADR-0010/0011): the `session-rollover` skill carries
> the policy, `register` and `scripts/launch-next-session.sh` implement it
> (tests: `scripts/tests/test-launch-next-session.sh`, `test-emit-mode.sh`).

Who decides that a rollover happens, and when:

- **WARN (≥120K) asks — under `ROLLOVER_RELAUNCH=manual` or `off`** (the
  root default is `manual`). The agent finishes the current work unit, then
  asks the user "roll over now?". Under `auto` it rolls over without asking.
  Either way the **dying agent conducts the rollover itself** — mandatory,
  because the reflect step routes conversation-only state to disk and only the
  dying context has it.
- **Declining at WARN arms write-ahead mode** for the WARN→STOP grace window
  (~30K tokens): the agent routes discussion state to disk *incrementally* at
  each natural pause (settled points → `decisions.md`/analysis docs; open
  threads → the launcher), so the eventual STOP rollover is cheap and nearly
  lossless.
- **STOP (≥150K) goes automatic.** No ask; the agent finishes only the current
  *atomic step*, then rolls over. Mid-discussion, the atomic step is the
  current exchange: answer the user's message first, then roll over, carrying
  the live question verbatim into the launcher's START HERE so the successor
  re-poses it.

Consent lives in this trigger policy — WARN is the ask; STOP in `auto` mode
does not add a second "really launch?" gate (that would recreate `manual`
inside `auto`).


## Relaunch knobs

`context-budget.env` (same file as the thresholds):

```sh
# Relaunch behavior at session-rollover's closing step:
#   off    — print the paste-ready bootstrap prompt only, and refuse a supervisor
#            start against this work item (scripts/session-loop.sh)
#   manual — consent-gated: at WARN the agent asks, then runs launch-next-session.sh
#   auto   — no ask: the agent runs the launcher itself; the successor starts
#            attached (foreground) — there is no background launch path
ROLLOVER_RELAUNCH=manual
ROLLOVER_RUNTIME=claude   # fallback default only — the actual relaunch runtime
                          # comes from the dying session's own registry record
```

**What `off` means.** "Do not run me unattended at all": the rollover step
prints the prompt instead of launching, and `scripts/session-loop.sh` refuses
to start against that work item (`relaunch_off`), naming `--relaunch-override`
as the explicit human way in. The `--emit` staging path is unaffected — the
supervisor's own bootstrap depends on it.

**Per-work-item override:** an optional, **committed**
`work/<project>/context-budget.env` may set `ROLLOVER_RELAUNCH` (and/or
`ROLLOVER_RUNTIME`) for that work item alone. Precedence in every script:
explicit environment variable > per-item file > global `context-budget.env` >
built-in default (`off`). Only the relaunch knobs are read per-item; WARN/STOP
thresholds stay workspace-global. A registered codex session relaunches a codex
successor whatever `ROLLOVER_RUNTIME` says.

## The session record

Everything about a work item's current launch lives in one machine-local file,
`work/<item>/session-state.json` (gitignored; ADR-0010). Three scripts write it,
each its own block, all through `scripts/lib/session-lib.sh`
(`session_record_update`: read, precondition, filter, temp file, rename, under a
directory lock — a lost race is a silent no-op, never a blind overwrite).

| Block | Written by | Holds |
| --- | --- | --- |
| `seq` | launcher (opened by `register` on a record-less item) | the current session number; never reused |
| `launch` | launcher, at the bump | `launched_at`, `by` (`session` or `supervisor`), `mode` (`interactive`/`handsoff`), `reason`, `predecessor` {`seq`, `session_id`, `registered_at`, `disposition` = `rolled_over`/`abandoned`/`stopped`}, `pending` {`pid`, `pid_start`, `prompt`} on `--clear` |
| `session` | measurer (`register` fills, `release`/`close` end) | the owner: `seq`, `runtime`, `session_id`, `pid`/`pid_start` when the runtime has a process, `artifact`, `registered_at`, `launcher_hash`, `user`, `ended` {`at`, `door`} |
| `staged` | launcher (`--emit`), consumed by the supervisor before each run | `successor`, `command`, `by` (the staging session's id, or `supervisor`) |
| `chain` | supervisor | `supervisor` {`pid`, `pid_start`, `started_at`} while one runs, `used`, `cap`, `closed` {`at`, `by_seq`, `reason`} after a quit |

Hooks and gates only read it. There is no other state file: the counter, the
marker, the command file, the bump record and the sentinel of earlier designs
are gone. The lib refuses with `record_unreadable`, `schema_mismatch`,
`record_unwritable`, `lock_timeout`, `precondition_invalid`, `filter_invalid`,
`filter_empty` or `jq_missing`; every writer relays the code.

### Migrating work items from the old scripts

A workspace that pulls these scripts has work items in one of three shapes,
and `scripts/import-session-seq.sh --status` (all items, or one) tells them
apart from the files on disk — it writes nothing:

| `state=` | What the item ran | Do |
| --- | --- | --- |
| `fresh` | never any session script — no counter, no record | nothing; `register --project <item>` opens the record from the ledger's top block |
| `old` (`loop=no` attended, `loop=yes` the old `session-loop.sh`) | the old scripts: a `.session-seq` counter, no record | `scripts/import-session-seq.sh <item>` (`no_old_counter`, `counter_unreadable`, `seq_conflict`) |
| `imported` | the import; counter and record agree | delete the `leftovers=` files (nothing reads them) |
| `new` (`loop=yes` when the current `session-loop.sh` has run it) | the current scripts | nothing |
| `conflict` / `unreadable` | record ahead of the counter, or a file that does not parse | look before touching |

Stop any old `session-loop.sh` on the item first. The import sets `seq` to
the counter — the number of the last session that registered under the old
scripts — so the next session numbers itself exactly as a session after a
plain exit does (`adopted`/`filled`: the same number when that session left
no ledger block, else the launcher mints the next). Exit 1 from `--status`
means at least one item still needs the import or a look.

## The launcher — `scripts/launch-next-session.sh`

```sh
scripts/launch-next-session.sh <project> [--runtime <rt>] [--check] [--dry-run] [--skip-freshness]
scripts/launch-next-session.sh <project> --emit [--loop-mode interactive|handsoff] [--loop-reason "<why>"]
scripts/launch-next-session.sh <project> --clear
```

The rollover is: the agent writes the ledger block and the launcher file, then
runs the launcher. The launcher checks both files itself; a failed gate is
`launch-next-session: refused reason=<code> [k=v …] — <remedy>` on stderr, exit
4, and nothing written. `--check` runs every gate and writes nothing (exit 0 or
4); `--dry-run` adds the command that would run. Gates, in order:

| Gate | Refuses when |
| --- | --- |
| `schema_mismatch` | the record is unreadable or not schema 1 |
| `chain_closed` | `chain.closed` is set — a session ended this chain on purpose; `session-loop.sh <p> --reopen` |
| `runtime_path_unsupported` | `--emit` on copilot-vscode (detached by nature); `--clear` off claude, or on an owner with no pid |
| `supervised_stage_only` | a plain launch or `--clear` while a supervisor is live — stage with `--emit` instead |
| `no_supervisor` | `--emit` from a session the supervisor started (`TF_SESSION_LOOP=1`) but none is live |
| `owner_live` | another session owns the item and its process is alive — roll over from it, or `register --takeover` |
| `not_owner` | no owner, or a dead owner this session has not adopted — `register --project <p>` first |
| `worktree_unsynced` | invoked from a worktree with uncommitted/unpushed `work/<p>/` changes, or the main checkout dirty or un-pullable |
| `launcher_stale` | git holds a newer `next-session.md` this checkout lacks; `--skip-freshness` overrides |
| `launcher_unchanged` | `next-session.md` is absent or its hash equals the one recorded at registration — write the successor's launcher first |
| `ledger_shape` | no `handoff.md`, no `# Session Handoff` heading, or no number in the top heading |
| `ledger_seq_mismatch` | the top ledger block is not this session's number |

The artefact gates (the last four) are skipped for the supervisor's own
bootstrap, which has no dying session. `jq_missing` is refused before anything
is read. Then one atomic write: `seq` advances by one, `launch` records who
launched, how, and the predecessor (`rolled_over` for the owner that rolled;
`abandoned` or `stopped` for a dead owner the supervisor's bootstrap steps
past), `session` empties, and:

- **attached** (the default): the successor starts in the foreground with the
  env pair `TF_SESSION_PROJECT=<p> TF_SESSION_SEQ=<n>` ahead of the vendor
  command, or — from a tool shell, or under `ROLLOVER_RELAUNCH=off` — the
  ready-to-run line is printed instead;
- **`--emit`** (under a supervisor): the command goes into `staged` and is
  printed as `cmd: <line>`; the supervisor runs it. The session that staged is
  ended by its turn-end hook at the end of that turn (see "The supervisor");
- **`--clear`** (claude only, attended): no process starts. The prompt goes into
  `launch.pending` with this process's pid and start time; the human presses
  `/clear`, the `SessionStart` hook's `register` matches the pid, binds the new
  session id to the open launch, and prints the prompt into the cleared context.
  Choose `--clear` when the successor needs the same MCP server set (it keeps
  the login and the connected servers); choose a fresh process when it needs a
  different fragment or runtime.

The bootstrap prompt is built in one place and is verbatim (ADR-0003):
`Work item <p> - rollover session #<n>. Read work/<p>/next-session.md and continue from **First actions**.`
Claude successors also get `--name "<p> #<n>"`, so session titles read as
work item + lineage number. Vendor flags live only in the script.

## Who owns a work item

A session owns a work item while it is the record's `session` and its process
is alive: `pid` running **and** started when `pid_start` says. That pair is the
only liveness test wherever the runtime has a process of its own; an owner
with no pid (copilot-vscode, gemini) is alive while its transcript was written
within `CONTEXT_LOCK_STALE_SECS`. No roles, no locks, no stamps.

`register` never blocks; its exit code is the measurement's. Binding outcomes,
one per `register: bound … (<outcome>)` line: `opened` (a record-less item,
`--project` given: `seq` opens at the ledger's top block + 1, else 1), `filled`
(an open launch with no owner), `refreshed` (the same session again), `adopted`
(the owner is dead, or is this very process after `/clear`), `takeover`
(`--takeover`, the explicit human steal, logged with the loser). A live
different owner keeps the slot: `register: reason=owner_live …`, and this session
is measured but cannot roll the item over (`not_owner` at the launcher).

**How the successor finds its number** (no guessing, no time window): the
launcher passes it in the environment on attached launches and under the
supervisor (`TF_SESSION_PROJECT` + `TF_SESSION_SEQ`; both required, and the
record's `seq` must agree); on `/clear` the process is the same, so its pid and
start time match `launch.pending`; whoever explicitly runs
`register --project <p>` against an open launch (number advanced, owner empty)
becomes that session. A session that matches nothing registers without a work
item and only measures itself. Numbers are never reused: a session that
vanished is closed as `abandoned` at the next bump and the gap stays in the
ledger.

**Two doors out.** `session-rollover` (the launcher) continues the work;
`checkpoint` ends it through `scripts/context-budget.sh close [--check]`, the
stop door: it runs the same ledger checks inline (`not_owner`, `ledger_shape`,
`ledger_seq_mismatch`) and marks `session.ended.door = stop`, which the
supervisor reads as `quit_stop`. A plain `/exit` is neither and is recoverable —
the next launch records the owner as `abandoned`.

## The supervisor — `scripts/session-loop.sh`

Runs a chain of rollover sessions unattended. Started once by a human, owns the
terminal, never talks to a model:

```sh
scripts/session-loop.sh <project> [--runtime <rt>] \
  [--max-sessions <N>] [--min-lifetime <secs>] [--stall-limit <N>] \
  [--reset-cap] [--reopen] [--relaunch-override]
```

**Start.** It reads the record once and refuses (exit 4, `session-loop: refused
reason=<code>`) on `record_unreadable`, `schema_mismatch`, `relaunch_off` (the
item commits `ROLLOVER_RELAUNCH=off`; `--relaunch-override`), `chain_closed`
(`--reopen` nulls the close and proceeds), `supervisor_live` (another
supervisor's pid is alive with the recorded start time). `--reset-cap` resets
`chain.used` and exits 0 without starting; a chain at its cap is the verdict
`cap` before anything is staged. It then writes `chain.supervisor` (pid, start
time) and exports `TF_SESSION_LOOP=1` and `TF_SESSION_LOOP_PROJECT=<p>`, which
the sessions and their hooks inherit.

**Each iteration.** Nothing staged → the bootstrap: a direct call of the
launcher with `--emit` (a refusal there is relayed with the launcher's code, or
`stage_failed` if it printed none). A staged successor whose number already has
a registered owner → `staged_invalid leg=spent` (the command was run by hand or
by another chain; the s18 duplicate-session defect). Otherwise it consumes
`staged` and charges `chain.used` in one write, exports the env pair, records
the start instant, and `eval`s the command in the foreground.

**The verdict**, read from the record after the child exits — only fields a
script wrote:

| Verdict | Evidence | Then |
| --- | --- | --- |
| `staged` | `seq` moved by exactly one, `launch.predecessor` names the child as `rolled_over`, `staged.by` is the child's session id, the child's registration is not older than its start, and it lived at least `--min-lifetime` | run the next session (interactive mode: after Enter) |
| `quit_plain` / `quit_stop` | nothing staged, `seq` unchanged, the child registered after it started, exit 0, transcript not ending in a logout; `quit_stop` when it went through `close` | `chain.closed` is written; exit 0 |
| `cap` | `chain.used` reached `chain.cap` | exit 0; the staged command stays for a restart after `--reset-cap` |

Anything else is **broken** (exit 1, `session-loop: broken reason=<code>`,
through the notify hook): `rc_nonzero` (the command never ran or the child
died), `logout` (exit 0 but the transcript ends on a terminal
`authentication_failed`; the slot is refunded — log in and restart),
`staged_invalid` with a leg (seq: moved by more than one; staged: moved but
nothing staged, or the block changed underneath; predecessor: the launcher did
not record the child as rolled over; by: staged by someone else; lifetime: a
rollover faster than `--min-lifetime` is not work), `no_own_measurement` (the
child never registered against the item after it started), `record_unreadable`
/ `schema_mismatch` (the record broke mid-chain), `stall` (`--stall-limit`
consecutive hands-off sessions whose commits touched only `README.md`,
`next-session.md`, `handoff.md` and `handoff-archive.md`).

**Ending a session that staged.** `--emit` is the last thing a supervised
session does: the vendor's turn-end hook (`Stop` for claude and codex,
`agentStop` for copilot, `session.idle` for opencode) reads the record, and when
`staged.by` is this session's own id under `TF_SESSION_LOOP=1`, it SIGTERMs the
agent at the turn boundary, so the supervisor's `eval` returns. Unset, every
mechanism here is inert and plain `claude` behaves exactly as before.

**Knobs** live in `context-budget.env`; a committed `work/<proj>/context-budget.env`
overrides per work item, the same precedence `ROLLOVER_RELAUNCH` uses.

| Knob | Default | Guards |
| --- | --- | --- |
| `SESSION_LOOP_MAX_SESSIONS` | 10 | chain cap |
| `SESSION_LOOP_MIN_LIFETIME` | 60 | a first-turn spurious STOP (`staged_invalid` leg lifetime) |
| `SESSION_LOOP_STALL_LIMIT` | 3 | a chain committing only bookkeeping (`stall`); off in interactive mode |
| `SESSION_LOOP_ALARM` | 900 | seconds between liveness checks on a running child; a tick pages only when the transcript has gone silent |
| `SESSION_LOOP_ALARM_MAX` | 3600 | ceiling on the alarm interval, which doubles after each silent page |
| `SESSION_LOOP_KILL_AFTER` | 14400 | seconds of transcript silence after which the child is killed (0 = off) |
| `SESSION_LOOP_NOTIFY` | `scripts/session-loop-notify.sh` | a command run with every halt, verdict and page as `$1` (desktop notification where available) |

**The watchdog** identifies the child from the record (`session.pid`, a child of
this supervisor) and ages its transcript (`session.artifact`). Each tick lands in
one of four places, each a `page=` token in the message: `unidentified` (no
verdict, never a kill), `blocked` (past STOP with nothing staged — the chain is
stranded until the session stages or quits), `staged_alive` (staged and still
running two ticks later — the turn-end hook did not fire), `silent` (nothing
written for the interval; kills at `SESSION_LOOP_KILL_AFTER`). A child seen
writing again resets the interval. Silence pages fire in hands-off mode only;
in interactive mode the human at the keyboard is the stall detector.

**Modes.** The dying session chooses `--loop-mode interactive|handsoff` at
`--emit` (recorded as `launch.mode`); a human `touch work/<p>/.hands-off` or
`.interactive` overrides it, and the launcher refuses if both exist.
Interactive waits for **Enter** between sessions (a keypress, not a countdown)
and disables the stall guard.

**A supervisor change takes effect one invocation late.** `bash` runs the
script text it already holds, so an edit to `session-loop.sh` first applies to
the next start; the running chain finishes on the old code. Check
`git log -1 scripts/session-loop.sh` against the supervisor's start time before
diagnosing a surprising halt.

## What the chain tells you — signals and what to do

Every signal names its own remedy at the point it fires; this section adds
what a one-line message cannot carry.

| What you see | What it means | What to do |
| --- | --- | --- |
| `successor: NOT STAGED — this chain continues only if you stage one.`, from `record` or `register` | nothing is staged and this session is already at WARN or STOP under a live supervisor | stage one — the exact command is printed on the next line — or quit deliberately to end the chain |
| `CONTEXT BUDGET STOP: … It is not finished until step 6 has staged your successor` (and the same clause at WARN) | the rollover is complete when the successor is staged, not when the handoff is written | run `skills/session-rollover/SKILL.md` through its closing step: a bare `--emit` |
| a page `blocked` — past its context budget with no successor staged | the chain is stranded; the supervisor will not invent a successor | finish the rollover (its closing step stages one) or quit deliberately |
| a page `staged_alive` — staged a successor and still running | the turn-end hook did not end the session that staged | check the runtime's turn-end hook wiring ("Vendor hook deployments") |
| `refused reason=not_owner` at `--emit` | this session is not the record's owner (never registered, or already rolled over) | `scripts/context-budget.sh register --project <p>`, then stage again |
| `refused reason=no_supervisor` at `--emit` | this session was started by a supervisor (`TF_SESSION_LOOP=1`) but none is live — also the shape a sub-agent's shell sees, since it inherits the chain's env | start one (`scripts/session-loop.sh <p>`), roll over attached, or unset the four `TF_SESSION_*` variables for a hand run |
| the supervisor refuses `chain_closed` | a session ended this chain on purpose | `--reopen` |
| the supervisor refuses `relaunch_off` | this work item says it must not be run unattended | `--relaunch-override` |
| `broken reason=staged_invalid leg=spent` at start | the staged command was already run by hand | roll over from that session, or null `staged` by hand |

**`successor: NOT STAGED` stays silent** below WARN, without a live supervisor,
and for sub-agents — so not seeing it proves nothing. To know whether a
successor exists, read `staged` in `work/<p>/session-state.json`. Its second
limb matters: **a deliberate quit with nothing staged is a correct ending**, not
a fault; the supervisor records the close and refuses to restart the item until
`--reopen`.

## Verbs and reason codes

The canonical list. `scripts/tests/test-doc-consistency.sh` pins it both ways:
every word in backticks under "Verbs" is a `case` arm of `context-budget.sh` or
`fleet.sh`, every word in backticks under "Reason codes" is a code a lifecycle
script emits, and nothing the scripts emit is missing here. Exit codes: `check`
/`record`/`register` 0/1/2 = OK/WARN/STOP; every verb 3 = usage, 4 = refused
(`reason=<code>` on stderr, `key=value` detail on the same line); the
supervisor 0 = chain ended, 1 = broken. Legs and other detail after a code are
free-form and never a test contract.

### Verbs

| Script | Verbs |
| --- | --- |
| `scripts/context-budget.sh` | `check` (measure; `--session-id` pins a named session), `register` (bind at start), `record` (measure + ledger line), `release` (end the owner's block), `close` (the stop door, `--check` dry-run), `supervised` (0 live / 1 not / 2 ambiguous), `watch` (poll + notify, hook-less runtimes) |
| `scripts/fleet.sh` | `children`, `dispatch-contract`, `dispatch-open`, `dispatch-close`, `dispatch-list` |

### Reason codes

| Emitter | Codes |
| --- | --- |
| record library (relayed by every writer) | `record_unreadable`, `schema_mismatch`, `record_unwritable`, `lock_timeout`, `precondition_invalid`, `filter_invalid`, `filter_empty`, `jq_missing` |
| register, binding outcomes (info) | `opened`, `filled`, `refreshed`, `adopted`, `takeover`; a kept slot is `owner_live` |
| release and close | `not_owner`, `ledger_shape`, `ledger_seq_mismatch` |
| launcher gates, in order | `chain_closed`, `runtime_path_unsupported`, `supervised_stage_only`, `no_supervisor`, `owner_live`, `not_owner`, `worktree_unsynced`, `launcher_stale`, `launcher_unchanged`, `ledger_shape`, `ledger_seq_mismatch` (plus `schema_mismatch` and `jq_missing` first) |
| supervisor start | `relaunch_off`, `chain_closed`, `supervisor_live`, `stage_failed` (the bootstrap launcher refused without a code), `staged_invalid` (leg spent) |
| supervisor verdicts | `staged`, `quit_plain`, `quit_stop`, `cap` |
| supervisor broken | `rc_nonzero`, `logout`, `staged_invalid` (legs seq, staged, predecessor, by, lifetime), `no_own_measurement`, `stall` |
| watchdog pages | `unidentified`, `blocked`, `staged_alive`, `silent` |
| `scripts/import-session-seq.sh` | `no_old_counter`, `counter_unreadable`, `seq_conflict` |
| hook dispatcher | `jq_missing` (stderr, exit 0, silent envelope on stdout) |

## Worktrees (workspace-root anchoring)

**Coordination state is keyed to the repository, never to a checkout**
(ADR-0006). Every script resolves `WORKSPACE_ROOT` through
`git rev-parse --git-common-dir` (the parent of the shared `.git`) when the git
root is this workspace, and through the script-anchored fallback otherwise, so
a script invoked from any git worktree reads and writes the **main
checkout's** `.context-budget/`, session records and ledger. Consequences:

- `register`/`record`/`release`/statusline/hooks behave identically in a
  worktree and in the main checkout.
- `launch-next-session.sh` invoked from a worktree first syncs the main
  checkout (no uncommitted `work/<p>/` changes, no unpushed commits, then
  `pull --ff-only`; `worktree_unsynced` on each), and launches from the main
  root.
- A live-ish run **from a worktree drives the main checkout's `work/`** — the
  supervisor and launcher included. Use a `git clone` of the branch in a
  scratch directory for that, never the worktree (the suites already run
  against temp directories). See `docs/operational-knowledge.md`.
- Fallback: outside a git repo, or when the git root is not this workspace,
  resolution reverts to the script-relative root — single-checkout behavior
  unchanged.

## Per-child sweep (`children`)

No runtime reports a subagent's context usage to its parent — the parent must
measure the child transcript artifacts directly (research R1). `children
[--parent-session <sid>] [--all]` does that sweep for Claude Code sessions
(the only runtime with a verified per-child artifact layout; anything else
dies loudly):

- Enumerates `<parent-artifact-dir>/<parent-uuid>/subagents/agent-*.jsonl`
  (direct children only — a child's own children are its business, R8) and
  measures each with a sidechain-*inclusive* variant of the Claude adapter: a
  subagent transcript's rows are all `isSidechain: true`, so the self-measure
  filter would silently degrade every child to a size estimate.
- **Escalation-only output:** only WARN/STOP children print (one check-style
  `agent= tokens= … status= age= type=` line each; `age` = artifact mtime age,
  the usual liveness signal; `type` = `agentType` from the `.meta.json`
  sibling). `--all` lists OK children too. Summary count goes to stderr.
- **Exit code = worst child status** (0 OK / 1 WARN / 2 STOP), so a parent
  can gate on the sweep exactly like its own `check`. Default parent is the
  current session; `--parent-session <sid>` sweeps another *registered*
  session's children.

What to do when the sweep escalates is the next section's R3 rule: roll the
child (fresh dispatch), don't resume it.

## Dispatching long-running children (`dispatch-contract` + dispatch records, R2–R4)

A child can't measure itself (D1 applies twice over — it has no hook wiring
and no envelope), and no runtime lets a parent reliably message a running
child. So child rollover rests on three portable rules, workable in every
runtime with no child handles at all (research §5/§8/§10/§11):

- **R2 — every long-running child is dispatched under a contract.**
  `dispatch-contract --report <path> [--brief <path>] [--gen <n>]` emits the
  block to include in the child's dispatch prompt: checkpoint by appending a
  progress block to the report file at every work-unit boundary (the report's
  mtime doubles as the child's heartbeat), cap the final return at 15 lines
  with detail in the report, first return line from
  `DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT | ROLLOVER_NEEDED`,
  and — on a checkpoint request — flush and yield rather than push on.
  `ROLLOVER_NEEDED` is only ever a *response* (to a checkpoint request, or to
  a WARN/STOP line pushed by the child's own runtime hooks), never the
  child's self-assessment. The subcommand is stateless, runtime-agnostic,
  and ASCII-only (dispatch prompts traverse `%q` and BSD sed in launch
  paths).
- **R3 — successor dispatch is the only rollover verb.** Resume is for
  *continuation* (e.g. SDD fix rounds), and every resume stacks history onto
  the child's transcript — the research's motivating 141.8K child was a
  resumed one. Before any resume, sweep (`children`); at WARN/STOP, ask the
  child to checkpoint, then dispatch a *fresh* child with `--gen N+1` (the
  contract then opens with "read the report file first; finish its open
  items"). Child WARN is the parent's decision, no human ask — humans are
  only consulted at the top level (R7).
- **R4 — the parent persists a dispatch record per task; generations are
  fenced.** `dispatch-open --project <p> --task <slug> --report <path>
  [--brief <path>] [--agent-type <t>] [--model <m>] [--effort <e>]
  [--agent-id <id>]` appends generation N+1 (status `open`) to
  `work/<p>/.agent-dispatch/<slug>.json` and emits the R2 contract for that
  generation in one step — never pass `--gen` here, it is computed from the
  record. Fencing: `dispatch-open` refuses while the previous generation is
  still open; close it first with `dispatch-close --project <p> --task
  <slug> --status <S>` (`S` = the five yield statuses, or `KILLED` — the
  parent's ruling on a hung/crashed child that never yielded; `--agent-id`
  merges at close once known). At most one live writer per report file, and
  the contract labels every appended block `[gen N]`, so the report reads as
  history across generations. `dispatch-list --project <p>` prints one
  `task= gen= status= report=` line per record and exits 1 while any
  generation is open — the drain check a rolling parent runs before its own
  rollover. Records are gitignored runtime state anchored to the workspace
  root (ADR-0006), same class as the session record.

The records are what make parent rollover fleet-safe: a successor parent
cannot resume the predecessor's children (resume is keyed to the dead
parent's session id), but it can `dispatch-list`, close orphaned open
generations `KILLED`, and re-dispatch each unfinished task fresh from its
recorded spec — `dispatch-open` hands gen N+1 the read-report-first clause
automatically. Without records, a parent rollover silently loses the fleet.

Task sizing is the cheapest prevention: scope child tasks so the expected
peak stays under WARN (the measured median child is ~67K; the tail is what
the sweep catches). Deferred to a later slice: drain mode (R6).

## Per-runtime adapters

Session formats are undocumented internals; each runtime gets one discover + one
measure function in the measurer (and one row in `scripts/hooks/context-budget-adapters.conf`
for its hooks) behind a fixed output contract, so format drift breaks one
function, never the skills/docs/hooks. Where parsing fails, the fallback is
always a bytes÷4 estimate (`method=estimate`), never "unsupported" — ±25% is
fine given the WARN→STOP margin.

| Runtime | Artifact | Signal | Fidelity |
| --- | --- | --- | --- |
| Claude Code | `~/.claude/projects/<cwd-slug>/$CLAUDE_CODE_SESSION_ID.jsonl` when that var is set (transcript basename = session id), else newest `.jsonl` in the slug dir (slug = cwd with `/` and `.` → `-`) | last main-chain `message.usage` sum of input + cache-read + cache-creation tokens; sidechain (sub-agent) rows excluded — they have their own windows | exact (verified 2026-07-22, this workspace) |
| Codex | `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` — pinned to `rollout-*-<id>.jsonl` when `$CODEX_THREAD_ID` is set (exported to every shell Codex spawns; equals the rollout UUID), else cwd-filtered newest-mtime fallback | last `last_token_usage.total_tokens` | exact (verified 2026-07-22, origin workspace); pin live-verified 2026-07-23 |
| Copilot VS Code | **Hook route (preferred, CONFIRMED working 2026-08-11):** the agent-mode hooks derive the `chatSessions/<id>.jsonl` path from the hook payload's `transcript_path` + `session_id` (`…/GitHub.copilot-chat/transcripts/<id>.jsonl` → `../../../chatSessions/<id>.jsonl`) and pass it as `--transcript` — no env var, works from the unsandboxed hook process; `.github/hooks/` is a default `chat.hookFilesLocations` location so the hook loads and auto-registers with no settings entry. **Terminal route (fallback):** `$VSCODE_TARGET_SESSION_LOG` when set (Copilot terminal sessions export it — on current builds a `debug-logs/<id>` dir whose basename is the session id), mapped to `~/Library/Application Support/<app>/User/workspaceStorage/<hash>/chatSessions/<id>.jsonl` (`<app>` = Code, Code - Insiders, VSCodium; `<hash>` found by grepping the workspace path in `workspace.json`) — deterministic, so it pins the live session even when a sibling's log is newer. Falls back to newest-mtime only when the var is unset (older builds), which can race | last `"promptTokens":N` via flat `grep -o` — these files reach 4–5MB with multi-MB single-line records; jq times out | exact (verified 2026-07-23, origin workspace; chatSessions promptTokens re-confirmed live 2026-08-06 on VS Code 1.132.0) |
| Copilot CLI | root `${COPILOT_HOME:-~/.copilot}`; `session-state/<id>/events.jsonl` pinned via `$COPILOT_AGENT_SESSION_ID` (CLI ≥1.0.29, exported to shell commands), else newest-mtime across `session-state/` then legacy `history-session-state/` | tries `promptTokens`/`input_tokens`/`inputTokens`, else estimate | exact (verified 2026-08-05 against a live CLI 1.0.78 session in the `ai-workspace-template` deployment — 73.0k UI match; evidence: `repos/ai-workspace-template/work/automatic-session-rollover/smoke-test-copilot.md`. No live CLI session has run in this workspace yet — the ledger has no copilot-cli records) |
| Gemini CLI | workspace `.gemini/telemetry.log` (local OTLP export, wired in tracked `.gemini/settings.json`), else `~/.gemini/tmp/<hash>/logs.json` | last response's input tokens from the telemetry log (`input_token_count` or OTel `gen_ai.usage.input_tokens`); chat logs carry no token counts → bytes÷4. The telemetry log is shared append-only across sessions, so `register` resets it — a new session never reads the previous session's counts | exact when the telemetry log has data (**unverified** against a live session); estimate otherwise |

Non-macOS: the Copilot VS Code storage root differs (Linux `~/.config/Code/…`,
Windows `%APPDATA%/Code/…`); BSD `stat -f` already falls back to GNU `stat -c`;
replace the `osascript` notification in `watch` with `notify-send` or equivalent.

**Remaining limitation — gemini only.** The session-keyed registry (see
"Multi-session model" above; shipped 2026-08-05) lets concurrent sessions of
any runtime coexist in one workspace, each measuring its own artifact. Gemini
is the exception: its exact counts come from the shared workspace telemetry
log, which is architecturally single-session-per-workspace. `register` guards
the boundary — a telemetry log another live session wrote to in the last 10
minutes is left alone, and the new session degrades to a chat-log bytes÷4
estimate. Explicit `--transcript` still overrides everything.

## How warnings reach the agent (layered, D8)

No single mechanism covers every runtime, so four layers overlap:

1. **In-band hook (all six runtimes, incl. Copilot VS Code agent mode):** each
   runtime's own committed hook
   wiring pushes a WARN/STOP message into the agent's turn. Escalation-only
   (one WARN + one STOP per session), throttled to one check/minute, fails
   open — any hook error exits 0 (or emits the vendor's silent-JSON shape) so
   it can never block real work. All six wirings ship committed — Claude
   Code's in `.claude/settings.json` (hooks + statusLine only; personal
   permissions stay in the gitignored `settings.local.json`, which
   `scripts/setup.sh` seeds from `.claude/settings.json.example`; never copy the `hooks` block
   into `settings.local.json`, or each copy fires once per event). Full
   per-runtime wiring/channel/friction breakdown: "Vendor hook deployments"
   below.
2. **Mandatory checkpoints in long-running skills (all runtimes):** `onboard-repo`
   and `rlm` carry a measured-checkpoint clause — `record` at every phase
   boundary and act on the exit code.
3. **Polling watcher (hook-less runtimes):** `watch` posts an OS notification on
   status escalation.
4. **Standing instruction:** the "Context Budget" section in `CONTEXT.md`
   (read by every runtime via the symlinked entrypoints).


## Vendor hook deployments

One dispatcher, `scripts/hooks/context-budget-hook.sh <runtime> <event>`,
produces every runtime's hook payload from the adapter table
`scripts/hooks/context-budget-adapters.conf` — one row per runtime: where the
session id and transcript come from, the measurer's `--runtime`, who runs
`register`, which vendor event measures each turn and with which output
envelope, which event ends a turn and how, and what a logout looks like
(ADR-0012). The shared core, `scripts/hooks/context-budget-hook-lib.sh`, holds
what must not drift between runtimes: the throttle (`CHECK_EVERY`, default
60s), escalation-only emission (one WARN and one STOP per session, tracked in
`.context-budget/hook-<runtime>-<session>.status`), the message text, and the
turn-end exit predicate (`staged.by` is this session, under `TF_SESSION_LOOP=1`).
Fail-open throughout: any error exits 0 (gemini: `{}`); a missing `jq` prints
`refused reason=jq_missing` on stderr before anything is parsed. The per-vendor
files beside the dispatcher are one-line shims onto it, kept so the committed
wiring below needs no edit.

| Runtime | Wiring file → shim | Check hook / envelope | Turn-end hook / action | Friction gate |
| --- | --- | --- | --- | --- |
| Claude Code | `.claude/settings.json` (committed; hooks + statusLine only — personal permissions live in the gitignored `settings.local.json`, seeded from `.claude/settings.json.example`; never copy the `hooks` block there or each hook fires twice) → `context-budget-claude-hook.sh`, `context-budget-stop-hook.sh claude` | `PostToolUse`: stderr text + `exit 2` | `Stop`: SIGTERM the agent once it staged | none — `SessionStart` runs `register` and `SessionEnd` runs `release` mechanically; every command self-resolves the repo root when `$CLAUDE_PROJECT_DIR` is empty |
| Codex | `.codex/config.toml` → `context-budget-codex-hook.sh`, `context-budget-stop-hook.sh codex` | `UserPromptSubmit`: `{hookSpecificOutput:{hookEventName,additionalContext}}` | `Stop`: SIGTERM | hash-based hook trust: the first run in a repo prompts once; editing the hook command re-prompts; CI passes `--dangerously-bypass-hook-trust` |
| Gemini CLI | `.gemini/settings.json` → `context-budget-gemini-hook.sh` | `BeforeAgent`: JSON-only stdout, `{}` when silent | none — chains unsupported, attended rollover only | measures the workspace `.gemini/telemetry.log`; a successor's first-turn check can read the predecessor's last entry (accepted: gemini chains are human-launched) |
| opencode | `.opencode/opencode.json` `plugin` array → `.opencode/plugins/context-budget.js` → `context-budget-opencode-hook.sh` | `chat.message`: the plugin pushes a message part | `session.idle`: the dispatcher prints `exit`, the plugin self-kills | plugins are not auto-discovered — list it in `opencode.json`; the sqlite read has no size-estimate fallback |
| Copilot CLI | `.github/hooks/context-budget.json` → `context-budget-copilot-hook.sh` | `sessionStart`: `{additionalContext}` | `agentStop`: SIGTERM, then `{decision:"block",reason}` at STOP | folder trust: hooks no-op unless the workspace is in `~/.copilot/config.json` `trustedFolders` (`scripts/setup.sh` seeds it; `check-tooling.sh` warns) |
| Copilot VS Code (agent mode) | `.github/hooks/context-budget-vscode.json` → `context-budget-copilot-vscode-hook.sh` | `SessionStart`: `{hookSpecificOutput:{additionalContext}}`; also registers | `Stop`: stderr + `exit 2` at STOP (a JSON block is ignored by VS Code); no supervisor — no process to own | `.github/hooks/` is a default hook location, trusted workspace required; `$CLAUDE_PROJECT_DIR` is unset in hook processes |

`stop_hook_active` guards every turn-end hook so a hook-continued turn never
sends a second SIGTERM. Support matrix (a mode is supported once its probe has
passed on the runtime): Claude Code — attended and supervised, verified;
codex and copilot-cli — unverified (logout shape not captured; a logout reads as
a plain quit, and reopening is one command); gemini and copilot-vscode —
attended only.

**Migrating an existing workspace (pre-2026-08-29):** `.claude/settings.json`
used to be a gitignored per-user copy of the example. Pulling the commit that
tracks it silently overwrites the untracked local file. Save yours first
(`mv .claude/settings.json .claude/settings.json.bak`), pull, then fold
personal bits (permissions, MCP servers) into `.claude/settings.local.json` —
never the hook or statusLine blocks.

## Session registration

`register` writes `.context-budget/sessions/<runtime>-<session-id>.json`
(`runtime, session_id, artifact, project, registered_at, user`, plus `pid`,
`pid_start` and `supervisor_pid` when the process walk finds the runtime, and
`parent_session_id`, `depth`, `agent_id` for a child registered by its parent),
pinning the exact artifact — newest-mtime discovery is ambiguous under
concurrent sessions. The session id comes from the runtime's own env var first
(`CLAUDE_CODE_SESSION_ID`, `CODEX_THREAD_ID`, `COPILOT_AGENT_SESSION_ID`,
`OPENCODE_SESSION_ID`, `VSCODE_TARGET_SESSION_LOG` basename; gemini has none →
fixed id `workspace`), else from the artifact path. `check`/`record`
resolve-self: they read only their *own* registry record, never another
session's, and fall back to discovery. Precedence in every command: explicit
`--transcript` > own record > discovery. The Claude Code hook receives the
exact transcript path on stdin, bypassing both.

When `register` can bind a work item (see "Who owns a work item") it also
fills the record's `session` block, stamps `project` on the registry record,
and — for a `/clear` binding — prints the pending prompt on stdout. `release`
(the `SessionEnd` hook, claude) ends the owner's block; `close` is the stop
door. For Claude Code registration is mechanical: the `SessionStart` hook in
the committed `.claude/settings.json` runs `register` with the transcript path
from the payload at every start, resume and clear, and hook stdout is added to
the session context.

### Asking about another session — `check --session-id <sid>`

`check --session-id <sid>` answers about the session **named**, reading its
artifact out of the registry record: exit code and output are that session's.
It never guesses (an unregistered id is refused, exit 3), never writes, and is
`check` only — `register`/`record` refuse the pin. The caller is the
supervisor's watchdog, which asks whether the child it watches is past STOP.

## Ledger

`record` appends one JSON line per measurement to
`.context-budget/context-ledger.jsonl` — the safety net doubles as research
data (token growth per workflow phase, hot workflows, estimate-mode accuracy):

```json
{"ts":"2026-07-22T12:00:00Z","runtime":"claude","session":"<file>","tokens":91000,
 "method":"exact","threshold":150000,"status":"OK","label":"onboard-repo: step 4 done"}
```

The ledger is **gitignored** (machine-local telemetry, same class as
`.gemini/telemetry.log` and the session record): hook appends would
otherwise dirty the tree every session. It is not regenerable — when mining it
for analysis, commit a deliberate dated snapshot (as
`work/context-decay/ledger-analysis.md` did here), never the live append-file.

## Known limitations

- Copilot **VS Code** measurement (`copilot_vscode_measure`) was live-verified
  2026-08-06 (VS Code 1.132.0, chatSessions `promptTokens`), along with the
  agent-mode hooks and `code chat` seeded launch
  (`repos/ai-workspace-template/work/automatic-session-rollover/issues/01-vscode-agent-mode-hooks.md`).
  The CLI adapter was live-verified 2026-08-05 (template deployment; see the
  adapter table above).
- Gemini CLI: the tracked `.gemini/settings.json` enables local-file telemetry
  (`target: local`, no data leaves the machine, `logPrompts: false`), and the
  adapter reads the last response's input-token attribute from
  `.gemini/telemetry.log` (`input_token_count` legacy / `gen_ai.usage.input_tokens`
  semconv) as an exact count. Wiring verified live (a run in this workspace
  produced the log); the parser is fixture-verified for both spellings but not
  yet against a real *successful* Gemini response — blocked on auth on the
  origin machine (personal-OAuth tier discontinued for gemini-cli; needs a
  `GEMINI_API_KEY`, see `docs/operational-knowledge.md`); sessions outside this
  workspace still fall back to the bytes÷4 estimate. The log accumulates across sessions in the workspace,
  so under concurrent Gemini sessions the last entry may belong to the other one.
- Auto-detection (`--runtime auto`) prefers env-var evidence (Claude/Codex) then
  newest artifact — with several runtimes active, `register` or pass `--runtime`.
- The hook checks at most once per minute — a single huge tool result can
  overshoot the threshold between checks.
- Estimates (bytes÷4) drift on binary-heavy or highly-compressed transcripts.
