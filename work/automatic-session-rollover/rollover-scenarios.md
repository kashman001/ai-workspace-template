# Rollover Scenario Catalog

**Authority:** this file is the authoritative scenario catalog for the
subagent-rollover design. It *extends* the seed suite in
`subagent-rollover-research.md` §13.3 (S1–S10, which stay where they are) and
continues its numbering. The HTML review doc
(`subagent-rollover-research.html` §7) mirrors this file for reading; when
they diverge, this file wins. Invariants I1–I8, fault properties P1–P5, and
the cost model referenced below are defined in research §13.

**Purpose (user direction, session 12):** enumerate mainline flows plus
corner/edge cases across the evaluation dimensions *before* implementing
anything, so the catalog can (a) be held in mind while reviewing the design
and (b) become the acceptance/fault-injection harness. Every scenario is
phrased with pass criteria so it can become a test in the existing harness
style (mktemp fixtures, `touch -t` mtimes, stub CLIs).

## The dimension set (answer to "is there a dimension I missed?")

The base list was: **functional mainline, resilience, recoverability,
performance.** Yes — five more earn first-class status, and one candidate
folds in rather than standing alone:

1. **Concurrency & contention** — distinct from resilience: nothing *fails*,
   things *overlap*. Races between drain broadcasts and completions, lock
   steals at the stale boundary, sibling writes, a human attaching to the
   workspace mid-drain. Fault injection won't surface these; interleaving
   will.
2. **Vendor heterogeneity & degradation** — S10 opens this, but the
   four-runtime survey (claude exposes child handles; codex/gemini children
   are opaque; opencode forbids nesting) means degraded modes need their own
   scenario rows, including mixed fleets, not one representative case.
3. **Human-in-the-loop & policy** — the seams where automation meets human
   authority: declined rollovers, manual kills, approval scope across
   generations, a human taking over a child. These are policy edges, not
   faults, and several have no analog in main-session rollover.
4. **Observability & auditability** — not "does it work" but "can an
   operator or auditor tell what happened from disk alone." I5 (no silent
   terminal states) and I7 (artifact-only liveness) seed this but don't
   cover reconstruction or attribution.
5. **Evolution & compatibility** — records outlive the code that wrote them:
   schema skew across generations, launch-config (including permission-mode)
   inheritance, thresholds edited mid-flight.

**Folded in, not separate:** cost/token-economy is the *substance* of
performance here (the scarce resource is parent-context tokens), so
budget-edge scenarios live in the performance group rather than a tenth
dimension. **Resilience vs recoverability**, kept distinct: resilience =
invariants hold *through* a fault, automatically; recoverability = the
ability to reconstruct and continue from persistent state *afterwards*,
possibly operator-driven.

**Still out of scope** (unchanged from research §13.4): disk loss (git +
push is the answer) and clock skew beyond mtime granularity (same exposure
as the shipped lock system).

Class column: **M** = mainline flow, **E** = edge/corner case,
**★** = measurement (pass = number obtained and bound holds).

## A. Functional mainline (extends S1, S2, S4, S7–S10)

| ID | Class | Scenario | Pass criteria |
|---|---|---|---|
| S11 | M | Fix round: child yields `DONE_W_CONCERNS`, parent reviews, sends `FINDINGS`, child fixes | Fix lands in the *same* generation while its lock is held; no successor spawned; I3 holds; report shows findings + fix blocks |
| S12 | M | `NEEDS_CONTEXT`: child yields for missing input, parent supplies it | WAITING→RUNNING; the supplied context is appended to the brief on disk (not only in-band), so a later generation would get it too |
| S13 | M | Full queue drains to completion: N tasks, concurrency cap M, one parent rollover mid-queue | Every task has exactly one COMPLETE generation chain; nothing lost or duplicated across the parent succession; dependency edges honored (S9 superset) |
| S14 | M | Long-running child: many checkpoint cycles, no rollover ever needed | Report checkpoints are monotonic; steady-state probe cost ≈ 0 parent tokens (escalation-only); no spurious nudges |
| S15 | E | Child's `YIELD(DONE)` crosses the drain broadcast in flight | DONE wins; no gen 2 dispatched for a finished task; drain child-count decrements correctly |

## B. Resilience (extends S3, S5, S6; exercises P1–P5)

| ID | Class | Scenario | Pass criteria |
|---|---|---|---|
| S16 | E | Parent crashes mid-fencing: gen N+1 dispatch record half-written | Recovery resolves to at most one live writer (I3, P2): either gen N+1 is validly on record or the dispatch is redone cleanly — never two successors |
| S17 | E | Child crashes while WRAPPING (rollover handoff half-written) | Successor starts from the last *full* checkpoint (I8); ledger records crash-during-rollover, not a clean roll |
| S18 | E | Zombie revival: presumed-dead child resumes after gen N+1 was dispatched | Revived gen N discovers its lock invalid before appending (I3 fencing); its writes are refused or ignored; ledger notes the event |
| S19 | E | Sweeper/probe reads a report mid-append (torn tail line) | Reader tolerates the partial line; no false KILLED verdict; verdict settles by the next cycle |
| S20 | E | Parent hits STOP during drain with one child unresponsive | Kill path fires per the budget state machine; ledger ruling written (I5); parent reaches ROLLING only at zero child locks (I4) |
| S21 | E | Child yields `ROLLOVER_NEEDED` while parent is DRAINING | No gen N+1 dispatch (drain forbids new dispatches); task is queued-with-state on disk; the *successor parent* dispatches gen N+1 from the record |

## C. Recoverability

| ID | Class | Scenario | Pass criteria |
|---|---|---|---|
| S22 | M | Cold reconstruction: every process gone, disk only | Successor parent rebuilds queue, in-flight generations, and pending human questions purely from records + reports + ledger; plan equals pre-crash plan modulo post-checkpoint tails |
| S23 | E | Double recovery race: two successor parents launched | I1 — one acquires the work-item lock; the loser aborts with zero writes |
| S24 | E | Recovery run twice sequentially (P4 deepened) | Second run is a no-op: no duplicate dispatches; any side-effect redo is detectable in git-visible files |
| S25 | E | Abandoned task reinstated: KILLED-with-no-successor later revived by explicit ruling | New generation chain links back to the old ledger entries (I5 continuity); no orphaned partial state |
| S26 | E | Operator lock surgery: human deletes a stale lock / hand-edits a record | System revalidates from artifacts and either tolerates or fails loudly; a documented runbook path exists; no silent corruption |

## D. Performance & token economy (extends the §13.5 cost model)

| ID | Class | Scenario | Pass criteria |
|---|---|---|---|
| S27 | ★ | Orchestration-overhead WARN point: grow fleet size N until the parent WARNs on overhead alone | Measured N★ matches the dispatch-guard formula `N ≤ (STOP − current − reserve) / return_cap` within tolerance |
| S28 | E | Return-cap violation: child returns far over the cap | Parent-context growth stays bounded (truncate/refuse); full content remains on disk; overage logged for the fix-round |
| S29 | ★ | Rollover-reserve sufficiency: parent handoff written at STOP | Measured handoff cost < `rollover_reserve` across trials; otherwise the reserve parameter is resized — before implementation freezes it |
| S30 | ★ | Drain-latency runway: drain completes inside WARN→STOP at the observed burn rate | Measured on real fleets; in the worst trial the S3/S20 kill path enforces the bound |
| S31 | ★ | Roll-vs-resume crossover: successor re-read cost vs resume history at several transcript sizes | Crossover point documented; validates the roll-not-resume rule at the 141.8K-class sizes that motivated it |

## E. Concurrency & contention

| ID | Class | Scenario | Pass criteria |
|---|---|---|---|
| S32 | M | Unrelated session works a *different* work item while a fleet runs | Zero interference; each work item's I1 is independent; probes never cross work items |
| S33 | E | Human attaches to the *same* work item during drain | Lock contention surfaces to the human (warned/refused while drain holds the lock); no dual writer; drain completes, or the human takes over via an explicit recorded steal |
| S34 | E | Lock-steal race at the stale boundary: successor and reviving owner contend at ~`LOCK_STALE` | Exactly one winner (I1); the loser's subsequent appends are refused (I3) |
| S35 | M | M siblings checkpoint simultaneously | No cross-child interleaving (per-child report files by construction); parent probe reads stay consistent |
| S36 | E | Parent and child hit WARN in the same window | Explicit ordering rule: child drains/rolls first (S21 rule if parent is already DRAINING); parent reaches ROLLING only after (I4); no deadlock between the two rollovers |

## F. Vendor heterogeneity & degradation (extends S10)

| ID | Class | Scenario | Pass criteria |
|---|---|---|---|
| S37 | M | Opaque child (codex/gemini): no transcript handle, no measurement | Contract mode: report-file heartbeats + capped returns give S1/S2-equivalent outcomes; probe degrades to report mtime (I7 still holds); only the *measurement-triggered* roll is lost |
| S38 | E | Mixed fleet: claude child + codex child under one parent | Per-child adapter selection; invariants hold for both; measurement features apply only where available; opaque child not falsely flagged stale |
| S39 | E | Nesting-forbidden runtime (opencode) asked to parent | Dispatch guard refuses depth ≥ 1 loudly and degrades to sequential in-session work; the refusal is recorded, not silent |
| S40 | E | Unknown runtime, no adapter | Handle-dependent features refuse loudly; contract-mode features (files, capped returns) still function |
| S41 | E | Hooks unavailable to a running child (the open mid-flight-injection question) | Nudge falls back to the disk channel; bounded patience then the kill path; the empirical answer (can hooks reach a live claude child?) is recorded either way |

## G. Human-in-the-loop & policy

| ID | Class | Scenario | Pass criteria |
|---|---|---|---|
| S42 | M | User declines rollover at parent WARN while children are live | Write-ahead incremental mode engages; dispatch guard tightens (no new children); the STOP path still fires unconditionally |
| S43 | E | BLOCKED child raises a human question during drain, no human present | Question serialized into handoff/`next-session.md` (S7 seed); child is yielded, not killed; successor re-raises it verbatim; no invented answer |
| S44 | E | Human kills a child process directly | Indistinguishable from a crash — S3/S5 machinery absorbs it; if the human declares intent, the ledger records a human ruling instead of a crash verdict |
| S45 | E | Approval scope across generations: gen N held a standing approval (e.g. push-to-main) | Approvals are carried *explicitly* in records/handoff; a successor (child or parent) never assumes authority that isn't written down |
| S46 | E | Human takes over a child session and continues it by hand | Ownership change recorded; parent stops nudging/killing that child; liveness still judged from artifacts only (I7) |

## H. Observability & auditability

| ID | Class | Scenario | Pass criteria |
|---|---|---|---|
| S47 | M | Post-hoc audit: "what happened to task T?" answered from disk alone | Complete narrative reconstructible: generation chain, rulings, timings, who decided what (I5 extended to *sufficiency*, not just existence) |
| S48 | M | Live fleet status derived mid-run without touching any agent | Status computed from artifacts only (I7); accurate within `LOCK_STALE`; zero tokens spent |
| S49 | E | Failure attribution after a fault-injection run | Disk distinguishes crash vs kill vs completion vs rollover; no ambiguous terminal record types |

## I. Evolution & compatibility

| ID | Class | Scenario | Pass criteria |
|---|---|---|---|
| S50 | E | Schema skew: newer successor reads records written by an older schema version | Records carry a version; reader migrates or fails loudly; never a silent misread |
| S51 | M | Launch-config inheritance: gen N+1 and successor-parent re-dispatch preserve child launch flags, MCP fragments, permission mode | Config lives in the dispatch record (the per-child `.rollover-options` analog); successor demonstrably launches with it; permission mode never silently widens |
| S52 | E | Thresholds edited mid-flight (`context-budget.env` changed during a fleet run) | Defined take-effect point (next probe); no invariant violated during the transition; the change is visible in the ledger |

## Using the catalog

- **Review pass:** read each group after the matching design section — A/B
  against §2.6–2.8 and §13, C against §12 and P4, D against §13.5, E against
  §6–7 (locks/drain), F against §11 and the vendor survey, G against §9
  (inventory rows 12–14), H against I5/I7, I against §5 (files/records).
  A scenario the design can't answer on paper is a design gap, found before
  any code.
- **Harness pass:** M-class first (acceptance), then E-class (fault
  injection/interleaving), ★-class as measurements that fix the model's
  parameters before implementation freezes them.
- Results (pass/fail/measured value, date) should be appended as a column or
  per-scenario notes *in this file* as the harness lands.
