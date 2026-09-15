# Stage 3 — scenario and loop evaluation of the Part 2 design (2026-09-15)

> Fresh reviewer, disk only. Design under review: `evaluation/stage2-design-part2.md` (= findings Part 2). Inputs: findings §3 (S1–S10), §1b.5 (17 decisions), §1b.7 (binding), Stage 1 §0/§B/§D, `evaluation/stage2-probes.md`. Script lines were read only where Part 2 cites them (cb/launch/loop/hook-lib), plus `capture-rollover-options.sh:69` and `launch:351-358` to settle two rows below. Labels: **M** = mechanical (script-gated, evidence written), **AT** = agent-trusted (a §1b.7 violation if load-bearing), **UD** = Part 2 is silent or inconsistent. Weighed throughout against the user's one finding, "it is just too long": every mechanism must be earned by a scenario, a loop step or §1b.7.

## 1. Loop walks

### 1.1 MEASURE

| # | Step | Writer → field | Gate for the next step | Label |
|---|---|---|---|---|
| M1 | runtime fires `session-start` → dispatcher → `cb register` | registry record; `session` block filled/adopted (b, e) or project-less | none (measurement never blocks); rollover verbs later refuse `not_owner` | M |
| M2 | `turn` → `cb check` | per-session `.stamp`/`.status` (hook-lib:44-52 kept) | exit 0/1/2; throttled by `CHECK_EVERY` | M |
| M3 | WARN/STOP transition (hook-lib:70-71) → in-band text + ledger line `escalation:<status>` | `handoff.md` append by hook-lib (decision 14) | — | M |
| M4 | agent *begins* the rollover at STOP | — | nothing mechanical in unsupervised mode; supervised: alarm page `past_stop_unstaged` (P4a) summons a human | **AT** — unavoidable without a blocking hook; accept and state it (Stage 1 I2 said the same) |
| M5 | ad-hoc start: agent runs `register --project p` (record-less item opens `seq = ledger-top+1 \| 1`, `launch.by=adhoc`) | `seq`, `session` | if skipped, `rollover-start`/launcher refuse `not_owner` with the remedy | AT-but-gated (allowed by §1b.7's last bullet) |
| M6 | `session-end` → `cb release` | registry cleanup; `session.ended.reason` (advisory) | none reads it | M (field is dead weight — cut list C5) |

Note on M5: `seq` gains a second writer (`register`), contradicting the "single writer" column of table (b). Harmless but should be stated as the one exception in the lib helper, not a footnote.

### 1.2 ROLLOVER (attended S1, hands-off S2, and the supervised child's half of S3)

| # | Step | Writer → field | Gate for the next step (`reason=`) | Label |
|---|---|---|---|---|
| R1 | `rollover-prep.sh p` → `cb rollover-start --project p` | `session.rollover={started_at, ledger_hash, launcher_hash}`; `options`; archive rotated | `verify` refuses `prep_missing`; refuses `not_owner` | M — but see **trap T1** |
| R2 | agent writes `handoff.md` top block `# Session Handoff — N` | file | `verify`: `ledger_seq_mismatch`, `ledger_shape` (check-ledger.py), `ledger_unchanged` | AT, script-verified (allowed) |
| R3 | agent replaces `next-session.md` (continue door) | file | `verify`: `launcher_unchanged` | AT, script-verified (allowed) |
| R4 | `cb verify --project p --door continue\|stop` | `session.verified_at` | launcher/`close` refuse `unverified` unless `verified_at > rollover.started_at` | M — but see **trap T2** |
| R5 | agent runs `opts-sync` | `options` | `options_invalid` only | AT, not load-bearing (cut list C3) |
| R6 | agent picks `--loop-mode interactive\|handsoff` | `launch.mode` | none | AT, not integrity-bearing (a wrong `handsoff` idles at a prompt; KILL_AFTER=0 so nothing dies) — accept |
| R7 | `launch-next-session.sh p [--emit\|--clear\|--bg\|bare]` — bump | `seq+1`, `launch` (predecessor disposition from the old `session`), `session=null`, `staged` (emit) or `launch.pending` (clear/bg/exec) | refusals (h): `unverified`, `not_owner`, `owner_live`, `chain_closed`, `supervised_stage_only`, `staged_unconsumed`, `runtime_path_unsupported`, `pending_elsewhere`, `worktree_unsynced` | M |
| R7' | CL-3 stale-launcher guard (launch:351-390, git `rev-list --all --not HEAD`) | — | Part 2 names only `worktree_unsynced` (L33); the CL-3 git freshness guard is not in (h), (j) or the code list | **UD** — Stage 1 E16 row says it must survive; needs a code (`launcher_stale`) |
| R8 | turn-end hook (supervised): dispatcher reads `staged.by.session_id == mine` → `kill -TERM $PPID` | — | today gated by `TF_SESSION_LOOP=1` (hook-lib:121); Part 2 (b) row 84 gates on `staged.by` only | **UD** — nothing says `--emit` without a live supervisor is refused or that the hook checks `chain.supervisor` liveness; a hand-run `--emit` would self-kill with nobody to launch N+1 (strands as `staged_unconsumed`) |
| R9 | successor `register` binds: env (`TF_SESSION_PROJECT`/`_SEQ`, exec/eval), pid (`--clear`, probe A), freshest unexpired `pending` (`--bg`, probe B) | `session` filled; `pending` nulled | `pending_mismatch`, `pending_expired`, `owner_live` | M for exec/eval/clear; **heuristic** for `--bg` (rule 4 is a scan; the `pending_elsewhere` refusal narrows it but a scan is still a guess) |
| R10 | stop door: `cb close --project p` | `session.ended={at, door:stop}` | refuses `unverified`; next launch classifies `stopped` | M; skipping it costs only `abandoned`+brief at the next launch |

**Trap T1 (ordering).** `ledger_unchanged`/`launcher_unchanged` compare against hashes taken at `rollover-start`. An agent that writes the ledger block *before* running prep (common: "write while it's fresh") gets `ledger_unchanged` and cannot clear it by re-running prep (prep re-hashes the already-written file). The only exit is a spurious second edit. `ledger_seq_mismatch` (top block == `seq`) is already the real evidence; the hash test adds a trap and nothing else.

**Trap T2 (stamp vs. state).** `verified_at` is a stamp: after `verify` passes the agent can still edit `handoff.md` (e.g. fix a heading, breaking shape) and launch — the launcher trusts the stamp. §1b.7's own pattern ("the script verifies the artefact afterwards and blocks the launch") is satisfied more simply and more strictly if the launcher and `close` run the artefact checks inline at the moment of the bump, with a `--check` dry-run for the agent. That removes `rollover-start`, `verify`, `session.rollover`, `verified_at`, `prep_missing`, `unverified`, `ledger_unchanged`, `launcher_unchanged` and both traps. "Changed since session start" (the launcher must be *replaced*) is then one hash captured by `register` when the session acquires its project (`session.launcher_hash`). See amendment A3.

### 1.3 SUPERVISE (`session-loop.sh`, S3)

| # | Step | Writer → field | Gate (`reason=` / verdict) | Label |
|---|---|---|---|---|
| L1 | `record_read` | — | `record_unreadable`, `schema_mismatch`, `chain_closed` (unless `--reopen`), `supervisor_live`, `relaunch_off` | M |
| L2 | write `chain.supervisor={pid,pid_start,started_at}`; trap clears on EXIT | `chain` | — | M |
| L3 | `chain.used ≥ cap` | — | `verdict=cap`, exit 0 | M |
| L4 | bootstrap: `staged ∧ session.seq == staged.successor` → `staged_spent`, clear; `staged` absent → launcher `--emit --loop-mode m` tagged `by=supervisor` | `staged`, `seq+1`, `launch` | launcher refusals propagate as `broken` | M — but **UD**: which launcher gates apply to a bump whose caller is not a session? `unverified`/`not_owner` cannot (no session, no rollover in flight); `owner_live` must. Part 2 does not say. Amendment A3 gives the rule: artefact gates fire iff `launch.by == session`. |
| L5 | read `staged.command` → clear `staged` → hash `next-session.md`/`handoff.md` → `chain.used+1`, `last_seq` → export env → alarm subshell → `eval` | `staged=null`, `chain` | — | M; **UD**: `TF_SESSION_SEQ` must be exported per iteration (today `TF_SESSION_LOOP_PROJECT` is exported once, loop:436) — one line, but say it |
| L6 | alarm probe captures `child = R.session` once the successor registers | — | pages `past_stop_unstaged`, `staged_still_alive` (both modes), `silent`/`killed_silent` (handsoff only) | M for pages; **UD/race** for the capture — a sampled snapshot is load-bearing for L8 (see below) |
| L7 | child's rollover: `--emit` bumps `seq`, nulls `session`, writes `staged.by={sid of N+1}`; turn-end hook SIGTERMs; rc 143 | — | — | M |
| L8 | verdict **staged**: `R.staged.by.session_id == child.session_id ∧ R.seq == seq_before+1 ∧ hashes changed ∧ R.session.registered_at > R.launch.launched_at ∧ R.session.seq == seq_before` | — | `staged` | **UD — inconsistent**: after L7 `R.session` is `null` (b row 83, "slot released at the bump") and `R.launch.launched_at` is the *new* launch's time, so the last two conjuncts cannot be evaluated from R as written; row 85 ticks them anyway. The only source is the alarm snapshot (L6), which can miss a child that registers and rolls over between ticks (the first-turn spurious-STOP shape, loop:945-947) → false `staged_by_mismatch`/`no_own_measurement`. |
| L9 | verdict **quit**: `R.staged == null ∧ R.seq == seq_before ∧ rc == 0 ∧ logout ≠ yes` | `chain.closed={at, by_seq, reason}` | `quit_stop`/`quit_plain` (+`logout=unknowable` on codex/copilot-cli) | M; **gap**: a child that never registered (hook failed, trust dialog) and exited 0 reads as `quit_plain` and *closes the chain*; add `R.session != null ∧ R.session.seq == seq_before` else `no_own_measurement` |
| L10 | verdict **broken**: anything else | `chain` untouched (`logout` refunds `used`) | exit 1 | M |
| L11 | interactive pause (loop:982-996 kept) | — | `pause_interrupted`, exit 0 | M |

**Fix for L8 (amendment A1):** the bump already writes `launch.predecessor={seq, runtime, session_id, disposition}` from the old `session`; add `registered_at` to it. The staged verdict then reads only script-written record fields: `R.launch.predecessor.session_id == child_sid_from_env_or_predecessor ∧ R.launch.predecessor.seq == seq_before ∧ R.launch.predecessor.registered_at > R_before.launch.launched_at ∧ R.launch.predecessor.disposition == rolled_over ∧ R.staged.by.session_id == R.launch.predecessor.session_id`. The alarm snapshot stops being load-bearing (stall pages only). `hashes changed` is redundant with the launcher's artefact gate (cut list C4).

## 2. Scenario matrix

| Row | Verdict | Failing step / note |
|---|---|---|
| S1 keyboard rollover | **YES** | R1–R7 mechanical; T1/T2 are usability traps, not integrity holes |
| S2 hands-off self-roll | **PARTLY** | `--clear`: YES (probe A, pid binding). `--bg`: R9 rule 4 is a freshest-unexpired scan — the last heuristic binding in the design; see Q2 |
| S3 overnight chain | **PARTLY** | L8 verdict reads `R.session` after the bump nulled it; L6 snapshot race; L4 bootstrap gate set undefined. All fixable by A1/A3, none structural |
| S4 two sessions, one repo | **YES** | `owner_live` → non-owner; `adopted_resume` on dead owner; no roles (V7) |
| S5 worktrees | **YES** | record on `WORKSPACE_ROOT`; `worktree_unsynced` kept; M16 re-pin kept |
| S6 exit/crash/logout/resume | **PARTLY** | crash → `rc_nonzero`, restart → `abandoned`+N+1: YES. Plain exit/stop door: YES. Resumed predecessor: `staged_unconsumed`/`--unstage`: YES. Logout: claude YES; codex/copilot-cli close the chain as `quit_* logout=unknowable` (design admits). R8 hand-run `--emit` strands: UD |
| S7 non-claude runtime | **PARTLY** | by construction "unverified → V9"; codex/copilot register project-less until the agent runs `register --project` (M5); gemini attended-only. Nothing in Part 2 blocks V9; nothing proves it |
| S8 fleet + parent rollover | **YES** | isolated; drain is a fleet-doc step, not a gate — correct under §1b.7 because the dispatch contract survives without it (g). V10's criteria must change (§3) |
| S9 clean clone | **YES** | `jq` req, `manual` root default, V11/V12 |
| S10 second person | **N/A** | explicit non-goal (l); record gitignored + `user` kept, so not made worse |
| E1 instantiate | **PARTLY** | unchanged; the local-vs-clone contradiction is outside this design (Stage 1 said the same) |
| E2 team repo | **NO** | unchanged non-goal; gitignored record keeps it no worse |
| E5 onboard machine | **PARTLY** | (i) doc set has no row for `docs/runbooks/` (jq, codex trust, copilot `trustedFolders`, gemini auth) — the row Stage 1 E5 asked for |
| E6 personal tooling | **YES** | one dispatcher; vendor wiring files stay |
| E9 start a work item | **YES** | no record → first bump mints 1; ad-hoc M5 opens it |
| E11 checkpoint & resume | **YES** | stop door = `close` + `quit_stop`; two-doors doc rewritten (i) |
| E12 finish a branch | **YES** | ff-push unchanged |
| E13 wayfinder cadence | **YES** | untouched |
| E16 many sessions (CL-1/2/3) | **PARTLY** | CL-1 stamp keying kept (hook-lib:44-52); CL-2 M16 kept; CL-3 git freshness guard (launch:351-390) **unnamed** (R7') |
| E17 multiple people | **N/A** | non-goal |
| I1 measure from disk | **PARTLY** | adapters unverified off claude; probe A's two claude caveats recorded in (e) |
| I2 act on WARN/STOP | **PARTLY** | M4 stays instruction-only unsupervised; supervised has P4a. Accept, state in doc |
| I3 roll over | **YES** | every step a verb with a code |
| I4 number sessions | **YES** | never-reclaim, ADR-0010; `seq` second writer (M5) to be stated |
| I5 concurrent sessions | **YES** | = S4 |
| I6 fleet | **PARTLY** | E2E still V10; child-lock gate deleted so V10 shrinks |
| I7 in-band delivery | **PARTLY** | copilot `trustedFolders` still a silent no-op (runtime limit) |
| I8 work-item files healthy | **YES** | ledger/launcher checks + check-ledger.py |
| I10 scaffold & self-checks | **YES** | V11 extends `test-template-instantiation.sh` |

Counts (30 rows): YES 15 · PARTLY 12 · NO 1 (E2, unchanged non-goal) · N/A 2 (S10, E17 non-goals).

## 3. Verification — can each §D probe still run as a self-checking script?

| Probe | Runnable under Part 2 | Note |
|---|---|---|
| V1 | yes | assertions are `jq` on the record + `check-ledger.py` rc. The "one human paste" can go: probe A's `expect` driver (`drive.exp`) already scripts a full claude TUI session, so V1/V2 can be fully unattended — recommend it, it is what §1b.7 "reproducible" asks |
| V2 | yes (done once) | `pending.prompt` null, new sid/JSONL |
| V3 | yes, **one criterion must change** | §D pins the prose `successor: NOT STAGED` (free-form by decision 13). Replace with: child `.status` reaches STOP before `staged` is written (two script facts) |
| V4 | yes | `rc_nonzero`, `chain.closed == null`, restart → `abandoned` |
| V5 | yes | `quit_*`, `chain_closed`, `--reopen` |
| V6 | yes (fixture) | add a codex fixture asserting `quit_plain logout=unknowable` so the gap has a test |
| V7 | yes | `owner_live`, `not_owner`, `adopted_resume` |
| V8 | yes | record in main checkout only |
| V9a–c | yes, vendor gates | unchanged |
| V9d | yes | `test-turn-end-exit.sh --live` |
| V10 | yes, **criteria must change** | "live child lock blocks pre-release (launch:863-867)" is deleted by decision 11; "successor re-dispatches with the read-the-report clause" is agent prose. Self-checkable core: `dispatch-list` rc 1 before, gen-2 records after, `children` measures both |
| V11 | yes | unchanged |
| V12 | yes | add `verify`, `rollover-start`, `.session-loop`, `--emit`-era names to the retired list if A3 lands |
| V13 | yes | `staged_unconsumed`, `--unstage` → `abandoned`, N+2 |

**Probes Part 2 needs that §D/§(j) lack** (suite-level unless noted): `staged_spent` bootstrap (supervisor restart after a hand-run staged command); `--bg` `pending_elsewhere` (only if `--bg` survives Q2 — no live probe exists for `--bg` at all, which is itself evidence for cutting it); `schema_mismatch` under a live old-code supervisor (the S3 residual); the R8 unsupervised `--emit` self-kill refusal (once defined); `--takeover` both paths; alarm pages P4a/P4b firing (V3 only checks their *absence*); the one-time `seq` import from `.session-seq` (the flag-day on this repo is the live test — script it before, not after). No §D probe becomes impossible.

## 4. Cut list — mechanisms no scenario, loop step or probe requires

| # | Cut | What breaks |
|---|---|---|
| C1 | `rollover-start` + `verify` verbs, `session.rollover`, `verified_at`, codes `prep_missing`/`unverified`/`ledger_unchanged`/`launcher_unchanged`; launcher and `close` run the artefact checks inline, `--check` dry-run for the agent, `launcher_hash` taken at `register` | nothing; removes traps T1/T2 and two agent-facing steps. `rollover-prep.sh` stays as the archive-rotation helper (non-gated) |
| C2 | `--bg` path: `pending.expires_at`, register rule 4, `pending_elsewhere`, `pending_expired`, launcher `--bg`; `pending` becomes `{pid, pid_start, prompt}` for `--clear` only, no TTL (pid liveness is the staleness test) | S2 with a *different* MCP fragment/runtime under `auto` unsupervised becomes a printed command. No probe in §D exercises `--bg`; ADR-0009 exists because `--bg` misbehaved; the supervisor never uses it |
| C3 | `opts-sync` agent verb and the `options` block as a cb-written field | nothing: `capture-rollover-options.sh:69` reads `permissionMode` from the transcript, and the record carries `session.artifact`, so the launcher captures at the bump into `launch.options` (one writer, replayed by the bootstrap bump). `options_invalid` stays |
| C4 | supervisor `flush hashes changed` / `flush_missing` | nothing: `--emit` cannot stage without the launcher's artefact gate passing |
| C5 | `session.ended.reason` written by `release` (vendor exit fact) — Q5 | nothing: no gate reads it; `close` remains the only writer of `ended` (`{at, door}`) |
| C6 | claude/codex/copilot-cli artifact-mtime *fallback* in (c) ("registered from outside the process tree") | nothing: `resolve_runtime_pid` (cb:698-723) always finds the runtime from inside its tree; keep the fallback for copilot-vscode/gemini only, as decision 4 says |
| C7 | `KILL_AFTER` / `killed_silent` | nothing by default (decision 15 = 0); the user chose to keep the knob, so listed only |
| C8 | `ledger_gap` (warn) | nothing; the successor's prompt already says "session N was abandoned" |

Kept deliberately: `staged_spent` (S6 restart after a hand-consumed stage), `close`/`quit_stop` (E11: the stop door is what makes the final ledger block mechanically checked), P4a/P4b pages (I2, V9d), `--takeover` (decision 7), `schema` (S3 residual), `chain` block (decision 8).

## 5. Recommended answers to §(m)

1. **WARN rule** — yes, "ask iff `ROLLOVER_RELAUNCH` ∈ {manual, off}" is the one rule. `auto` is already standing authorization (CONTEXT.md:289); the WARN ask is not load-bearing (STOP gates are), so a third knob buys nothing.
2. **`--bg` binding** — cut `--bg` (C2); `--clear` is the sole unsupervised hands-off path, the supervisor covers chains with exact env binding, and everything else prints the command. "Restrict `--bg` to supervised chains" is empty: the supervisor evals a foreground child and never needs `--bg`.
3. **Logout shapes** — the operator captures them as the last step of V9d (log out deliberately at chain end; the transcript tail is the fixture). Meanwhile `quit_* logout=unknowable` is acceptable: it errs toward *stopping* the chain, and the code makes the gap visible in tests (V6 codex fixture).
4. **`--unstage` spends a number** — accept the gap. A "never consumed ⇒ reuse" carve-out is an evidence test of exactly the class decision 2 removed; `staged_unconsumed` + `abandoned` is one rule.
5. **Vendor exit facts** — neither: drop them (C5). pid+pid_start is the sole oracle on every runtime; `/clear` binds by pid, not by `SessionEnd.reason`.

## 6. Overall: **SOUND-WITH-AMENDMENTS**

The record/three-writer/liveness/adapter shape holds against every kept scenario; nothing found is structural. Minimum amendments before Stage 4:

- **A1** (S3, L8) — bump copies `registered_at` into `launch.predecessor`; the staged verdict reads `launch.predecessor` + `R_before.launch.launched_at` only; the alarm snapshot is not load-bearing.
- **A2** (S6, R8) — turn-end self-kill requires `chain.supervisor` live (or the launcher refuses `--emit` without one: `reason=no_supervisor`).
- **A3** (T1/T2, L4, C1) — artefact checks run inline in the launcher/`close` at the bump, `--check` dry-run; they fire iff the caller is the live owner (`launch.by=session`), never on the supervisor's bootstrap bump; `launcher_hash` captured at `register`.
- **A4** (L5, L9) — export `TF_SESSION_SEQ` per iteration; quit requires `R.session != null ∧ R.session.seq == seq_before`, else `no_own_measurement`.
- **A5** (E16, R7') — name the CL-3 git freshness guard as kept, with a code.
- **A6** (E5, V10, V3) — add the runbook row to (i); rewrite V10 and V3 criteria as in §3.
- Apply cuts C1–C6 (C7/C8 at the user's discretion). Net effect on length: two verbs, four record fields, seven reason codes and one launch path fewer — the shortest version of Part 2 that still passes every row above.
