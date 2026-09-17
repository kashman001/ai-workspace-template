# Fleet plan — Stage 4 by a fleet of agents (one wave per session)

> Short, plain, self-contained. Who does what, in which order, and how the
> parent checks it. Phase content lives in `issues/0N-*.md`; progress in
> `stage4-tracker.md`.

## The idea in two sentences

Each phase is done by one agent in its own git worktree on its own branch,
so agents never touch each other's files or the scripts this session's own
hooks are running. The parent session never edits a script: it writes this
plan, launches the agents, merges green branches into `stage4`, runs every
suite there, and updates the tracker.

## Branch picture

```
main   ──●──●──●──  (old scripts, frozen; supervisor + hooks run from here;
        \            bookkeeping only: tracker, launcher, ledger, this plan)
stage4   ●──M1──M2──…──  (integration: scripts, tests, plans/phase-<n>.md)
          \  /
     s4-phase-1   (one agent, one worktree, merged on green, then deleted)
```

- `main` is never checked out to `stage4` in the primary working tree: the
  live supervisor (pid 72900) reads `scripts/session-loop.sh` from that
  tree incrementally, and the parent's hooks call `scripts/context-budget.sh`
  from it every turn. All `stage4` work happens in worktrees.
- Integration worktree: `.claude/worktrees/stage4` on branch `stage4`.
  Agent worktrees: `.claude/worktrees/s4-phase-<n>` on `s4-phase-<n>`,
  branched from `stage4` at wave start.

## Waves

| Wave | Phases | Session | Blocked by | Parallel? |
|---|---|---|---|---|
| A | 1 (record helper) ∥ 2 (fleet extraction) | 11 | phase 0 | yes, disjoint files |
| B | 3 (measurer on the record) | 12 | 1, 2 | no |
| C | 4 (launcher on the record) ∥ 6 (hook dispatcher) | 13 | 3 | yes |
| D | 5 (supervisor, three verdicts) | 14 | 4 | no; `main "$@"` wrapper commit first |
| E | 7 (probes, Claude Code acceptance) | 15 | 5 | no |
| F | 8 (skill, docs, ADRs, ignore, env, doc test) | 16 | 1–7 | no |
| cutover | import + attended rollover + 2-session chain | 17 | 8 | parent, attended |

Read-only prep for a later wave (drafting its `plans/phase-<n>.md` from the
ticket and the design tables) may run alongside the current wave. No code for
a phase before its blockers are merged into `stage4`.

## One agent, one phase — the contract

| Item | Value |
|---|---|
| Worktree / branch | `.claude/worktrees/s4-phase-<n>` on `s4-phase-<n>`, from `stage4` |
| Ticket | `work/template-improvement-review/issues/0<n+1>-phase-<n>-*.md` (its checkboxes are the acceptance list) |
| First file written | `work/template-improvement-review/plans/phase-<n>.md`: tasks, decisions with the rejected alternative, evidence |
| Throwaway item | tests run against a temp directory; from phase 3 on, a scratch item `work/s4-scratch/` inside the worktree, never committed |
| Must be green | every `scripts/tests/*.sh` (run each with `bash`, check each rc; macOS has no `timeout`) plus the phase's new or renamed suite |
| Hands back | the branch (committed, clean tree), the plan file with an Evidence section (suite rc lines, record contents where a record is written), and a short report |
| Does not touch | `stage4-tracker.md`, `next-session.md`, `handoff.md`, `decisions.md`, `.claude/settings.json`, anything under `work/template-improvement-review/` except its own plan file; never runs `context-budget.sh register/record/release` (the parent measures) |
| Dispatch record | parent: `scripts/context-budget.sh dispatch-open --project template-improvement-review --task phase-<n> --report work/template-improvement-review/dispatch/phase-<n>.md` before launch; `dispatch-close --status <S>` at yield |

## Parent's loop per wave

1. Create the integration worktree if missing; create each agent worktree from `stage4`.
2. `dispatch-open` per agent; launch the agents in parallel (general-purpose agents, not the read-only `repo-navigator`), each with its ticket, the contract above, and the design excerpts it needs.
3. On yield: `dispatch-close`; in the integration worktree, `git merge --no-ff s4-phase-<n>` (one at a time), then run every suite there. Red: send the failure back to the same agent; never fix it in the parent.
4. Green: tracker row `done` + commit hash; remove the agent worktree and branch.
5. `record --label "wave <X>"`; roll over through the live supervisor with `--loop-mode handsoff` (user, 2026-09-17: the successor starts on its own, no Enter). The launcher names the next wave.

## Hazards

- **Measurer under edit.** The parent's hooks measure the parent with `scripts/context-budget.sh` from the main tree. Agents edit only in their worktree; hooks fired during an agent's tool calls resolve `CLAUDE_PROJECT_DIR` to the main tree, so they keep running unchanged code.
- **Two agents, one script.** Never in one wave. Wave A: phase 1 adds `scripts/lib/session-lib.sh` + its suite; phase 2 edits the measurer, adds `scripts/fleet.sh`, renames three suites. Disjoint. Wave C: phase 4 owns the launcher, phase 6 owns the hooks and the dispatcher; the merge order is 4 then 6.
- **Phase 5.** First commit is the `main "$@"` wrapper on `session-loop.sh`, so a running supervisor reads the file once, before any body edit.
- **Chain cap.** Session 11 is 7 of 10; the cap lands around wave D. Restart with `scripts/session-loop.sh template-improvement-review --reset-cap`.
- **Bookkeeping split.** `main` carries tracker/launcher/ledger/decisions/this plan; `stage4` carries scripts, tests, `plans/phase-<n>.md`. Never both on one file, so cutover merges cleanly.
