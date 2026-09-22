# Phase 7 plan — probes rewritten; acceptance on Claude Code

Ticket: `issues/08-phase-7-probes-and-acceptance.md`. Plan of record: the
`**Phase 7 —**` paragraph of `session-management-review-findings.md` (line 805)
and its phase-table row (line 786: probe scripts live under `evaluation/`);
the probe table in `evaluation/stage2-design-part2.md` (lines 240–254); which
criteria must change in `evaluation/stage3-scenario-evaluation.md` (lines
94–113); `evaluation/stage3-design-v2.md` line 124 (probes are self-checking
scripts; a probe that needs a vendor login gets a stub-runtime twin that is
the CI contract). Builds on phase 4 (launcher on the record) and phase 5
(supervisor with three verdicts; `plans/phase-5.md` decisions 1–3, 5). Branch
`s4-phase-7` from `stage4` (256b36b), worktree `.claude/worktrees/s4-phase-7`
(2026-09-21).

## Tasks

| # | Task | Check |
|---|---|---|
| 1 | Lock fix in `scripts/lib/session-lib.sh` (`_session_record_lock`): a `mkdir` that fails while the lock directory is already gone is a lost race, retried; only a directory that itself refuses (absent, unwritable, or a non-directory at the lock path) is `record_unwritable`. Test first (S10i/S10j in `test-session-lib.sh`), own commit | new tests red before, green after; `bash scripts/tests/test-session-lib.sh` ×5, all rc=0 |
| 2 | Probe scripts under `evaluation/probes/`: `lib.sh` (shared assertions + the retired-file list), `v1-attended-rollover.sh`, `v3-chain.sh`, `v10-fleet.sh`. Each drives its scenario against `--root <workspace> --project <item>` with whatever `claude` is on PATH and checks its own criteria: record fields (`jq`), log `verdict=` codes, exit codes, `check-ledger.py` rc — no prose | each exits 0 iff every criterion holds; the twin suite runs them |
| 3 | Stub runtime + twin suite `scripts/tests/test-probe-twins.sh`: a throwaway git workspace (the `test-session-loop.sh` fixture pattern) with a `claude` shim on PATH whose stub honours the hooks contract (SessionStart → `register`, the turn's **First actions** script, Stop hook → the dispatcher's self-kill, SessionEnd → `release`); runs the three probes unchanged (T1/T3/T10) | suite green; every probe assertion is exercised by the stub |
| 4 | The two suite-level cases, end-to-end, in the twin suite: H1 the staged command run by hand, then a supervisor restart → `refused reason=staged_invalid leg=spent` exit 4, nothing run, staged left in place; H2 the refused hand stage — `--emit` re-run by the session that already staged → `not_owner`, and `--emit` by a second session while the owner is live → `owner_live`; record byte-identical, staged intact | pinned by exit code + reason code + `cmp` |
| 5 | Mirror decision: left to phase 8 (decision 5) — no measurer/hook/launcher edits this phase | `git diff stage4 --stat` touches only the lib, tests, probes, this plan |
| 6 | Claude Code acceptance in a clone of this branch (decision 3): (a) `v1-attended-rollover.sh` with the real `claude`; (b) `v3-chain.sh --max-sessions 2` under `expect` | record contents, log verdict lines and rc lines in Evidence; no stray `claude` process afterwards |
| 7 | Every `scripts/tests/*.sh` with `bash`, `python3 scripts/tests/test-check-ledger.py` | rc lines in Evidence |

## Interface

`evaluation/probes/<probe>.sh --root <workspace-root> --project <item> [--runtime claude] [--keep]`
plus per probe: `v3-chain.sh --max-sessions <N>` (default 2); `v10-fleet.sh
--parent-session <sid>` (the registered parent whose subagent transcripts
`fleet.sh children` sweeps; the twin fabricates them under a fake `HOME`).
Exit 0 pass / 1 a criterion failed (each printed as `FAIL: …`) / 3 usage.
The probes seed the item (`README.md`, `next-session.md`, `handoff.md` with a
`# Session Handoff — 1` block) when it is empty and leave it in place for
inspection unless the caller cleans up; `session-state.json` is removed before
a run so each run opens its own record.

What a session does in every probe is one script, `work/<p>/session-turn.sh`,
named under **First actions** in `next-session.md`: bind the item if the
record does not already name this session (`register --project`), append the
ledger block for this session's number, rewrite `next-session.md` for the
successor, then `launch-next-session.sh <p>` — `--emit` under a supervisor
(`TF_SESSION_LOOP=1`), attached otherwise (from a tool shell that prints the
`run:` line, which V1 then executes as the successor). The model's part is to
run that script and reply; the scripts under test get a real identity, real
hooks and a real transcript.

## Decisions (Tier 2 candidates; `decisions.md` is off-limits to this agent)

1. **The probes are driver scripts sharing one assertion library; the twin is the same script under a stub `claude` on PATH.** `test-probe-twins.sh` calls `evaluation/probes/v*.sh` unchanged with the shim first on PATH, so the CI contract and the acceptance run are literally the same assertions. Rejected: a twin suite with its own copy of the checks (the two drift, and the acceptance stops proving what CI proves).
2. **The stub runtime honours the hooks contract instead of writing the record itself.** It runs `context-budget.sh register` at start (SessionStart), the First-actions script as its "turn", the Stop hook through the real dispatcher (`context-budget-stop-hook.sh claude`, which TERMs the stub when it staged under a supervisor), and `release` at exit. Rejected: `test-session-loop.sh`'s stub, which writes the `session` block directly — it never exercises the measurer, the hook dispatcher or the self-kill, and those are exactly what a chain probe must cover.
3. **The acceptance workspace is a `git clone` of this branch under the scratchpad, not `$WT/work/s4-scratch/`.** The launcher, supervisor, measurer and fleet script resolve their root through `git rev-parse --git-common-dir`, so from the worktree every one of them drives the MAIN checkout's `work/` (only the hook lib honours `WORKSPACE_ROOT`); a clone has its own `.git`, so the same commit's scripts drive the clone's `work/s4-scratch/`. The clone's HEAD is recorded in Evidence and equals the branch commit under test. Rejected: an env override in the scripts (out of this phase's files, and it would change the worktree semantics phase 4 pinned); creating the item in the main checkout (the live supervisor and the parent's hooks run there).
4. **Attended sessions are driven with `claude -p … --allowedTools Bash,Read` ; the chain's children run exactly as the launcher wrote them, under `expect`.** In V1 the launcher's attached path prints the `run:` line from a tool shell; the probe executes that command with `-p` appended so it runs headless — the env pair, cwd, `--name` and prompt are the launcher's, and registration binds through the real SessionStart hook. In V3 the supervisor `eval`s the staged TUI command itself, so the supervisor runs under `expect` (a pty) with a scratch-local `.claude/settings.local.json` allowing the tools. Rejected: expect-driving the V1 TUI (permission dialogs to answer, nothing gained — identity, hooks and transcript are the same in `-p`); editing the staged command (it is the contract under test).
5. **Mirror removal is left to phase 8.** The `.session-loop` marker has a third reader outside the places this agent may edit: the launcher's `invoked_by_supervisor` (gate 6's bootstrap exemption reads the marker's `pid`); deleting the write without moving that read breaks every bootstrap (F1). `.next-command` is also `--emit`'s output contract (`test-emit-mode.sh` E1–E10), not only the hook's mirror, so a half removal (bump + emit file) would still leave the marker and rewrite two suites. The exact places phase 8 must touch are listed under Concerns. Rejected: taking the removal now (a wider edit than the dispatch allows, and the acceptance below should measure the code as phase 5/6 merged it).
6. **V3 passes on three script facts.** The chain verdicts from the log (`verdict=staged` per session, then `cap` or `quit_*`), `chain.used` and `staged`/`chain.closed` in the record, and the supervisor's exit code; the prose `successor: NOT STAGED` is not read. Rejected: grepping the child's transcript for the advisory line (free-form by design).
7. **V10 asserts the absence of the child-lock gate.** With two dispatch generations open (`dispatch-list` rc 1), the parent's rollover through the launcher must succeed (rc 0, `launch.predecessor.disposition = rolled_over`); then `dispatch-close` + `dispatch-open` yields generation 2 and `children --parent-session` measures both children. Rejected: keeping a "children drained" precondition in the probe (decision 11 of the stage-3 review deleted the gate).
8. **The lock fix retries only a lost race.** `mkdir` failed and no lock directory exists → if the record's directory exists and is writable and nothing non-directory sits at the lock path, retry (bounded by the same wait budget); otherwise `record_unwritable` as before. Rejected: an unconditional retry (an absent directory would spin to `lock_timeout` with a misleading code).
9. **The two suite cases are end-to-end runs; R6/R7 stay.** H1 runs the launcher-written staged command by hand (a real registration of the successor number), then starts the supervisor; H2 pins which launcher gate refuses a hand `--emit` that the record contradicts — `not_owner` for the session that already staged (its number's `session` is null and it is no longer the owner), `owner_live` for a stranger while the owner is alive; `no_supervisor` is the third leg, already R7. Rejected: a new supervisor code for the hand-run stage (phase-5 decision 3: `staged_invalid leg=spent` is the code).

## Evidence

Run 2026-09-21/22 in the worktree (bash 3.2.57, `claude` 2.1.278), every
suite with `bash`, no `timeout` wrapper. Commits on `s4-phase-7`: 54b623c
(plan), fae4746 (lock fix), 30f2632 (probes + twins), f2cebb2 (trust-dialog
pattern), then this one.

### The lock fix (task 1)

S10i/S10j red on the old loop (`record_unwritable`, seq unchanged), green
after; S10l–S10q pin the two refusals that stay (absent directory, a file at
the lock path) and that the absent directory refuses at once. Five runs:

```
run 1: scripts/tests/test-session-lib.sh rc=0 test-session-lib: 64 passed, 0 failed
run 2: scripts/tests/test-session-lib.sh rc=0 test-session-lib: 64 passed, 0 failed
run 3: scripts/tests/test-session-lib.sh rc=0 test-session-lib: 64 passed, 0 failed
run 4: scripts/tests/test-session-lib.sh rc=0 test-session-lib: 64 passed, 0 failed
run 5: scripts/tests/test-session-lib.sh rc=0 test-session-lib: 64 passed, 0 failed
```

### Twins (tasks 3–4)

`test-probe-twins.sh` **37 passed, 0 failed**, three consecutive runs plus
the full-suite run: T1 (V1 under the stub: 18 criteria; #1 opened the record
by an explicit `register`, #2 bound `via=env (filled)` through the SessionStart
hook, `release --quiet` set `ended.at`), T3 (V3 to the cap and to a quit: both
children ended `rc=143` by the dispatcher's self-kill, "terminating claude
session" in the hook output), T10 (V10: 19 criteria), H1 (the launcher-written
staged command run by hand registered #2; a supervisor restart exits 4 with
`refused reason=staged_invalid leg=spent`, ran nothing, left `staged` intact,
cleared `chain.supervisor`), H2 (`--emit` again by the session that staged →
4 `not_owner`; `--emit` by a stranger while a fresh transcript makes the owner
live → 4 `owner_live`; record byte-identical both times).

### Claude Code acceptance (task 6)

Workspace: `git clone` of this branch at f2cebb2 under the scratchpad
(`…/scratchpad/s4-accept`, `git rev-parse HEAD` equal to the worktree's),
item `work/s4-scratch/` (untracked, never committed), a local
`.claude/settings.local.json` allowing `Bash(bash work/s4-scratch/session-turn.sh:*)`
and `Read`. Login proven first: `claude -p "Reply with exactly: ok"` from the
worktree → `ok`, rc 0. Every session was driven without a human: V1's two
sessions with `claude -p … --allowedTools …`, V3's two children exactly as
the launcher staged them (TUI), under `expect`.

**V1 attended rollover — `v1-attended-rollover.sh --root <clone> --project s4-scratch`: 18 passed, 0 failed, rc 0.**
Session #1 (sid `9409f261-…`) bound the item by `register --project`, wrote
block 1 and the launcher for #2, and ran the launcher attached from its tool
shell; the launcher's log:

```
project=s4-scratch runtime=claude mode=manual path=exec seq=2
record: seq 1 -> 2, predecessor=rolled_over, by=session (work/s4-scratch/session-state.json)
not an interactive terminal — run this in one:
run: TF_SESSION_PROJECT=s4-scratch TF_SESSION_SEQ=2 claude --name s4-scratch\ #2 Work\ item\ s4-scratch\ -\ rollover\ session\ #2.\ Read\ \`work/s4-scratch/next-session.md\`\ and\ continue\ from\ \*\*First\ actions\*\*.
```

The probe ran that line (`-p` and the tool list appended) as session #2
(sid `03fba971-…`), which registered by the env pair, wrote block 2 and
stopped. Record after V1:

```json
{"schema":1,"seq":2,
 "session":{"seq":2,"runtime":"claude","session_id":"03fba971-45fd-49e2-8c8f-5318a6938d4d","pid":61322,"pid_start":"Mon Sep 21 18:51:51 2026",
            "artifact":"~/.claude/projects/…-s4-accept/03fba971-45fd-49e2-8c8f-5318a6938d4d.jsonl","registered_at":"2026-09-21T23:51:51Z",
            "launcher_hash":"a543818d13ff…","user":"kashif@…","ended":{"at":"2026-09-21T23:55:50Z"}},
 "launch":{"launched_at":"2026-09-21T23:51:49Z","by":"session","mode":"handsoff",
           "predecessor":{"seq":1,"session_id":"9409f261-7282-458f-8bc3-b54bc24d8ba7","registered_at":"2026-09-21T23:51:49Z","disposition":"rolled_over"},
           "pending":null},
 "staged":null}
```

Ledger: `# Session Handoff — 2 …` over `# Session Handoff — 1 …`;
`check-ledger.py work/s4-scratch` rc 0; files under `work/s4-scratch/`:
`.probe-stop-at .session-seq.bump.json README.md handoff.md launcher-1.log
next-session.md session-1.out session-2.out session-state.json
session-turn.sh turns.log` — no retired name. Both sessions replied `done`.

**V3 supervised chain — `v3-chain.sh --root <clone> --project s4-scratch --driver expect --max-sessions 2`: 15 passed, 0 failed, rc 0** (the supervisor's own exit 0). `work/s4-scratch/.session-loop.log`:

```
2026-09-22T00:00:10Z staging the first session
2026-09-22T00:00:10Z starting session #1 (1 of 2)
2026-09-22T00:00:27Z session #1 ended rc=143
2026-09-22T00:00:27Z verdict=staged seq=1 successor=2 mode=handsoff
2026-09-22T00:00:27Z starting session #2 (2 of 2)
2026-09-22T00:05:54Z session #2 ended rc=143
2026-09-22T00:05:55Z verdict=staged seq=2 successor=3 mode=handsoff
2026-09-22T00:05:55Z verdict=cap seq=3 used=2 cap=2 — chain cap reached; open a new budget with: scripts/session-loop.sh s4-scratch --reset-cap
```

Both children were real TUI sessions (sids `4535d67b-…`, `7b262be0-…`),
each ended by the turn-end hook after its `--emit` (rc 143). Record after V3:

```json
{"schema":1,"seq":3,
 "chain":{"supervisor":null,"used":2,"cap":2,"closed":null},
 "launch":{"launched_at":"2026-09-22T00:05:52Z","by":"session","mode":"handsoff",
           "predecessor":{"seq":2,"session_id":"7b262be0-97bd-4798-a31e-da21fce75621","registered_at":"2026-09-22T00:00:27Z","disposition":"rolled_over"},
           "pending":null},
 "session":null,
 "staged":{"successor":3,"command":"TF_SESSION_PROJECT=s4-scratch TF_SESSION_SEQ=3 claude --name s4-scratch\\ #3 Work\\ item\\ s4-scratch\\ -\\ rollover\\ session\\ #3.\\ …","by":"7b262be0-97bd-4798-a31e-da21fce75621"}}
```

`staged.by == launch.predecessor.session_id`; ledger blocks 2, `check-ledger.py`
rc 0; no retired file. The folder-trust dialog was answered once by the
driver before the chain (Concern 4); no `claude`, `expect` or supervisor
process was left running after either run (`ps` checked). The clone stays in
the scratchpad for inspection; nothing under it was committed.

### Every suite (task 7)

```
scripts/tests/test-agent-entrypoints.sh rc=0
scripts/tests/test-attach-session.sh rc=0
scripts/tests/test-check-dependencies.sh rc=0
scripts/tests/test-context-budget-registry.sh rc=0
scripts/tests/test-emit-mode.sh rc=0                 (53 asserts)
scripts/tests/test-fleet-children.sh rc=0
scripts/tests/test-fleet-dispatch-contract.sh rc=0
scripts/tests/test-fleet-dispatch-records.sh rc=0
scripts/tests/test-import-session-seq.sh rc=0
scripts/tests/test-launch-next-session.sh rc=0       (190 asserts)
scripts/tests/test-link-local-work.sh rc=0
scripts/tests/test-parameterization.sh rc=0
scripts/tests/test-probe-twins.sh rc=0               (37 asserts, new)
scripts/tests/test-session-lib.sh rc=0               (64 asserts, was 55)
scripts/tests/test-session-loop-notify.sh rc=0
scripts/tests/test-session-loop.sh rc=0              (105 asserts)
scripts/tests/test-session-numbering.sh rc=0
scripts/tests/test-statusline-context-budget.sh rc=0
scripts/tests/test-template-instantiation.sh rc=0
scripts/tests/test-turn-end-exit.sh rc=0             (5 asserts, no skips)
scripts/tests/test-vendor-budget-hooks.sh rc=0
python3 scripts/tests/test-check-ledger.py rc=0
```

`git diff --stat stage4..s4-phase-7`: `scripts/lib/session-lib.sh` (+12/−2),
`scripts/tests/test-session-lib.sh` (+20), `scripts/tests/test-probe-twins.sh`
(new, 174), `evaluation/probes/{lib,v1-attended-rollover,v3-chain,v10-fleet}.sh`
(new), this plan. No measurer, hook, launcher or supervisor edit.

## Concerns for the parent

1. **Mirror removal, for phase 8 (decision 5).** The exact places, with their
   readers: (a) `.session-loop` — written by `session-loop.sh` (after the
   `chain.supervisor` write) and removed in `cleanup`; read by
   `context-budget.sh cmd_supervised` and by the launcher's
   `invoked_by_supervisor` (gate 6's bootstrap exemption compares the marker's
   `pid` to `$PPID`), pinned by `test-session-loop.sh` V1n, R7,
   `test-launch-next-session.sh` (B series, `LOOPF`), `test-emit-mode.sh`
   (`LOOPF`), `test-context-budget-registry.sh` (`LOOPF`, `S1LOOP`); the
   record's `chain.supervisor.{pid,pid_start}` carries the same facts.
   (b) `.next-command` + `.session-seq.bump.json` — written by the launcher's
   `--emit`; read by `budget_hook_should_exit` (`.next-command` non-empty and
   the bump's `session_id` == mine) and by `successor_advisory`
   (`.next-command` non-empty); pinned by `test-vendor-budget-hooks.sh`
   (lines ~488–489), `test-emit-mode.sh` (E2m/E2n on the bump, the `EMITF`
   pins), `test-launch-next-session.sh` (line ~127), `test-session-loop.sh`
   (the `reset` cleanup); the record's `staged.by` and `staged != null` carry
   the same facts. `.next-command` is also `--emit`'s user-visible output.
2. **The acceptance ran in a clone, not in `$WT/work/s4-scratch/`** (decision
   3): every script resolves its root through `git rev-parse --git-common-dir`,
   so from the worktree the supervisor and launcher would have driven the main
   checkout's `work/`. The clone's HEAD equals the branch commit under test
   (Evidence). The item was never committed anywhere.
3. **A supervised session's tool shells inherit the chain env.** This agent's
   shell carried `TF_SESSION_LOOP=1 TF_SESSION_LOOP_PROJECT=template-improvement-review`
   from the parent's live chain, so a hand `--emit` from inside it is refused
   `no_supervisor` (correct for the chain, surprising for a probe run from a
   subagent). The probe lib and the twin suite unset the four `TF_SESSION_*`
   variables; nothing in the scripts changed. Worth a line in the phase-8 docs.
4. **The folder-trust dialog.** A real TUI child in a folder Claude Code has
   not seen refuses to start until the dialog is answered; `claude -p` neither
   shows nor records it (`hasTrustDialogAccepted` stayed null after V1). The
   probe driver answers it (Down, Enter), and its words arrive interleaved
   with cursor escapes, so the match is `safety.{0,20}check`, not the literal
   text. Any future fresh-clone chain needs the same one-time answer.
