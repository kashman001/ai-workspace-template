# Phase 5 plan — supervisor with three verdicts, stub-child suite

Ticket: `issues/06-phase-5-supervisor-three-verdicts.md`. Plan of record: the
`**Phase 5 —**` paragraph of `session-management-review-findings.md` (line 801);
the record table's `chain` row and "The supervisor's decision" in
`evaluation/stage3-design-v2.md` (lines 50–58, 68–80) plus the gate table's
two supervisor rows. Builds on phase 3 (`register` binds by
`TF_SESSION_PROJECT` + `TF_SESSION_SEQ`) and phase 4 (`plans/phase-4.md`
"Interface": the launcher writes `staged`, `launch.predecessor`,
`launch.pending`; decisions 4 and 10). Branch `s4-phase-5` from `stage4`
(4bb8a5d), worktree `.claude/worktrees/s4-phase-5` (2026-09-18).

## Tasks

| # | Task | Check |
|---|---|---|
| 1 | Wrap the existing `scripts/session-loop.sh` in `main "$@"` with no other change, its own commit | `test-session-loop.sh` and `test-session-loop-notify.sh` green before and after; `git diff` shows only the wrapper lines |
| 2 | Rewrite `scripts/tests/test-session-loop.sh` against the record: stub children on a throwaway git workspace, one case per verdict and per refusal, pinning exit code + reason code (+ record fields) only | red against the wrapped old supervisor, green after task 3 |
| 3 | Rewrite the body of `session-loop.sh` on the record: start gates, chain budget in `chain`, bootstrap through the launcher, `TF_SESSION_PROJECT`/`TF_SESSION_SEQ` exported, `chain.supervisor` + `chain.used` written before the child, the verdict from `launch.predecessor` / `staged.by` / `seq` before and after | task 2 green |
| 4 | Delete the sentinel, the flush-hash check, the budget/alarm-stop/closed state files, the `.next-command.json` sidecar and `.next-command.stale` handling; delete the launcher's write-only `.session-seq` mirror and the emit `.json` sidecar plus their pins in `test-launch-next-session.sh` / `test-emit-mode.sh` | `grep -rn` over `scripts/` finds no `rollover-complete`, `session-loop.budget`, `alarm-stop`, `chain-closed`, `.next-command.json`, `.session-seq"` writes outside `import-session-seq.sh` (the one-time import) |
| 5 | Every `scripts/tests/*.sh` green with `bash`, `python3 scripts/tests/test-check-ledger.py` green | rc lines in Evidence |

## Interface

`session-loop.sh <project> [--runtime <rt>] [--max-sessions N] [--min-lifetime secs] [--stall-limit N] [--reset-cap] [--reopen] [--relaunch-override]`

Knobs unchanged: `SESSION_LOOP_MAX_SESSIONS`, `SESSION_LOOP_MIN_LIFETIME`,
`SESSION_LOOP_STALL_LIMIT`, `SESSION_LOOP_ALARM`, `SESSION_LOOP_ALARM_MAX`,
`SESSION_LOOP_KILL_AFTER`, `SESSION_LOOP_NOTIFY`, `ROLLOVER_RELAUNCH`.

Exit: 0 chain ended by a verdict (`quit_stop`, `quit_plain`, `cap`) or by the
interactive pause; 1 broken; 3 usage; 4 refused at start. Every line the tests
pin goes to stderr (and the log) in the measurer's shape:

- `session-loop: refused reason=<code> [k=v …] — <remedy>` (exit 4)
- `session-loop: verdict=<code> seq=<n> [k=v …]` (`staged`, `quit_stop`, `quit_plain`, `cap`)
- `session-loop: broken reason=<code> seq=<n> [k=v …] — <remedy>` (exit 1)

### Start, in order (the record read once)

1. `record_unreadable` — the record exists but is not a JSON object; `schema_mismatch` — `.schema != 1`. An absent record is fine: the launcher's bootstrap opens `seq`.
2. `--reset-cap`: refused `supervisor_live` under a live supervisor; else `chain.used = 0`, exit 0 without starting (the old contract; the fleet plan's restart recipe is `--reset-cap` then a plain start).
3. `relaunch_off` — `ROLLOVER_RELAUNCH=off` from the env files without `--relaunch-override`.
4. `chain_closed` — `.chain.closed != null` (`seq=` `at=`); `--reopen` nulls it in the record and proceeds.
5. `supervisor_live` — `.chain.supervisor.pid` alive with the recorded `pid_start` (`pid=`). A stale block is overwritten.
6. `cap` — `chain.used >= cap` is the verdict `cap` (exit 0), before anything is staged.
7. Write `chain.supervisor = {pid, pid_start, started_at}`, `chain.cap`; keep `chain.used`. Also write the `.session-loop` marker (see decision 1).

### Each iteration

1. Re-read the record. `staged == null` → the bootstrap: a DIRECT call of `launch-next-session.sh <p> [--runtime] --emit` (the launcher's `invoked_by_supervisor` tests the strict parent pid); a refusal there is relayed as `session-loop: refused reason=<the launcher's code>` exit 4 (the code is read from the launcher's stderr line; `stage_failed` only if it printed none).
2. `staged != null` and `session != null` → `staged_invalid leg=spent` refusal (exit 4): the successor number already has a registered owner, so the staged command has been run by hand or by another chain (the s18 duplicate-session defect).
3. `chain.used >= cap` → verdict `cap`, exit 0 (the staged command stays for the restart after `--reset-cap`).
4. Consume: one `session_record_update` (precondition `.staged.successor == $seq`) sets `.staged = null`, `.chain.used += 1`; `rm -f work/<p>/.next-command` (decision 2). Export `TF_SESSION_PROJECT`, `TF_SESSION_SEQ`, `TF_SESSION_LOOP=1`, `TF_SESSION_LOOP_PROJECT`. Record `HEAD` and the start instant; start the alarm subshell; `eval` the command in the foreground.
5. Verdict on the re-read record (`record_unreadable` / `schema_mismatch` are broken here):
   - `seq_after == seq + 1` and `launch.predecessor.{seq == seq, disposition == "rolled_over"}` and `staged.by == launch.predecessor.session_id` → `staged` (the child's exit status is ignored: the turn-end hook ends it with TERM). Then `staged_invalid leg=lifetime` if the session ran under `--min-lifetime` seconds; the stall guard.
   - number moved otherwise → `staged_invalid leg=seq`; predecessor wrong → `leg=predecessor`; staged absent → `leg=staged`; `staged.by` wrong → `leg=by`.
   - number unchanged, nothing staged: `rc != 0` → `rc_nonzero`; `session == null` or `session.seq != seq` or `session.registered_at < started` → `no_own_measurement`; the transcript at `session.artifact` ends in a terminal `authentication_failed` → `logout`; else `session.ended.door == "stop"` → `quit_stop`, else `quit_plain`. A quit writes `chain.closed = {at, by_seq, reason}`, exit 0.
6. Stall (hands-off only, `launch.mode`): a session whose commits touched only `work/<p>/README.md`, `next-session.md`, `handoff.md` (and its archive) made no progress; `--stall-limit` consecutive → `stall`.
7. `launch.mode == interactive` → the Enter pause, as today.

### Deleted

`.rollover-complete` (sentinel), the flush-hash check, `.session-loop.budget`,
`.session-loop.alarm-stop`, `.chain-closed`, `.next-command.json`,
`.next-command.stale`, the registry scan (`consumer_since`,
`dead_child_artifact`), and in the launcher the `.session-seq` mirror and the
emit `.json` sidecar (with their pins E5a/E5c/M1f/P1e and E2h/E2j).
`.session-loop.log` stays: it is a log, not state. The launcher's legacy
`.chain-closed` read (gate 2, second leg) is left in place: nothing new
writes the marker, but the old supervisor still running on the main checkout
does when its chain quits, and the read is not this phase's mirror.

The watchdog's pages carry a token the suite greps: `page=unidentified`,
`page=silent`, `page=blocked`, `page=staged_alive`.

## Decisions (Tier 2 candidates; `decisions.md` is off-limits to this agent)

1. **The `.session-loop` marker is still written, beside `chain.supervisor`.** `context-budget.sh supervised` (which this agent may not edit) reads only the marker, and the launcher's `supervised_stage_only` / `no_supervisor` gates and its bootstrap exemption (`invoked_by_supervisor`) read through it. The record's `chain.supervisor` is the supervisor's own liveness authority (`supervisor_live`); the marker is a mirror for the measurer until `supervised` reads `chain.supervisor`. Rejected: dropping the marker (every supervised session would fail `no_supervisor` at its rollover). Reported as a concern.
2. **`.next-command` and `.session-seq.bump.json` stay written by the launcher.** The turn-end self-kill (`scripts/hooks/context-budget-hook-lib.sh`, `budget_hook_should_exit`, phase 6/8's file) reads `.next-command` non-empty and the bump record's `session_id`; the measurer's `successor_advisory` reads `.next-command`. The supervisor reads neither (it consumes `staged` in the record and removes `.next-command` at the consume so the hook's "staged" fact is bounded as before). Only what nothing reads is deleted: `.session-seq` and the emit `.json` sidecar. Rejected: deleting the whole mirror (every supervised session would stay alive after staging, the chain stalls at its first rollover). Reported as a concern.
3. **A spent stage is refused as `staged_invalid leg=spent`, exit 4.** The ticket's code list is closed and `staged_invalid leg=<which>` is its open-ended member; a staged command whose successor number already has a registered owner is a staging the supervisor cannot act on. Rejected: a new code (`stage_spent`); silently discarding and re-staging (the old bootstrap's behaviour — the launcher would then bump past a number a session is running under).
4. **The `--clear` prompt (`launch.pending.prompt`) is not the supervisor's.** `--clear` is the in-place restart of an attended Claude session (`runtime_path_unsupported` off claude); a supervised chain never runs it (`supervised_stage_only` refuses `--clear` under a live supervisor), so there is nothing for the supervisor to inject. Whoever wires the `/clear` seed (phase 7's probes or phase 8's skill) owns the injector. Rejected: the supervisor reading `launch.pending.prompt` and passing it to the child (it never has a pending block to read).
5. **`no_own_measurement` is read from the record, not the registry.** The child's block (`launch.predecessor` on `staged`, `session` on a quit) must carry a `registered_at` not older than the instant the supervisor started it; the registry-record mtime scan is gone. The `--min-lifetime` leg keeps its knob as `staged_invalid leg=lifetime`. Rejected: dropping min-lifetime (a committed knob that quietly does nothing).
6. **The stall guard's bookkeeping set is the three markdown files plus the ledger's archive.** `handoff-archive.md` is where the ledger rotates at a rollover; counting that rotation as progress would let a bookkeeping-only chain pass the guard. Rejected: the counter files (gone) and the record (never committed).
7. **The watchdog stays, reading the record.** The alarm subshell, its backoff, `SESSION_LOOP_KILL_AFTER` and the two pages (past STOP with nothing staged; staged and still alive) are existing behaviour on committed knobs, not a feature of this ticket; the child is identified by `session.pid` (a child of this supervisor) and its transcript by `session.artifact`. The stop flag moves to a `mktemp` path. Rejected: deleting the watchdog with the state files (an unattended chain that hangs at 03:00 would page nobody).
8. **Verdict lines are stderr + log; the exit code and the code are the contract.** Prose stays free-form; `test-session-loop.sh` greps `reason=<code>` / `verdict=<code>` and the exit code, never message text. Rejected: pinning the old halt sentences.
9. **`--reset-cap` stays a standalone operator action (exit 0 without starting).** The fleet plan's recipe and the old contract; the cap is a human checkpoint. Rejected: `--reset-cap` also starting the chain.

## Evidence

Run 2026-09-18 in the worktree (bash 3.2.57), every suite with `bash`, no
`timeout` wrapper. One bash 3.2 parse trap found while writing the body: a
literal `(` before `$(… "?" …)` inside double quotes fails with "unexpected
EOF while looking for matching `'`"; avoided, not worked around.

Suites for this phase: `test-session-loop.sh` **105 passed, 0 failed**
(V1–V4, B1–B7, R1–R8, C1–C2, F1, A1–A4; 394 lines, was 1747; no timing
flake seen in five runs); `test-launch-next-session.sh` **190 passed**
(was 193: E5a/E5c flipped to absence pins, M1f and P1e deleted);
`test-emit-mode.sh` **53 passed** (was 54: E2h flipped, E2j/E2k → one
absence pin); `test-session-loop-notify.sh` unchanged, green. The `main "$@"`
wrapper commit (f771dd4) ran the old suite 222/222 before and after.

Every suite plus the Python ledger check:

```
scripts/tests/test-agent-entrypoints.sh rc=0
scripts/tests/test-attach-session.sh rc=0
scripts/tests/test-check-dependencies.sh rc=0
scripts/tests/test-context-budget-registry.sh rc=0
scripts/tests/test-emit-mode.sh rc=0
scripts/tests/test-fleet-children.sh rc=0
scripts/tests/test-fleet-dispatch-contract.sh rc=0
scripts/tests/test-fleet-dispatch-records.sh rc=0
scripts/tests/test-import-session-seq.sh rc=0
scripts/tests/test-launch-next-session.sh rc=0
scripts/tests/test-link-local-work.sh rc=0
scripts/tests/test-parameterization.sh rc=0
scripts/tests/test-session-lib.sh rc=0
scripts/tests/test-session-loop-notify.sh rc=0
scripts/tests/test-session-loop.sh rc=0
scripts/tests/test-session-numbering.sh rc=0
scripts/tests/test-statusline-context-budget.sh rc=0
scripts/tests/test-template-instantiation.sh rc=0
scripts/tests/test-turn-end-exit.sh rc=0
scripts/tests/test-vendor-budget-hooks.sh rc=0
python3 scripts/tests/test-check-ledger.py rc=0
```

`test-session-lib.sh` S8 and the old D5b-g are the known flakes; neither
fired. `scripts/session-loop.sh` is 381 lines (was 1002).

Record after V1 (a two-session chain that ran to its cap; #8 and #9 each
rolled over through the real launcher, killed by TERM as the hook would):

```json
{"schema": 1, "seq": 10,
 "launch": {"launched_at": "2026-09-18T07:53:16Z", "by": "session", "mode": "handsoff",
            "predecessor": {"seq": 9, "session_id": "sid-9", "registered_at": "2026-09-18T07:53:15Z", "disposition": "rolled_over"},
            "pending": null},
 "session": null,
 "staged": {"successor": 10, "command": "TF_SESSION_PROJECT=testproj TF_SESSION_SEQ=10 claude --name testproj\\ #10 Work\\ item\\ …", "by": "sid-9"},
 "chain": {"supervisor": null, "used": 2, "cap": 2, "closed": null}}
```

Its log (`work/testproj/.session-loop.log`):

```
starting session #8 (1 of 2)
session #8 ended rc=143
verdict=staged seq=8 successor=9 mode=handsoff
starting session #9 (2 of 2)
session #9 ended rc=143
verdict=staged seq=9 successor=10 mode=handsoff
verdict=cap seq=10 used=2 cap=2 — chain cap reached; open a new budget with: scripts/session-loop.sh testproj --reset-cap
```

Record after V2 (#8 registered and quit; `chain.closed` written, `staged`
consumed, `chain.supervisor` cleared at exit):

```json
{"schema": 1, "seq": 8,
 "launch": {…, "predecessor": {"seq": 7, "session_id": "sid-7", …, "disposition": "rolled_over"}, "pending": null},
 "session": {"seq": 8, "runtime": "claude", "session_id": "sid-8", "pid": 63532, "pid_start": "Fri Sep 18 02:53:16 2026",
             "artifact": "<tmp>/transcript-8.jsonl", "registered_at": "2026-09-18T07:53:16Z", "launcher_hash": "seeded", "user": "t", "ended": null},
 "staged": null,
 "chain": {"supervisor": null, "used": 1, "cap": 3, "closed": {"at": "2026-09-18T07:53:16Z", "by_seq": 8, "reason": "quit_plain"}}}
```

Mid-run (the stub's copy of the record while #8 ran, V1k–V1m): `staged`
null, `chain.used` 1, `chain.supervisor` = `{pid, pid_start, started_at}`.

## Concerns for the parent

1. `context-budget.sh supervised` still reads `.session-loop`; the marker is
   written beside `chain.supervisor` until the measurer reads the record
   (decision 1). The ticket's "state files are gone" holds for the budget,
   alarm-stop, closed and sentinel files, not for the marker.
2. `scripts/hooks/context-budget-hook-lib.sh` `budget_hook_should_exit` reads
   `.next-command` + `.session-seq.bump.json`, so the launcher keeps writing
   both (decision 2); the record's `staged.by` is the field it should read.
3. The dangling `.gitignore` lines for the deleted files (`.rollover-complete`,
   `.session-loop.budget`, `.session-loop.alarm-stop`, `.chain-closed`,
   `.next-command.json`/`.stale`, `.session-seq`) are left as they are.
