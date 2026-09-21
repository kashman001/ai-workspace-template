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

(filled at the end)

## Concerns for the parent

(filled at the end)
