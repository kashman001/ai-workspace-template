# Phase 2 plan — move the fleet verbs out of the measurer (pure move)

Ticket: `issues/03-phase-2-fleet-extraction.md`. Plan of record: Part 4 of
`session-management-review-findings.md` ("Phase 2 — fleet extraction").
Branch `s4-phase-2` from `stage4`, worktree `.claude/worktrees/s4-phase-2`.

## Why this phase exists

Phase 3 rewrites the measurer's own verbs. The five sub-agent fleet verbs
share nothing with that rewrite except the file, so they leave first, with no
behaviour change, so the phase 3 diff is about the measurer only.

## Tasks

| # | Task | Check |
|---|---|---|
| 1 | New `scripts/fleet.sh` with `children`, `dispatch-contract`, `dispatch-open`, `dispatch-close`, `dispatch-list`: same CLI, options, exit codes, stdout/stderr text, files written | the three renamed suites pass with only the script path changed |
| 2 | Measurer loses the five verbs, their function bodies, their options and their usage lines; a fleet verb through the measurer fails with exit 3 and a one-line message naming `scripts/fleet.sh <verb>` | new assertions C10 / L10; `grep -c dispatch scripts/context-budget.sh` shows the refusal line only |
| 3 | `git mv` the three suites to `test-fleet-children.sh`, `test-fleet-dispatch-contract.sh`, `test-fleet-dispatch-records.sh`, re-pointed at `scripts/fleet.sh` | rc 0 each |
| 4 | Re-point in-repo callers: `CONTEXT.md`, `docs/context-budget.md` (command paths only); one tree line in `docs/workspace-structure.md` | grep for `context-budget.sh (children|dispatch-)` finds nothing outside history rows |
| 5 | Every `scripts/tests/*.sh` green | rc lines in Evidence |

## What moved (measurer line numbers before the move)

Moved verbatim into `fleet.sh`:
- `claude_child_measure` (1050–1062), `cmd_children` (1064–1110)
- `cmd_dispatch_contract` + its comment (1128–1162)
- `dispatch_record_path` + the R4 comment (1164–1176)
- `cmd_dispatch_open` (1178–1209), `cmd_dispatch_close` (1211–1228), `cmd_dispatch_list` (1230–1247)
- the five case-dispatch lines (1446–1450), the five verbs in the verb `case` (77) and the usage comment (8–9)
- options read only by these verbs: `--all --report --brief --gen --task --agent-type --effort --status` (and their variables). `--model` stays (opts-sync reads it); `--agent-id` stays (register reads it).

Copied (still needed by the measurer, so they stay there too): `resolve_workspace_root`, the `context-budget.env` precedence block (thresholds only), `note`, `die`, `parent_record_path`, `estimate_from_size`, the `jq` check.

One call changed: `cmd_children` without `--parent-session` used to call the measurer's `resolve_session` in-process. In `fleet.sh` it runs `scripts/context-budget.sh check [--runtime R] [--transcript A] [--quiet]` and reads `runtime=` / `artifact=` from its one output line (exit 3 from `check` is passed through as exit 3, stderr untouched). Everything after that point is the verbatim function.

## Callers re-pointed

- `CONTEXT.md` (dispatch bullet in "Context Budget"): `scripts/context-budget.sh dispatch-open` → `scripts/fleet.sh dispatch-open`
- `docs/context-budget.md`: quickstart line (`children`), the "Dispatching a long-running subagent" bullet (`dispatch-open`)
- `docs/workspace-structure.md`: one line for `fleet.sh` in the `scripts/` tree
- Hooks, skills, `.claude/settings.json`, `context-budget.env`: no references found. Backlog HTML rows are history and stay.

## Decisions (Tier 2 candidates; recorded here because `decisions.md` is off-limits to this agent)

1. **Helpers are copied, not shared.** `fleet.sh` carries its own copies of the few helpers it needs (~40 lines). Rejected: a `scripts/lib/` helper library sourced by both scripts. Phase 1 is adding `scripts/lib/session-lib.sh` in parallel and phase 3 decides what is shared; a second library now would pre-empt that and cross the other agent's paths.
2. **`children` asks the measurer for the caller's own session instead of copying discovery.** Rejected: copying `resolve_session` and the per-runtime discovery stack (~250 lines) into `fleet.sh`. That would duplicate the most volatile code in the workspace right before phase 3 rewrites it, and the measurer already exposes exactly this answer through `check`. Known deltas, all edge cases: a parent transcript that `check` cannot measure at all now fails `children` with exit 3 (before, the parent was never measured), and the measurer's `--quiet` is forwarded only when `children` itself got `--quiet`, so the M16 re-pin note still appears as before.
3. **`fleet.sh` accepts only the options its verbs read.** Rejected: mirroring the measurer's full option list. The measurer accepted `--takeover`, `--interval`, `--label`, `--mode`, … for fleet verbs and ignored them; `fleet.sh` answers `unknown option: … (exit 3)`. Only nonsense invocations change.
4. **Refusal, not silence, in the measurer.** `scripts/context-budget.sh children` exits 3 with `error: children moved to scripts/fleet.sh — run: scripts/fleet.sh children [options]`. Rejected: dropping the verbs from the `case` and letting the option parser say `unknown option: children`, which names no fix.

## Evidence

Run 2026-09-17 in the worktree, every suite with `bash`, no `timeout` wrapper.

Baseline (untouched `stage4`): all 23 suites rc=0.

After the move (all 23, including the three renamed):

```
scripts/tests/test-agent-entrypoints.sh rc=0
scripts/tests/test-attach-session.sh rc=0
scripts/tests/test-check-dependencies.sh rc=0
scripts/tests/test-context-budget-registry.sh rc=0
scripts/tests/test-emit-mode.sh rc=0
scripts/tests/test-fleet-children.sh rc=0            (29 asserts, C1-C10)
scripts/tests/test-fleet-dispatch-contract.sh rc=0   (24 asserts, K1-K7)
scripts/tests/test-fleet-dispatch-records.sh rc=0    (55 asserts, L1-L10)
scripts/tests/test-import-session-seq.sh rc=0
scripts/tests/test-launch-next-session.sh rc=0
scripts/tests/test-link-local-work.sh rc=0
scripts/tests/test-parameterization.sh rc=0
scripts/tests/test-rollover-clear-seed.sh rc=0
scripts/tests/test-rollover-prep.sh rc=0
scripts/tests/test-rollover-sentinel.sh rc=0
scripts/tests/test-seq-sync.sh rc=0
scripts/tests/test-session-loop-notify.sh rc=0
scripts/tests/test-session-loop.sh rc=0
scripts/tests/test-session-numbering.sh rc=0
scripts/tests/test-statusline-context-budget.sh rc=0
scripts/tests/test-template-instantiation.sh rc=0
scripts/tests/test-turn-end-exit.sh rc=0
scripts/tests/test-vendor-budget-hooks.sh rc=0
```

Line counts: `scripts/context-budget.sh` 1454 → 1265 (−189; the phase text's
"roughly 400" overestimated — the verbs, their helpers and options were ~190
lines). `scripts/fleet.sh` 309 lines. `grep -c dispatch scripts/context-budget.sh`
= 2: the usage pointer line and the refusal `case` line.

Refusal through the measurer (exit 3):

```
$ scripts/context-budget.sh children
error: children moved to scripts/fleet.sh — run: scripts/fleet.sh children [options]
$ scripts/context-budget.sh dispatch-list --project x
error: dispatch-list moved to scripts/fleet.sh — run: scripts/fleet.sh dispatch-list [options]
```

Old-vs-new comparison in a temp workspace (`git show HEAD:scripts/context-budget.sh`
against `scripts/fleet.sh`): `dispatch-contract` (with/without `--report`),
and the sequence open → close → reopen → list → bad close → list on a missing
item produced byte-identical stdout, stderr and exit codes; the record
`work/p/.agent-dispatch/t1.json` was identical minus timestamps.
