# Slice — parent-persisted dispatch records + generation fencing (R4)

Status: COMPLETE (session 22; L1–L9 green — 51 asserts, all eight suites
green, 318 total).
Scope: `scripts/context-budget.sh` three new subcommands
(`dispatch-open` / `dispatch-close` / `dispatch-list`) + one contract clause
+ new test suite + docs. Research §5 ("dispatch record") + §8 ("Generation
fencing"); portable-core tier (§11). This is what makes parent rollover
fleet-safe: a successor parent cannot resume predecessor children (resume is
keyed to the parent session id), but it can reconstruct the orchestration
from dispatch records + report files and re-dispatch unfinished subtrees
fresh. Without records, a parent rollover silently loses the fleet.

## Design (decided this session)

- **Layering: records are stateful, the contract emitter stays stateless.**
  New subcommands own persistence; `dispatch-contract` keeps its slice-3
  contract (pure text emit, usable unregistered). (Rejected: folding
  persistence into `dispatch-contract` — its statelessness was a slice-3
  decision and keeps it usable from any runtime/checkout; rejected: a single
  `dispatch` verb with modes — flat hyphenated commands match the existing
  CLI surface.)
- **`dispatch-open --project <p> --task <slug> --report <path>`**
  (`--brief/--agent-type/--model/--effort/--agent-id` optional): appends
  generation N+1 (status `open`, timestamped) to the task's record and emits
  the R2 contract for that generation on stdout — one command at dispatch
  time, so the record can't be forgotten and the gen in the contract can't
  drift from the gen on disk. `--gen` is rejected: generation is computed
  from the record, never passed.
- **Generation fencing at open:** `dispatch-open` refuses (exit 3, loud)
  while the task's latest generation is still `open` — gen N+1 exists only
  after gen N was closed (clean yield or parent kill ruling). This is the
  at-most-one-live-writer-per-report guarantee.
- **`dispatch-close --project <p> --task <slug> --status <S>`**: closes the
  open generation with outcome + timestamp. `S` is the five-status child
  vocabulary + `KILLED` (parent ruling for a hung/crashed child that never
  yielded). `--agent-id` merges post-hoc (the parent typically learns the id
  only after dispatch). Dies if no generation is open.
- **`dispatch-list --project <p>`**: one line per task record
  (`task= gen= status= report= brief=`); exit 1 if any generation is open,
  else 0 — the drain-check surface a rolling parent consults before its own
  rollover (partial R6, check-style like `children`).
- **Storage: `work/<proj>/.agent-dispatch/<task>.json`**, one record per
  task, `generations[]` array, resolved via `$WORKSPACE_ROOT` (ADR-0006:
  every worktree converges on the main checkout's records). Dot-prefixed
  gitignored runtime state, same class as `.agent-locks/`. (Rejected:
  research §5's literal `work/<proj>/agents/` — an undotted name reads as
  durable content and would need a broad gitignore pattern; rejected:
  `.context-budget/` — the registry stays a registry, not a store of
  dispatch specs.)
- **One new contract clause (research §8):** appended progress blocks are
  labeled with the writer's generation (`[gen N]`) — keeps the report
  readable as history across generations. Emitted by `dispatch-contract`
  (so slice-3 K-tests extend, not fork).
- **R3+R4 parent-side flow documented, not mechanized:** successor parent =
  `dispatch-list` → close orphaned gens `KILLED` → `dispatch-open` fresh
  (contract auto-carries the read-report-first clause at gen ≥2).

## Test plan (new suite `scripts/tests/test-dispatch-records.sh`)

- L1 `dispatch-open` creates the record (gen 1 `open`, metadata persisted)
  and emits the contract with `generation 1` + report path
- L2 missing `--project`/`--task`/`--report` → die exit 3; `--gen` → die
- L3 fencing: second `dispatch-open` on the same task while gen 1 open →
  die exit 3, record unchanged
- L4 `dispatch-close --status DONE` closes gen 1; next `dispatch-open` →
  gen 2 `open`, contract carries the successor clause
- L5 `dispatch-close` invalid status → die; no open generation → die;
  `--agent-id` merged into the closed generation
- L6 `dispatch-list`: lines for each task; exit 1 while any open, 0 when
  all closed
- L7 contract gains the generation-label clause (`[gen` in emit); still
  pure ASCII (K5 analog)
- L8 records land under the workspace root's `work/<proj>/.agent-dispatch/`
- L9 usage header lists the three new subcommands

## Follow-through (after green)

- `.gitignore`: `work/*/.agent-dispatch/` under the runtime-state block
- Docs: `docs/context-budget.md` — extend "Dispatching long-running
  children" with the R4 record/fencing flow; drop R4 from its deferred line
  (R6 stays deferred)
- CLAUDE.md Context Budget section: extend the dispatch-time pointer line
- `decisions.md` note (layering + storage placement); backlog changelog row;
  plan marked COMPLETE
- Commit + push to origin/main (standing approval)
