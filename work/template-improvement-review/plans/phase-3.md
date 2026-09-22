# Phase 3 plan — measurer verbs on the record (`register`, `release`, `close`, `--check`)

Ticket: `issues/04-phase-3-measurer-on-the-record.md`. Plan of record: Part 4 of
`session-management-review-findings.md` ("Phase 3 — measurer verbs", line 797);
record table and "How the successor finds its number" in
`evaluation/stage3-design-v2.md` (lines 50–66, 100–110). Branch `s4-phase-3`
from `stage4`, worktree `.claude/worktrees/s4-phase-3` (2026-09-17).

## Tasks

| # | Task | Check |
|---|---|---|
| 1 | Rewrite `scripts/tests/test-context-budget-registry.sh` against the record on a temp workspace: register fills `session`, binds to an open launch (env pair / `launch.pending` pid), `owner_live` / `adopted` / `takeover`, release owner vs non-owner (`cmp`), close and `close --check` (ok, `not_owner`, `ledger_seq_mismatch`, `ledger_shape`), `jq_missing`; keep the cases that still hold (M13 self-measure, gemini, worktree root, supervised, R9, M16, P-series, S1 advisory, N1 pin) | red before the rewrite, green after |
| 2 | Rewrite `scripts/tests/test-session-numbering.sh` against the record: `seq` opened once from the ledger top (+1) or 1, never regressed by registration, `session.seq == seq`, env seq mismatch does not bind, import then register keeps the imported number | same |
| 3 | Measurer: `register` writes the registry record (minus roles) and the `session` block through `session_record_update`; `release` merges `ended.at` only for the owner; new `close` (stop door) runs the ledger checks inline, `--check` dry-runs them; `jq_missing` refused before parsing (exit 4) | suites 1–2 green |
| 4 | Delete `seq-sync`, `opts-sync`, `rollover-complete` (verbs, functions, options), `scripts/rollover-prep.sh`, `scripts/capture-rollover-options.sh`, `test-seq-sync.sh`, `test-rollover-prep.sh`, `test-rollover-sentinel.sh`; the `.active-session` lock, roles, `superseded_*` stamps, `.agent-locks` child locks and the `successor-pending-*.json` handshake go with them | `grep -rn` over scripts/, hooks, skills, `.claude/`, `mcp-fragments/` finds no invocation |
| 5 | Re-point the two in-repo callers of a deleted verb: `launch-next-session.sh --unstage` rewinds the counter directly; `test-session-loop.sh` V4 drops its seq-sync and sentinel steps, V5 (the sentinel's number) is deleted | `test-launch-next-session.sh`, `test-session-loop.sh` green |
| 6 | Every `scripts/tests/*.sh` green | rc lines in Evidence |

## Interface

All verbs: exit 3 on usage (`die`), 4 with `context-budget: refused reason=<code> [k=v …]` on stderr when refused; `jq_missing` is checked right after option parsing, before any session or file is read. Record: `work/<item>/session-state.json`, written only through `session_record_update` (phase 1 lib), with a compare-and-set precondition so a lost race is a silent no-op.

### `register [--project p] [--takeover] [--runtime r] [--transcript a] [--parent-session sid --agent-id id] [--quiet]`

Never blocks: exit is the measurement's (0 OK / 1 WARN / 2 STOP), 3 on a `die`.

1. Resolves the session and the runtime pid as before; writes the registry record `.context-budget/sessions/<rt>-<sid>.json` `{runtime, session_id, artifact, project, registered_at, user, pid?, pid_start?, supervisor_pid?, parent_session_id?, depth?, agent_id?}` — `role`, `superseded_*` are gone. `project` is stamped only when the session is bound as owner.
2. Child registrations (`--parent-session`) write the registry record only (parent, depth, agent id) and never touch a work item's record.
3. Binding, first hit wins: `--project`; `TF_SESSION_PROJECT` + `TF_SESSION_SEQ` (both required; the record's `seq` must equal `TF_SESSION_SEQ`, else `register: … not bound` and project-less); a record whose `launch.pending.pid`/`pid_start` equals this process's and whose `session` is null; nothing → project-less, measures only.
4. On the bound item's record: absent record with explicit `--project` → opens `seq` once (ledger top block + 1, else 1) and fills `session`; `session` null → fills it; `session.session_id` is mine → refreshed; another owner → `--takeover` overwrites (`register: reason=takeover loser=<rt>-<sid>`), else owner live → `register: reason=owner_live owner=<rt>-<sid>` and the record is untouched (registered as non-owner), else dead or the same process → overwrites (`register: reason=adopted loser=<rt>-<sid>`). Every bind nulls `launch.pending`.
5. `session` = `{seq, runtime, session_id, pid?, pid_start?, artifact, registered_at, launcher_hash, user, ended: null}`; `launcher_hash` is the digest of `work/<item>/next-session.md` (`shasum -a 256` / `sha256sum`, empty when absent).

Liveness of a recorded owner: `kill -0 pid` and `ps -o lstart=` equal to `pid_start`; a record without a pid falls back to the owner's transcript age (< `CONTEXT_LOCK_STALE_SECS`) via its registry record, as today.

### `release [--project p]`

Project from `--project`, else the caller's registry record; none → `release: no work item bound` exit 0. Precondition `.session.session_id == mine`; filter merges `ended.at` (a `door` set by `close` survives). Exit 0 written / 1 not the owner (`release: no-op reason=not_owner owner=<rt>-<sid>`, record byte-identical) / 4 lib refusal. `--takeover` is not accepted here (register and the launcher own takeover).

### `close [--project p] [--check]`

The stop door. Owner check (`not_owner`), then the ledger checks: `work/<item>/handoff.md` (or `session_handoff.md`) must exist with a top `# Session Handoff` heading carrying a session number (`ledger_shape`, detail `file=`/`heading=`) and that number must equal the record's `seq` (`ledger_seq_mismatch ledger=<n> seq=<m>`). Grammar is the launcher's `top_ledger_session` (mirrors `check-ledger.py`). Passing: merges `ended = {at, door: "stop"}`, prints `close: ok seq=N`, exit 0. `--check`: same checks, writes nothing, prints `close: check ok seq=N`, exit 0 / 4. `--check` with another verb is a usage error.

### `check` output unchanged

`runtime= method= tokens= threshold= warn= pct= status= artifact=` stays byte-for-byte; `scripts/fleet.sh resolve_own_session` and the hook lib parse it. The `--session-id` pin still reads the registry (kept, concept 1 of the findings).

## Decisions (Tier 2 candidates; `decisions.md` is off-limits to this agent)

1. **`record`, `watch`, `supervised` stay as verbs, unchanged.** `record` is the boundary measurement every skill prescribes and its ledger (`.context-budget/context-ledger.jsonl`) is not session state; `watch` writes nothing; `supervised` is read by the launcher (twice) and by `successor_advisory`, and its marker belongs to phase 5's chain block — deleting it here would break the launcher a phase early. Rejected: folding `supervised` into a record read now (the `chain` block has no writer until phase 5).
2. **The registry record stays; the per-item side files go.** Concept 1 of the findings keeps `.context-budget/sessions/<rt>-<sid>.json` (the launcher, the supervisor, `fleet.sh children`, the `--session-id` pin and M16 all read it). What the record replaces is `.active-session`, the roles, the `superseded_*` stamps and the `successor-pending-*.json` handshake. Rejected: dropping the registry too (breaks four readers that are not this phase's).
3. **Child locks (`.agent-locks/`) leave the measurer.** The lock depended on `.active-session` (`parent_chain_holds_lock`), which is gone; findings (g) put child locks in fleet and decision 11 stops `release` sweeping them. Child *registration* stays (registry record with parent, depth, agent id — `fleet.sh children` and the advisory read those). Rejected: re-pointing the parent-chain check at the record (keeps a lock the daily loop no longer reads).
4. **Register never blocks; `owner_live` is a logged outcome, not an exit code.** Per the design's refusal table ("never blocks"). The record is untouched and the session is measured project-less. Rejected: exit 4 (a SessionStart hook would report a failure for a correct outcome).
5. **Non-owner `release` exits 1, not 4.** It is the "answer was no" convention (the lib's precondition-false), run unconditionally by the SessionEnd hook for every session; a refusal code there would be noise. `close` refuses (4): it is an explicit agent action with a remedy.
6. **Ledger checks live in the measurer, not the lib.** The launcher gains the same checks in phase 4 and can lift them then; adding an unused helper to `session-lib.sh` now is speculative. Same rule as phase 2's "helpers are copied, not shared".
7. **Deleted verbs refuse with a one-line pointer**, like phase 2's moved verbs, instead of falling through to `unknown option`. Rejected: silence (the launcher's remedy text still names `seq-sync` until phase 4 rewrites it).
8. **`--unstage` writes the counter directly.** The launcher already writes `.session-seq` itself at the lineage gate and the bump; phase 4 deletes `--unstage`. Rejected: keeping `seq-sync` alive for one caller.
9. **Env binding needs both variables and an equal `seq`.** A project without a number, or a number that does not match, is not a binding (`register: … not bound`), because the successor must never claim a launch it cannot prove is its own. Rejected: binding on the project alone (the D14 swap class).
10. **`TF_SESSION_LOOP_PROJECT` no longer binds a work item.** The design names `TF_SESSION_PROJECT`/`TF_SESSION_SEQ`; phase 5's supervisor exports them. `supervised` still reads the old variable for its ambiguity answer (unchanged).

## Evidence

Run 2026-09-17 in the worktree, every suite with `bash`, no `timeout` wrapper.

Suites for this phase, red against the `stage4` measurer, green after the
rewrite: `test-context-budget-registry.sh` 100 passed / 87 failed → **187
passed, 0 failed** (T1, R1–R10, T5, T7, G1–G3, T16, T20, T22, M16, P1–P6, S1,
N1); `test-session-numbering.sh` 4 / 14 → **18 passed, 0 failed** (N1–N6).

Every suite (21 files after the three deletions):

```
scripts/tests/test-agent-entrypoints.sh rc=0
scripts/tests/test-attach-session.sh rc=0
scripts/tests/test-check-dependencies.sh rc=0
scripts/tests/test-context-budget-registry.sh rc=0   (187 asserts)
scripts/tests/test-emit-mode.sh rc=0
scripts/tests/test-fleet-children.sh rc=0
scripts/tests/test-fleet-dispatch-contract.sh rc=0
scripts/tests/test-fleet-dispatch-records.sh rc=0
scripts/tests/test-import-session-seq.sh rc=0
scripts/tests/test-launch-next-session.sh rc=0       (329 asserts)
scripts/tests/test-link-local-work.sh rc=0
scripts/tests/test-parameterization.sh rc=0
scripts/tests/test-rollover-clear-seed.sh rc=0
scripts/tests/test-session-lib.sh rc=0
scripts/tests/test-session-loop-notify.sh rc=0
scripts/tests/test-session-loop.sh rc=0              (221 asserts; V4 without the retired steps, V5 deleted)
scripts/tests/test-session-numbering.sh rc=0         (18 asserts)
scripts/tests/test-statusline-context-budget.sh rc=0
scripts/tests/test-template-instantiation.sh rc=0
scripts/tests/test-turn-end-exit.sh rc=0
scripts/tests/test-vendor-budget-hooks.sh rc=0
```

Line counts: `scripts/context-budget.sh` 1265 → 1017. `scripts/lib/session-lib.sh`
unchanged. Deleted: `scripts/rollover-prep.sh`, `scripts/capture-rollover-options.sh`,
`scripts/tests/test-seq-sync.sh`, `test-rollover-prep.sh`, `test-rollover-sentinel.sh`.

### Record contents, throwaway item `work/item` (paths shortened)

Register on an open launch — seed, then a stub successor with
`TF_SESSION_PROJECT=item TF_SESSION_SEQ=12` (the `pid` is the real claude
ancestor of the agent session that ran this, found by the walk):

```
$ cat work/item/session-state.json
{"schema":1,"seq":12,"launch":{"launched_at":"2026-09-17T10:00:00Z","by":"session","mode":"handsoff","pending":null},"session":null}
$ TF_SESSION_PROJECT=item TF_SESSION_SEQ=12 CLAUDE_CODE_SESSION_ID=succ scripts/context-budget.sh register --runtime claude
register: bound work/item seq=12 via=env (filled)
registered claude session succ artifact: …/succ.jsonl
runtime=claude method=exact tokens=1000 threshold=150000 warn=120000 pct=0 status=OK artifact=…/succ.jsonl
rc=0
{
  "schema": 1, "seq": 12,
  "launch": {"launched_at": "2026-09-17T10:00:00Z", "by": "session", "mode": "handsoff", "pending": null},
  "session": {
    "seq": 12, "runtime": "claude", "session_id": "succ", "pid": 46023, "pid_start": "<lstart>",
    "artifact": "…/succ.jsonl", "registered_at": "2026-09-17T20:03:33Z",
    "launcher_hash": "286206fc30dc8414e5301b4b060ac11d1fe831d2a10a74236923529918c569d0",
    "user": "kashif@…", "ended": null
  }
}
```

Release by a non-owner:

```
$ CLAUDE_CODE_SESSION_ID=other scripts/context-budget.sh release --project item --runtime claude
release: no-op reason=not_owner owner=claude-succ — work/item is not this session's (claude-other); nothing written
rc=1
cmp: byte-identical
```

Close refusals (record byte-identical after all three, `cmp`):

```
$ printf '# Session Handoff — 11 (2026-09-17): stale block\n' > work/item/handoff.md
$ … close --project item            → context-budget: refused reason=ledger_seq_mismatch ledger=11 seq=12 file=…/handoff.md   rc=4
$ printf '# Session Handoff — 2026-09-17 (no number)\n' > work/item/handoff.md
$ … close --project item            → context-budget: refused reason=ledger_shape file=…/handoff.md — the top heading carries no session number   rc=4
$ (as other) close --project item   → context-budget: refused reason=not_owner project=item owner=claude-succ me=claude-other   rc=4
```

`--check` then `close` on the right block:

```
$ printf '# Session Handoff — 12 (2026-09-17): the block\n' > work/item/handoff.md
$ … close --project item --check    → close: check ok seq=12 project=item   rc=0   (cmp: --check wrote nothing)
$ … close --project item            → close: ok seq=12 project=item door=stop   rc=0
$ jq -c .session.ended work/item/session-state.json
{"at":"2026-09-17T20:03:33Z","door":"stop"}
```

`jq` absent (`PATH` without it): `context-budget: refused reason=jq_missing jq is required`, rc=4, before any read.

### Callers of the deleted verbs and scripts

Invocations fixed: `scripts/launch-next-session.sh --unstage` (wrote the counter
through `seq-sync`; now writes `.session-seq` directly, as the lineage gate
already did); `scripts/tests/test-session-loop.sh` V4 fork (ran the real
`seq-sync` and `rollover-complete`; both steps dropped) and V5/V5e-g (tested
the sentinel's number, deleted). No hook, settings file, `context-budget.env`
or `mcp-fragments/*.json` invokes any of them (`grep -rn` over `scripts/`,
`.claude/`, `skills/`, `mcp-fragments/`, `CONTEXT.md`).

Still *naming* them, prose only, left for later phases: launcher remedy messages
at `launch-next-session.sh` lines 323, 582, 1217 (pinned by `T23i4` and `E8d`;
phase 4 rewrites the launcher, and the retired verbs now answer with a one-line
pointer to the record, exit 3), comments at `launch-next-session.sh:879` and
`session-loop.sh:680`, `skills/session-rollover/SKILL.md` steps 1/6 (phase 8),
`mcp-fragments/README.md:43` (phase 8). `.gitignore` entries for the retired
files and `work/*/session-state.json`: phase 8.

Not moved here (noted for phase 7, fleet): child locks under `work/<item>/.agent-locks/`
are no longer written by `register` (decision 3); the launcher's own sweep of
that directory (`launch-next-session.sh:785-867`) is untouched and still green.
