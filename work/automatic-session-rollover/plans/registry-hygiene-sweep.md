# Mini-slice — register-time sweep of stale primary records (registry hygiene)

Status: COMPLETE (session 23; T15 green — 8 asserts, registry suite 68,
all eight suites green, 326 total).
Scope: `scripts/context-budget.sh` one new internal function + one call site
in `cmd_register`; extends `scripts/tests/test-context-budget-registry.sh`.
Retires the parked learning from sessions 19/21: stale `role=primary`
records accumulate in `.context-budget/sessions/` from sessions that died
without release/rollover (the stale-reclaim branch of `acquire_lock` notes
the reclaim but never stamps the old holder's record).

## Design (decided this session)

- **Sweep at primary acquisition only.** After `acquire_lock` grants
  `role=primary` (and after `backstamp_superseded` claims the
  launcher-stamped predecessor), sweep every *other* same-project record
  with `role=primary` whose liveness is stale — same rule as the lock
  (`lock_holder_age` unknowable or ≥ `LOCK_STALE`). Auxiliary/child
  registrations never sweep (they didn't win the lock; the lock is
  authoritative).
- **Stamp, don't delete.** Swept records get the exact takeover stamp
  (S33 shape): `role=superseded`, `superseded_at=now`,
  `superseded_by=<new primary>`. Keeps provenance for the 7-day mtime GC
  window and stays inside the final role schema — no new role value.
  (Rejected: deleting the files — loses succession provenance and diverges
  from how every other role transition is recorded; rejected: a new
  `role=stale` — role schema is final per the session-19 decision.)
- **Live primaries are left alone.** A same-project `role=primary` record
  whose artifact is fresh (e.g. its lock file was removed out-of-band while
  the session lives) is not touched — liveness beats bookkeeping, matching
  the sweep rule for child locks.
- **Other projects' records are left alone.** Each project's next primary
  sweeps its own; register stays surgical.
- **Ordering:** `backstamp_superseded` first (claims the intended
  launcher-stamped record), then the sweep (touches only `role=primary`
  leftovers). The sweep cannot create backstamp candidates because it
  always sets `superseded_by`.

## Test plan (extend `test-context-budget-registry.sh`, T15)

- T15a stale same-project primary is stamped superseded +
  `superseded_by=<new primary>` + `superseded_at` at next primary register
- T15b live same-project primary (fresh artifact, lock gone out-of-band)
  is NOT touched
- T15c stale primary of a different project is NOT touched
- T15d stale non-primary record (auxiliary) is NOT touched
- T15e an auxiliary registration (lock held by a live primary) does NOT
  sweep

## Follow-through (after green)

- `docs/context-budget.md`: one line in the roles/registry section noting
  register-time hygiene sweep
- `decisions.md` Tier-2 note (stamp-vs-delete); backlog changelog row;
  plan marked COMPLETE; retire the parked Learnings line at rollover
- Commit + push to origin/main (standing approval)
