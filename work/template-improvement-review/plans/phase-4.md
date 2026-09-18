# Phase 4 plan — launcher on the record, first end-to-end slice

Ticket: `issues/05-phase-4-launcher-on-the-record.md`. Plan of record: Part 4 of
`session-management-review-findings.md` ("Phase 4 — launcher", line 799);
record table, "How the successor finds its number" and the gate table in
`evaluation/stage3-design-v2.md` (lines 50–66, 98–124). Builds on phase 3
(`plans/phase-3.md`: `register` binds via `TF_SESSION_PROJECT`+`TF_SESSION_SEQ`
or `launch.pending`; `close`; decisions 7–8). Branch `s4-phase-4` from
`stage4` (0a117c6), worktree `.claude/worktrees/s4-phase-4` (2026-09-18).

## Tasks

| # | Task | Check |
|---|---|---|
| 1 | Rewrite `scripts/tests/test-launch-next-session.sh` against the record on a throwaway git workspace: one test per gate (exit 4 + reason code), `--check` writes nothing (`cmp`), the end-to-end slice with the real `register` on a stub claude transcript, `--clear` writes `launch.pending`, bare launch writes no `staged`, the supervisor bootstrap exemption, worktree/freshness gates | red against the `stage4` launcher, green after |
| 2 | Rewrite `scripts/tests/test-emit-mode.sh`: emitted command == dry-run command for the five attached runtimes, `--emit` side effects (record `staged`, `.next-command` + sidecar + counter mirror for the old supervisor), `mode=off` does not swallow `--emit`, bare `--emit` resolves from `WORKSPACE_ROOT`, failed emit is loud, bootstrap exemption legs | same |
| 3 | Launcher: read the record once; gates in order (below); one `session_record_update` write; supervisor-compat files after it; `--check`; refusals `exit 4` + `launch-next-session: refused reason=<code> k=v …` | suites 1–2 green |
| 4 | Delete `--bg` + confirmation poll, `--unstage`, `.rollover-options` replay + `OPT_ARGS`, `.session-seq.provenance` / stray-copy reporting, the lineage gate on the counter, `.active-session` release + child-lock sweep, `successor-pending-*.json`, `scripts/hooks/rollover-clear-seed.sh`, `scripts/tests/test-rollover-clear-seed.sh`; rewrite the three `seq-sync` remedies | `grep -rn` over scripts/ finds no `--bg`/`--unstage`/`seq-sync`/`pending-clear-seed`/`rollover-options` in the launcher or its suites |
| 5 | `scripts/tests/test-session-loop.sh`: minimal fixture edit so the real-launcher cases (G4, V4, F1, N1) run against a record: `reset()` seeds `session-state.json` (seq 8, no owner), the fixture `.gitignore` ignores it, V4 seeds the owner + ledger block instead of `.active-session` + a registry record, V4b asserts `session == null` | suite green |
| 6 | Every `scripts/tests/*.sh` green, `python3 scripts/tests/test-check-ledger.py` green | rc lines in Evidence |

## Interface

`launch-next-session.sh <project> [--runtime rt] [--emit [<abs-path>]] [--loop-mode interactive|handsoff] [--loop-reason <text>] [--clear] [--check] [--dry-run] [--skip-freshness]`

Kept: `--runtime`, `--emit` (bare form resolves to `WORKSPACE_ROOT/work/<p>/.next-command`), `--loop-mode`, `--loop-reason`, `--clear`, `--dry-run`, `--skip-freshness`. New: `--check`. Deleted: `--bg`, `--unstage`.

Exit: 0 launched / staged / check ok; 3 usage (`die`, parse-time contradictions unchanged: relative `--emit`, `--emit`+`--dry-run`, `--clear`+`--emit`, `--loop-*` without `--emit`, both `.hands-off`/`.interactive` markers); 4 refused, `launch-next-session: refused reason=<code> [k=v …] — <remedy>` on stderr (the measurer's convention). `--check` and `--dry-run` run every gate and write nothing; `--dry-run` additionally prints `cmd:`.

### Gate order

Parse-time usage errors, then, reading `work/<p>/session-state.json` once:

1. `schema_mismatch` — record exists but is unreadable, not an object, or `.schema != 1` (`record=` `schema=`).
2. `chain_closed` — `.chain.closed != null`, or the legacy `.chain-closed` marker (the phase-5 supervisor still writes it) (`seq=` `at=`).
3. `runtime_path_unsupported` — after runtime resolution (`--runtime` > `.session.runtime` > `ROLLOVER_RUNTIME` > claude): unknown runtime; `--emit` with `copilot-vscode`; `--clear` off claude (`runtime=` `path=`); `--clear` when the owner's block records no pid is checked once the caller is confirmed as the owner (gate 6), same code.
4. `supervised_stage_only` — bare launch or `--clear` while `context-budget.sh supervised` is positively live (exit 0) (`pid=`). Ambiguity (exit 2) warns and proceeds, as before.
5. `no_supervisor` — `--emit` from a session that was started by a supervisor (`TF_SESSION_LOOP=1`) while `supervised` says positively unsupervised (exit 1): the turn-end self-kill would end the session with nothing to consume the staged command.
6. `owner_live` / `not_owner` — identity = the exported session id (claude, codex, copilot-cli, copilot-vscode, opencode; gemini's constant `workspace` only when the resolved runtime is gemini). Owner iff `.session.runtime-.session.session_id == me`. Otherwise: owner live (pid + `pid_start`, else transcript age < `CONTEXT_LOCK_STALE_SECS`) → `owner_live owner= me=`; owner absent or dead → `not_owner owner= me=` (remedy: `register --project <p>`). Exempt: the supervisor's own bootstrap (strict parent pid == `.session-loop` pid, alive), which proceeds when there is no live owner and writes `launch.by=supervisor`, `staged.by=supervisor`.
7. `worktree_unsynced` — worktree-invoked: uncommitted `work/<p>` in the worktree or the main checkout, unpushed commits, or the main checkout's ff-only pull fails (`checkout=` `state=`). `--check`/`--dry-run` skip the pull.
8. `launcher_stale` — a commit touching `work/<p>/next-session.md` reachable from some ref but not `HEAD` (`commit=` `refs=`); the worktree ff-push self-heal is kept; `--skip-freshness` skips.
9. Artefact checks, owner only (never on the bootstrap): `launcher_unchanged` — `next-session.md` absent (`file=` `— absent`) or its digest equals `.session.launcher_hash` taken at registration (`file=` `hash=`); `ledger_shape` — no `handoff.md`/`session_handoff.md`, no `# Session Handoff` heading, or an unnumbered top heading (`file=`); `ledger_seq_mismatch` — top-block number != `.seq` (`ledger=` `seq=` `file=`). Grammar: `top_ledger_session` (mirrors `check-ledger.py`).

### The write (one `session_record_update`, precondition `.seq == seen and .session.session_id == seen`)

```
seq      = seen + 1   (no record: ledger top + 1, else 1 — the launcher opens it)
launch   = {launched_at, by: "session"|"supervisor", mode: <loop-mode>,
            predecessor: null | {seq, session_id, registered_at, disposition},
            pending: null | {pid, pid_start, prompt}}        (--clear)
session  = null
staged   = null | {successor: seq, command, by: <caller sid>|"supervisor"}   (--emit)
```

`disposition`: `rolled_over` when the caller is the owner; on the bootstrap `stopped` when the dead owner's `ended.door == "stop"`, else `abandoned`. A lost compare-and-set (rc 1) refuses `not_owner — the record changed underneath`. The successor's command carries `TF_SESSION_PROJECT=<p> TF_SESSION_SEQ=<seq>` as an env prefix (attached exec exports them; `--emit` and the `run:` line prefix them), so `register` binds by the env pair; `--clear` binds by `launch.pending.pid`.

### Kept for the phase-5 supervisor (unchanged this wave; read by `session-loop.sh` and `test-session-loop.sh`)

Written after the record, never read by the launcher: `work/<p>/.session-seq` (mirror of `seq`), `work/<p>/.session-seq.bump.json` (`seq`, `successor`, `runtime`, `session_id`, `cwd`, `written_at`, `mode`, `reason`, `written_by`), and on `--emit` the command at the emit path plus its `.json` sidecar (`project`, `seq`, `successor`, `runtime`, `session_id`, `written_at`, `command_cksum`, `written_by`). `supervised` is still read from the `.session-loop` marker (phase 5 moves it into `chain`). Phase 5 deletes all of this.

## Decisions (Tier 2 candidates; `decisions.md` is off-limits to this agent)

1. **`not_owner` vs `owner_live` split.** A caller who is not the recorded owner is refused either way; the code says why: `owner_live` when another session is alive on the item (roll over from it, or `register --takeover`), `not_owner` when the slot is empty or its owner is dead (remedy `register --project` — it adopts). Rejected: the old C5 "rollover is the authority" release of a dead holder — the launcher now writes the outgoing owner into `launch.predecessor`, and a non-owner cannot vouch for that block.
2. **`no_supervisor` fires only for a supervised session (`TF_SESSION_LOOP=1`) staging with no live supervisor.** The ticket's end-to-end slice is `--emit` with no supervisor and expects `staged.by`, so `--emit` cannot refuse on the absence alone. Rejected: refusing every `--emit` without a supervisor (contradicts the acceptance test).
3. **`--check` and `--dry-run` run every gate.** A dry-run that passes where a launch would refuse is the readout the operator cannot trust; the gates are cheap and side-effect-free. Rejected: the old dry-run exemptions from the supervisor guard and the authorization guard.
4. **`.session-seq` and the two sidecars are written, never read.** The record's `seq` is the only number source; the counter and the bump/identity sidecars are a compatibility mirror for the unchanged phase-5 supervisor. Rejected: reading the legacy counter when no record exists (`import-session-seq.sh` is the migration path, and two number sources is the defect class this stage removes).
5. **A missing `next-session.md` is `launcher_unchanged`.** The file the successor is told to read was not written; the detail says `absent`. Rejected: a new code (the ticket's list is closed) or keeping `die` (tests pin reason codes).
6. **`.active-session` and `.agent-locks` leave the launcher.** Phase 3 stopped writing both; the record's `session` block is the lock and child locks are fleet's (phase 7). Rejected: a compatibility `rm -f` of a file nothing writes.
7. **Supervisor bootstrap dispositions.** With no session to roll over, the bootstrap records the dead owner as `stopped` (closed through the stop door) or `abandoned`; `predecessor` is null when the slot was empty. Rejected: refusing the bootstrap on a dead owner (a killed chain could never restart).
8. **`launch.options` and `launch.reason` are not written.** Nothing captures permission mode without the deleted `.rollover-options` file, and the design drops reason strings from the record; `--loop-reason` reaches only the compat bump record. Rejected: carrying `reason` in the record for one wave.
9. **Runtime resolution reads the record, not the registry.** `--runtime` > the outgoing owner's `session.runtime` > `ROLLOVER_RUNTIME`. Rejected: the newest registry record for the project (the D17 fallback the design retired: registration order is not identity).
10. **`test-session-loop.sh` gets the smallest fixture edit that models a migrated item.** `reset()` seeds a record (seq 8, no owner) so the bootstrap stages #9 as the suite expects; V4 seeds the owner and a ledger block and asserts `session == null` instead of a released `.active-session`. Rejected: leaving the counter as a number source for record-less items.
11. **The dangling `SessionStart` entry for `scripts/hooks/rollover-clear-seed.sh` in `.claude/settings.json` is handed to the parent.** The entry tests `[ -x "$h" ] || exit 0`, so the deleted hook is a silent no-op until phase 6/8 removes the line; this agent may not edit that file.

## Evidence

Run 2026-09-18 in the worktree, every suite with `bash`, no `timeout` wrapper.

Suites for this phase, rewritten to the record contract and green against the
new launcher: `test-launch-next-session.sh` **193 passed, 0 failed** (E, P, S,
C, R, V, N, O, A, B, L, M, D, W, F series); `test-emit-mode.sh` **54 passed,
0 failed** (E1–E10). `test-session-loop.sh` after the fixture edit (task 5):
see the rc line below.

Every suite (20 files after the deletion), plus the Python ledger check:

```
scripts/tests/test-agent-entrypoints.sh rc=0
scripts/tests/test-attach-session.sh rc=0
scripts/tests/test-check-dependencies.sh rc=0
scripts/tests/test-context-budget-registry.sh rc=0
scripts/tests/test-emit-mode.sh rc=0                 (54 asserts)
scripts/tests/test-fleet-children.sh rc=0
scripts/tests/test-fleet-dispatch-contract.sh rc=0
scripts/tests/test-fleet-dispatch-records.sh rc=0
scripts/tests/test-import-session-seq.sh rc=0
scripts/tests/test-launch-next-session.sh rc=0       (193 asserts)
scripts/tests/test-link-local-work.sh rc=0
scripts/tests/test-parameterization.sh rc=0
scripts/tests/test-session-lib.sh rc=0
scripts/tests/test-session-loop-notify.sh rc=0
scripts/tests/test-session-loop.sh rc=0              (222 asserts; fixture edit per task 5)
scripts/tests/test-session-numbering.sh rc=0
scripts/tests/test-statusline-context-budget.sh rc=0
scripts/tests/test-template-instantiation.sh rc=0
scripts/tests/test-turn-end-exit.sh rc=0
scripts/tests/test-vendor-budget-hooks.sh rc=0
python3 scripts/tests/test-check-ledger.py rc=0
```

Line counts: `scripts/launch-next-session.sh` 1319 → 512;
`test-launch-next-session.sh` 1352 → 438; `test-emit-mode.sh` 239 → 184.
`scripts/context-budget.sh`, `scripts/lib/session-lib.sh`, `scripts/session-loop.sh`
and every other hook untouched.

### Deleted

Flags: `--bg` (and its successor-confirmation poll, `ROLLOVER_CONFIRM_SECS`),
`--unstage`. Files: `scripts/hooks/rollover-clear-seed.sh`,
`scripts/tests/test-rollover-clear-seed.sh`; the launcher no longer writes or
reads `work/<p>/.pending-clear-seed`, `work/<p>/.rollover-options` (and the
`OPT_ARGS` approval/model mapping), `.session-seq.provenance.json`, stray
cross-checkout `.session-seq` copies, `.context-budget/successor-pending-<p>.json`,
`work/<p>/.active-session`, `work/<p>/.agent-locks/`. Logic: the lineage gate on
the counter (one-ahead reclaim, fingerprint diagnosis), the `.active-session`
identity×liveness guard and child-lock sweep, the D17 registry fallback, the
`STAGE_INSTEAD`/`BG` derivation. Tests: the old T1–T24, U, C, W6–W7, G, H, K,
S9–S12, D17 series and E2b/E2c/E4c/E6c/E8b/E8d in their old form. Remedy text
naming `seq-sync`: gone (E8d now asserts its absence). `.gitignore`: no
seed-file line existed on this branch; nothing to remove (the retired
`.rollover-options`/`.session-seq*` lines are phase 8's).

### Record contents, throwaway item `work/item` (paths shortened)

The slice, on a stub claude transcript, no supervisor:

```
$ printf '# Session Handoff — 11 …' > work/item/handoff.md
$ CLAUDE_CODE_SESSION_ID=pred scripts/context-budget.sh register --project item --runtime claude
register: bound work/item seq=12 via=project (opened)
$ echo "# launcher for 13" > work/item/next-session.md; printf '# Session Handoff — 12 …' > work/item/handoff.md
$ CLAUDE_CODE_SESSION_ID=pred scripts/launch-next-session.sh item --check
launch-next-session: check ok project=item seq=12 successor=13 path=exec by=session   rc=0   (cmp: wrote nothing)
$ CLAUDE_CODE_SESSION_ID=pred scripts/launch-next-session.sh item --emit
project=item runtime=claude mode=manual path=emit seq=13
record: seq 12 -> 13, predecessor=rolled_over, by=session (work/item/session-state.json)
emit: staged the successor command at …/work/item/.next-command                        rc=0
$ cat work/item/session-state.json
{
  "schema": 1, "seq": 13, "session": null,
  "launch": {
    "launched_at": "2026-09-18T07:13:40Z", "by": "session", "mode": "handsoff",
    "predecessor": {"seq": 12, "session_id": "pred", "registered_at": "2026-09-18T07:13:40Z", "disposition": "rolled_over"},
    "pending": null
  },
  "staged": {
    "successor": 13,
    "command": "TF_SESSION_PROJECT=item TF_SESSION_SEQ=13 claude --name item\\ #13 Work\\ item\\ item\\ -\\ rollover\\ session\\ #13.\\ Read\\ \\`work/item/next-session.md\\`\\ and\\ continue\\ from\\ \\*\\*First\\ actions\\*\\*.",
    "by": "pred"
  }
}
$ TF_SESSION_PROJECT=item TF_SESSION_SEQ=13 CLAUDE_CODE_SESSION_ID=succ scripts/context-budget.sh register --runtime claude
register: bound work/item seq=13 via=env (filled)
$ jq -c '{seq, session:{seq:.session.seq, session_id:.session.session_id}, predecessor:.launch.predecessor.session_id}' work/item/session-state.json
{"seq":13,"session":{"seq":13,"session_id":"succ"},"predecessor":"pred"}
```

Mirror for the phase-5 supervisor after the `--emit`: `work/item/.session-seq` = `13`;
`.session-seq.bump.json` = `{seq:12, successor:13, runtime:claude, session_id:pred, mode:handsoff, reason:"", written_by:launch-next-session.sh, …}`;
`.next-command.json` = `{project:item, seq:12, successor:13, session_id:pred, command_cksum:<cksum of .next-command>, written_by:launch-next-session.sh, …}`.

Refusals (record byte-identical after each, `cmp`):

```
$ (as other) … item --emit   → launch-next-session: refused reason=owner_live project=item owner=claude-succ me=claude-other — a live session owns work/item; …   rc=4
$ (as succ, launcher not rewritten) … item --emit
                             → launch-next-session: refused reason=launcher_unchanged file=…/next-session.md hash=78e2a6637482 — unchanged since this session registered; …   rc=4
```

The suite pins the other codes the same way: `schema_mismatch` (S1–S2),
`chain_closed` (C1 record, C2 legacy marker), `runtime_path_unsupported`
(R1–R4), `supervised_stage_only` (V1–V3, incl. `--dry-run`), `no_supervisor`
(N1), `not_owner` (O4–O7, L2, B7), `ledger_shape` (A3–A5), `ledger_seq_mismatch`
(A6), `worktree_unsynced` (W1, W2, W5, W6), `launcher_stale` (F1, F4); the
bootstrap exemption with `abandoned`/`stopped` dispositions (B1–B6); `--clear`
writing `launch.pending` (L1).

### Handoff items for the parent

- **Dangling hook entry.** `.claude/settings.json` (stage4 copy) still has the
  `SessionStart` entry that execs `scripts/hooks/rollover-clear-seed.sh`. The
  entry guards with `[ -x "$h" ] || exit 0`, so with the hook deleted it is a
  silent no-op; the line itself is the parent's (or phase 6/8's) to remove.
  This agent may not edit that file.
- **Prose still naming the deleted pieces** (phase 8): `skills/session-rollover/SKILL.md`
  (`--bg`, `--unstage`, `.rollover-options`, the seed file), `docs/context-budget.md`,
  `docs/adr/0009-clear-based-rollover-relaunch.md`, `mcp-fragments/README.md`,
  `CONTEXT.md` ("inherits the predecessor's launch options via `.rollover-options`").
- **`--clear`'s prompt injection.** The seed hook is gone; the prompt now sits in
  `launch.pending.prompt` for phase 6's dispatcher to inject at SessionStart.
- **Supervisor compat.** Phase 5 deletes the counter mirror, the bump record and
  the identity sidecar from the launcher once `session-loop.sh` reads the record.
