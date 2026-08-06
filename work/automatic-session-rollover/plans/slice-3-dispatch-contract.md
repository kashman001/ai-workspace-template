# Slice 3 — SDD dispatch-contract hardening (R2/R3)

Status: COMPLETE (session 21; K1–K7 green — 24 asserts, all seven suites
green, 267 total).
Scope: `scripts/context-budget.sh` new `dispatch-contract` subcommand + new
test suite + orchestration guidance in `docs/context-budget.md`.
Research §10 R2/R3 + §8 (protocol) + §14.3; portable-core tier (§11) — works
in every runtime, no child handles needed. Addresses the 141.8K
resumed-child pattern directly.

## Design (decided this session)

- **New subcommand `dispatch-contract`** emitting the R2 contract block to
  stdout, for a parent to paste/inject into a child's dispatch prompt
  (rejected: prose-only guidance in docs/skills — the contract text is
  load-bearing and would drift across hand-copies; an emitter is the single
  source of truth and gives the slice its testable surface).
  Surface: `context-budget.sh dispatch-contract --report <path>
  [--brief <path>] [--gen <n>]`.
- **`--report` required** (loud die without): the report file is the
  authoritative C→P channel (§8) — a contract without it is decoration.
  `--brief` optional (SDD tasks have one; ad-hoc dispatches may not).
  `--gen` defaults to 1; `--gen ≥2` adds the successor clause ("read the
  report file before starting; finish its open items first").
- **Contract clauses (R2, from §8's DISPATCH vocabulary):** checkpoint = an
  appended progress block to the report file at every work-unit boundary
  (doubles as heartbeat); final return capped at 15 lines, detail to the
  report; first return line = one of
  `DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT | ROLLOVER_NEEDED`;
  `ROLLOVER_NEEDED` only in response to a checkpoint request or a runtime
  WARN/STOP push, never from self-assessment (D1); on a checkpoint request:
  flush to report, yield status + open items, don't push on.
- **R3 stays parent-side policy, documented not emitted:** successor
  dispatch is the only rollover verb; resume = continuation only and stacks
  history, so the parent measures (`children` sweep) before any resume and
  rolls (checkpoint-request → fresh dispatch gen N+1) at WARN/STOP — child
  WARN is the parent's decision, no human ask (R7).
- **Runtime-agnostic + stateless:** pure text emit; no registry, session, or
  lock dependency — usable unregistered, from any runtime, any checkout.
- **ASCII-only output** (the T21 lesson: dispatch prompts traverse `%q` and
  BSD sed in launch paths; multibyte dies).
- **Deferred out of this slice:** dispatch records + generation fencing (R4),
  hook-injected acceleration, drain mode (R6), any skill-file packaging.

## Test plan (new suite `scripts/tests/test-dispatch-contract.sh`)

- K1 `--report <path>` → block contains the path + all load-bearing clauses
  (checkpoint-at-boundaries, 15-line cap, all five statuses,
  ROLLOVER_NEEDED-only-on-request)
- K2 missing `--report` → loud die, exit 3
- K3 `--brief` line present iff `--brief` given
- K4 default gen 1 → no read-report-first clause; `--gen 2` → successor
  clause + generation label
- K5 output is pure ASCII
- K6 stateless: runs with no registered session, exit 0
- K7 usage header lists `dispatch-contract`

## Follow-through (after green)

- Usage header of `context-budget.sh` gains `dispatch-contract`
- Docs: `docs/context-budget.md` — "Dispatching long-running children
  (R2/R3)" section + quickstart line; `children` section cross-ref
- CLAUDE.md Context Budget section: one dispatch-time pointer line
- `decisions.md` note (emitter vs prose-only); backlog changelog row;
  plan marked COMPLETE
- Commit + push to origin/main (standing approval)
