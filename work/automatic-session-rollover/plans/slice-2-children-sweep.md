# Slice 2 — per-child transcript sweep helper (R1)

Status: COMPLETE (session 18; C1–C9 green — 27 asserts, all six suites green,
live smoke test surfaced the research's 141.8K child as WARN).
Scope: `scripts/context-budget.sh` new `children` subcommand + new test suite.
Research §10 R1 + §14.2; builds on ADR-0005 (roles/registry). Claude adapter
only — no other runtime exposes per-child artifacts we've verified.

## Design (decided this session)

- **New subcommand `children`** (rejected: a `--children` flag on `check` —
  check's contract is one artifact → one status line → exit = own status;
  the sweep is N artifacts + escalation filtering, a different contract).
  Surface: `context-budget.sh children [--parent-session <sid>] [--all]`.
- **Parent selection:** default = the current session (resolve_session);
  `--parent-session <sid>` sweeps another *registered* session's children
  (artifact via its registry record). Claude runtime only; loud die otherwise.
- **Enumeration:** subagents dir = `${parent_artifact%.jsonl}/subagents/`
  (verified layout: `<proj>/<parent-uuid>/subagents/agent-<hash>.jsonl` with
  `.meta.json` siblings). Direct children only (R8 subsidiarity —
  grandchildren are the child's own business).
- **Sidechain-inclusive measurement:** child transcript entries are all
  `isSidechain: true`; `claude_measure`'s sidechain filter (correct for
  parent self-measure) would silently degrade every child to size-estimate.
  The sweep uses a variant with the filter dropped.
- **Escalation-only default (R1):** print only WARN/STOP children; `--all`
  prints every child. Exit code = worst status across ALL children measured
  (0/1/2, check semantics). No subagents dir / no children → note + exit 0.
- **Per-child line:** `agent=<id> tokens= threshold= warn= pct= status=
  age=<secs> type=<agentType> artifact=` — check-style key=value, plus
  artifact age (liveness signal, same mtime principle as locks) and the
  `.meta.json` agentType (missing meta tolerated, `type=?`).
  Summary note to stderr: `children: <n> measured, <m> escalated`.
- **Deferred out of this slice:** throttling (belongs to hook wiring),
  ledger writes, live-only filtering, non-claude adapters.

## Test plan (new suite `scripts/tests/test-children-sweep.sh`)

- C1 two children under WARN → no lines, exit 0, summary counts
- C2 one child ≥WARN → its line (tokens/status=WARN), exit 1
- C3 one child ≥STOP among WARN → worst wins, exit 2
- C4 `--all` also lists OK children
- C5 meta.json agentType surfaced; missing meta tolerated
- C6 sidechain-true entries measured exact (not size-estimate)
- C7 no subagents dir → exit 0, "no children" note
- C8 `--parent-session <sid>` sweeps another registered session's children
- C9 non-claude runtime → loud die, exit 3

## Follow-through (after green)

- Usage header of `context-budget.sh` gains `children` + `--all`
- Docs: `docs/context-budget.md` — child sweep section (R1, escalation-only)
- `decisions.md` note (children subcommand vs check flag; sidechain variant)
- Backlog changelog row; plan marked COMPLETE
- Commit + push to origin/main (standing approval); user pulls main checkout
