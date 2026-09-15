# Session-management subsystem review — findings (Part 1)

> Status: FINDINGS DRAFT for user review. The plan (Part 2) is written only after the
> findings and direction are finalized with the user. Sources: three parallel review
> agents (internals / operating model / history+evidence) on 2026-09-14, spot-checked
> against the files. Repo: ai-workspace-template, main @ 8d2d542.

## Context

The user asked for a holistic review of context decay, session management and
long multi-session work (session-loop, launch-next-session, context tracking):
big picture, whether it can be improved, where complexity is unnecessary, use
cases and scenarios for judging operating models, then a plan for an improved
implementation covering internals, DevX and maintainability.

## 1. Big picture (what exists)

Scripts ≈3.9K LOC + 9 hooks ≈420 LOC + 5 wiring files; 22 test suites ≈5.5K
LOC; docs ≈3.7K lines (context-budget.md 925, workspace-structure.md 1005,
work-directory-conventions.md 344, 9 ADRs); session-rollover skill 466 lines.
113 of 433 repo commits (26%) touch this subsystem. Growth: context-budget.sh
241→1356, launch-next-session.sh 0→1201, session-loop.sh 0→722 in 8 weeks.

Three loops:
- **Measure**: per-tool hook → `context-budget.sh check` (measures from the
  transcript on disk) → escalation-only WARN/STOP pushed in-band.
- **Rollover**: skill (6 steps) → `rollover-prep.sh` → agent writes ledger
  (handoff.md) + launcher (next-session.md) → `seq-sync` assert →
  `launch-next-session.sh` (bump counter, write bump record, spawn/`--bg`/
  `--clear`/`--emit`).
- **Supervise**: `session-loop.sh` evals staged commands in a loop with guards
  (MIN_LIFETIME, STALL_LIMIT, MAX_SESSIONS+persisted budget, ALARM/ALARM_MAX,
  KILL_AFTER, NOTIFY, logout classifier).

## 2. Findings

### F1. The core is sound and incident-validated
Keep without debate: measure-from-disk (never ask the model); session-id-keyed
registry and id-keyed artifact resolution (M9–M13, M16: five incidents, one
class); repository-keyed state via git common dir (ADR-0006, which *removed*
workarounds); counter as assertion with one writer (ADR-0008); bump record as
script-written verdict (R2.17); persisted chain budget (D9); transcript-silence
probe (D6, a 3d20h hang); `--clear` relaunch (ADR-0009, deletes two failure
modes); link-local-work (L45). The launcher/ledger split for work items is the
strongest DevX idea in the repo.

### F2. One modelling gap generates most of the complexity
A session has **no durable identity and no exit event** in any runtime: rc
means nothing (logout == `/exit`), transcript path moves (EnterWorktree), id
re-keys on fork, process death is unobservable. Every design reversal in the
history (mtime→id, seq write→assert, sentinel→bump record, spawn→/clear,
wall-clock→silence) moved a fact from *inferred* to *script-written at a moment
it knew both halves*. The subsystem converged on the right shape (the bump
record) on 2026-09-11, but the older mechanisms it should replace still sit
beside it: roles (4), lock staleness + `--takeover`, lineage gate (109 lines,
depth 6), `--unstage`, resumed-predecessor fingerprint, logout transcript
sniff, four-check bump match plus a top-of-loop backstop.
**Same fact encoded N times:** session number ×7 files, mode ×4, "a rollover
happened" ×3, liveness ×3 oracles, role ×2 (both marked "cached claim").

### F3. Retired and dead surface still shipped
- `rollover-complete`: self-documented DEPRECATED, nothing reads it; ~230 LOC
  across cb/hook-lib/session-loop/launcher + a 122-line test suite.
- `dispatch-open/close/list`, `dispatch-contract`, `watch`, `children`: 5 of
  14 subcommands, 8 flags, ~180 LOC; zero non-test callers for close/list;
  research-derived, self-tagged fleet-only, no incident behind them.
- One-time ledger migration re-stat'd on every hook fire (cb:42-49); legacy
  scalar-registry rm; `session_handoff.md` alternate name used by no item;
  cross-checkout max-wins still computed by rollover-prep though retired.
- Hook throttle stamps never GC'd: 222 files for 11 sessions.

### F4. Duplication and shape of the big scripts
- Workspace-root resolution copied in 12 files; lock helpers ×3 with a "keep
  in sync" comment; seq parsing at 9 sites; ledger-heading grammar ×3;
  mode-override block byte-duplicated (launch:150-162 ≡ cb:1265-1277); four
  approval levels enumerated ×3; runtime enumeration ×2 "keep in sync".
- launch-next-session.sh: ~1087 of 1201 lines top-level straight-line code, 11
  functions; session-loop.sh: one 272-line while body with 16 halt sites.
- Six hook wrappers (221 LOC) differ only in stdin key spelling and output
  envelope.
- Contracts pinned only by tests: `cb` text output re-parsed by grep in
  hook-lib; the stall guard's bookkeeping list must match `.gitignore` (L46 was
  exactly this); rotation invariant.

### F5. Six runtimes wired, one exercised
Ledger: 273 measurements, **273 claude, 0 other**. No non-claude runtime has
ever rolled over here; gemini blocked on auth; codex/gemini exit hooks never
seen to fire; gemini supervisor "undetermined". ~40% of context-budget.sh's
surface (adapters, runtime `case` at 11 sites) serves 0% of recorded use.
MIN_LIFETIME guards a gemini-only defect (M12) on a runtime that has never run.

### F6. Supervisor is real but thin in evidence here
Unattended chains in this repo: 3 starts, 4 sessions. The "proven over 14
sessions" claim is a downstream workspace whose defects.md is not committed
here. Today's own chain drew two silence pages (2055s, 2847s) then reported the
child alive: R2.18 reduced false pages, didn't eliminate them. STALL_LIMIT
never exercised. The "did this session end cleanly?" question has 4
overlapping answers + a backstop.

### F7. Operating model: ~50 concepts vs a stated 3-concept core
Concept count for a user/agent ≈50 (launcher, ledger, dispatch record, seq,
bump record, sentinel, chain budget, hands-off/interactive, attach, /clear
seed, lock, roles, child registry, approval levels, opts-sync, seq-sync verbs,
generation fencing, R2 contract + 5 yield statuses, TF_SESSION_LOOP, ...).
Pre-first-rollover reading ≈960 lines (~10–12K tokens). Four overlapping
boundary mechanisms (checkpoint / session-rollover / vendored handoff / --clear
vs spawn); tie-break table duplicated in two skills; `handoff` writes to OS
temp outside `work/`. Rules that rely on the agent *remembering* every time
(`record --label` at every boundary — the scenario audit marks it unverifiable;
63% of STOP sessions never saw a WARN checkpoint).

### F8. Docs contradict each other on load-bearing rules
- WARN policy: CONTEXT.md:262-264 + context-budget.md:180-184 say *ask*;
  skills/session-rollover/SKILL.md:29-31 says *do not ask* (standing preference
  2026-08-14). Verified.
- CONTEXT.md:286 ships `--mode interactive`; the flag is `--loop-mode` and the
  launcher comments that `--mode` was deliberately not used. Verified.
- ROLLOVER_RELAUNCH default stated 4 times with 3 values (manual/auto/off).
- Stop-hook trigger still documented as the retired sentinel in
  context-budget.md:413,839 and workspace-structure.md:572-576.
- Chain budget + `--reset-cap` (the remedy halt messages hand the operator),
  `TF_SESSION_LOOP_PROJECT`, `CHECK_EVERY`: undocumented.
- context-budget.md's index omits "The supervisor" (187 lines, its largest
  section); ≈35% of that file is change-log narrative ("since R2.17…").
- context-budget.env comments narrate another workspace's incidents
  (policy-dev-onboarding, token-factory, cm_bugs, s29).

### F9. Downloader/template leakage
Five dangling `repos/ai-workspace-template/...` paths; env defaults baked from
one operator's incidents (`KILL_AFTER=14400`, `ROLLOVER_RELAUNCH=auto` means a
fresh clone background-launches token-spending successors on first STOP);
setup-guide.html has no rollover content; supervisor absent from CONTEXT.md and
README.md; jq/ccstatusline/notify/`claude --bg` setup unstated in the guide.

### F10. Incidental defects found (small, fix regardless)
- `.pending-clear-seed` missing from `.gitignore` (shows untracked; blocks
  link-local-work's ignored-status test).
- `SESSION_LOOP_NOTIFY="${ROOT:-.}/..."` in context-budget.env resolves against a
  different ROOT in each of its three sourcing sites.
- ADR-0009 open item never verified: whether `/clear` rotates the transcript
  JSONL (if it appends, `record` reports a false STOP immediately). 17 days old.
- Three change-log findings still say "Status: Open" in prose though carded.

## 3. Use cases / scenarios to evaluate operating models against

| # | Scenario | Who | Status today |
|---|---|---|---|
| S1 | Solo dev at keyboard, one work item, hits WARN/STOP, continues in a fresh window | core | works; ~11K-token rollover cost measured (M18), 50-concept load |
| S2 | Same, hands-off: agent rolls itself with no human command (auto/--clear/--bg) | core | works on claude only; `--bg` tty/login issues drove ADR-0009 |
| S3 | Unattended overnight chain under the supervisor | core for author | 4 sessions of evidence here; guards mostly downstream-validated |
| S4 | Two work items / two sessions on one repo concurrently | core (ADR-0004) | works; roles+lock+staleness are the cost |
| S5 | Worktree-isolated sessions (EnterWorktree, Agent isolation) | core (ADR-0006) | works; link-local-work + ff-push heal |
| S6 | Plain exit / crash / vendor logout mid-chain, then resume | core | lineage gate + --unstage + logout sniff; the densest cluster |
| S7 | Non-Claude runtime (codex/gemini/opencode/copilot×2) | claimed | wired, fixture-tested, never exercised |
| S8 | Subagent fleet dispatch with parent rollover | speculative | research-only, no incident, no callers |
| S9 | Template downloader on a clean machine | core | subsystem undocumented in the guide; leaks operator specifics |
| S10 | Non-engineer / second person | explicitly unsupported | design hole documented |

## 4. Improvement directions (for discussion, not yet a plan)

- **D-A Delete the retired and speculative surface** (F3, F5-partial): sentinel,
  dispatch/children/watch, migration shim, legacy paths, stamp GC. Low risk,
  ~-600 LOC, -1 suite, -8 flags.
- **D-B One lifecycle record per session** (F2): the launcher becomes the sole
  author of `work/<p>/session-state.json` (seq, identity, mode, disposition,
  budget) opened at launch and closed at the next launch; retire
  .session-seq/.provenance/.bump/.hands-off/.interactive/.session-loop.budget
  and the roles/staleness/lineage cluster that infers what this record states.
  This is the structural fix; medium-high risk, needs the test suites rewritten
  around behaviour not golden strings.
- **D-C Shared lib + collapse hooks** (F4): `scripts/lib/workspace.sh`; one hook
  dispatcher parameterized by runtime/event; functions out of the two
  straight-line scripts. Mechanical, low risk.
- **D-D Claude-first, adapters as explicitly "unverified"** (F5): keep the
  adapter seams but gate non-claude paths behind a verified-flag and stop
  documenting them as supported until a rollover has run on them.
- **D-E One doc, one skill, one rule** (F7, F8): resolve the contradictions;
  split context-budget.md into a ~150-line daily loop + fleet/supervisor
  reference; assertion-only instruction files (move incident narrative to
  ADRs/postmortems); one boundary skill that branches internally.
- **D-F Make recording a side effect, not a memory** (F7): record on commit /
  turn-end hooks rather than "at every boundary".
- **D-G Downloader hygiene** (F9): neutral env defaults, guide section, remove
  dangling paths.

## 5. User decisions (2026-09-14, session 5, at WARN — findings phase closed)

1. **Appetite: cleanup + structural redesign.** All of D-A, D-C, D-E, D-G plus
   the D-B single-lifecycle-record redesign.
2. **Runtimes: first-class = Claude, Codex, GitHub Copilot, Gemini.** Others
   (opencode; treat copilot CLI vs VS Code as one "Copilot" scope decision to
   confirm) are a follow-up if they are a lot of work; fold them in if not much
   more. First-class means the plan must include actually exercising a rollover
   on each of the four and fixing what breaks.
3. **Fleet dispatch machinery: KEEP.** User asks: *what is the best way to
   maintain it?* The plan must answer this (e.g. isolate it as its own script
   /module with its own suite and doc, gated fleet-only, not entangled with the
   daily loop; or fold its per-child measurement into the lifecycle record).
4. Test posture: not asked; plan proposes rewriting around behaviour where a
   suite pins golden strings (recommended alongside D-B).
5. User chose **roll over now**; the successor continues with the PLAN phase.

## 6. Successor pickup (Part 2 = the plan)

Next session: read this file top to bottom (it is the whole findings state; do
not re-run the review agents). Then, per plan-mode Phase 2, launch up to 3
Plan agents with the findings + decisions above as context, from distinct
perspectives: (a) the lifecycle-record redesign and migration path from the
current 7 state files; (b) maintainability of the fleet machinery + the four
first-class runtime adapters (how to structure, test, and verify each); (c)
docs/DevX consolidation and downloader hygiene. Synthesize into a phased plan
(tracer-bullet order, each phase independently shippable, verification per
phase), write it here as Part 2, then ExitPlanMode. Execution planning
(tickets / work item) comes after the user approves Part 2.
