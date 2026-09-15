# Session-management subsystem review — findings (Part 1)

> Status: FINDINGS DRAFT for user review. The plan (Part 2) is written only after the
> findings and direction are finalized with the user.
> **Session 6 (2026-09-14) gate, set by the user mid-session:** local was checked
> against origin (already up to date; PRs #54–#60 merged in session 5). NO
> implementation planning until the suggested changes have been (1) re-evaluated
> against current main, (2) reviewed by an independent architect agent, and
> (3) evaluated against the usage scenarios and flows. Three Plan agents that had
> started designing the implementation were stopped. Results land below as
> Part 1b.
> **Process set by the user (2026-09-14, session 6) — four stages, in order:**
> (1) research + evaluation of the suggested changes (Part 1b: re-evaluation vs
> current main, architect review, scenario/flow evaluation); (2) design and
> architecture (Part 2: the target design, no implementation detail); (3) evaluate
> the design/architecture against the usage scenarios and flows + an independent
> architect review, iterate until it is schematically and fundamentally sound
> (Part 3); (4) only then plan the implementation (Part 4). Each stage ends with
> the user's go before the next starts. Sources: three parallel review
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

---

# Part 1b — Stage 1: research + evaluation of the suggested changes (2026-09-14, session 6)

> Three independent agents, run after the origin check (local main already
> carried PRs #54–#60): (1) re-evaluation of every finding against current
> main; (2) an architect review of D-A..D-G as scoped by §5; (3) an evaluation
> of the directions against the usage scenarios and the three control-flow
> loops. Full reports (file:line evidence, VERIFIED/INFERRED tagged) are in
> `evaluation/stage1-*.md` next to this file. This section is the synthesis.
> **Stage 2 (design + architecture) does not start until the user resolves
> the decisions in §1b.5.**

## 1b.1 Re-evaluation against current main (report: `stage1-reevaluation-vs-main.md`)

**No finding was invalidated by PRs #54–#60; the structural ones got more true.**

| Finding | Verdict | What changed |
|---|---|---|
| F1 core sound | HOLDS | — |
| F2 modelling gap | HOLDS, worse | seq-carrying files ×7→**×9** (`.next-command.json`, `.chain-closed`); "rollover happened" ×3→×5; liveness oracles ×3→×4. #60 *adds* an inference mechanism (consumption event discarded, reconstructed from timestamps at chain start); #54 adds `.chain-closed` with two copies of its gate; #55 tightens an existing check only. |
| F3 retired surface | HOLDS | Sentinel + 122-line suite, shim, `session_handoff.md`, max-wins unchanged. `check --session-id` is now a *third* per-child measurement surface. |
| F4 duplication/shape | HOLDS, worse | Scripts 1454/1318/1002 LOC (session-loop +280); loop body 345 lines / 23 halt sites; runtime tables an explicit "must stay in step" pair (launch:597-613 ↔ cb:381-393); new `$PPID` contract. |
| F5 one runtime exercised | HOLDS | Ledger 275 claude / 0 other. Three opencode hook stamps from Aug 5-6 exist (hook fired once, nothing registered). |
| F6 supervisor evidence | PARTLY | Page wording fixed; the cited downstream evidence (`docs/session-chain-scenarios.md`, `work/session-loop-hardening/`) **does not exist in this repo** — a new dangling reference. "Ended cleanly?" answers ≈5→8. |
| F7 concept count | HOLDS, worse | +6 concepts; two (`sidecar`, `.stale`) with zero docs. |
| F8 doc contradictions | HOLDS | WARN ask/don't-ask, `--mode interactive`, ROLLOVER_RELAUNCH 4 statements / 3 values, sentinel still documented, index omits supervisor. **Corrections:** `CHECK_EVERY` *is* documented (cb.md:940); the "Status: Open" prose claim was wrong. `--reset-cap` partly addressed. |
| F9 downloader leakage | HOLDS | Same 5 dangling paths + env defaults; guide/README/CONTEXT untouched. |
| F10 small defects | HOLDS | `.pending-clear-seed` still unignored; NOTIFY/ROOT now 4 sourcing sites; ADR-0009 `/clear` item open (strongly inferred harmless: transcript basename = session id, but **`/clear` has never run on this machine** — 20 transcripts, 0 `/clear`). |

New surface the findings did not cover: `.next-command.json/.stale`, `.chain-closed`, `--reopen`, `--relaunch-override`, `check --session-id`, `successor_advisory`, G1-a off-gate, P4a/P4b predicates, ~+617 test LOC (mostly golden-string).
Direction premises: D-A intact; D-B strengthened (record must carry staged/consumed/closed); D-C gains two targets; D-D superseded by §5.2; D-E/D-G strengthened.

## 1b.2 Architect review of the directions (report: `stage1-architect-review.md`)

| Direction | Verdict | Amendments / rejections |
|---|---|---|
| D-A delete retired surface | **AGREE** | Nothing on the list is load-bearing. Add: `watch` (its "hook-less runtimes" layer is dead), `.rollover-options` cross-checkout adoption, stray-seq reporting. No GC code: widen the existing 7-day purge. |
| D-B one lifecycle record | **AGREE with amendments** | "Launcher sole author" is impossible: the successor's id is born at its own `register`; the supervisor owns the chain budget. Shape = one schema, **three writers with disjoint fields** through ONE lib helper (launcher: `launch`/`staged`; context-budget.sh: `session`/`seq`/`options`; session-loop.sh: `chain`). Roles collapse to "am I the record's session". Liveness = pid+pid_start first, artifact-mtime fallback. Also retire number reclaim, the resumed-predecessor fingerprint, `--unstage`'s rewind (ADR-0008 precedent: gaps stay, ledger annotates). Migration: flag-day between chains, one-time seq import; risk medium — the cost is the suites (~half of 600+ assertions pin log text; fixtures copy single scripts). |
| D-C shared lib + one dispatcher | **AGREE**, precondition for D-B | ADR-0006 explicitly rejected a shared lib because suites copy single scripts → amend the ADR, land a fixture helper with the lib. Wiring files stay (M31 untouched); opencode JS plugin untouched. |
| D-D verified-flag | **REJECT the flag** | Speculative configurability. Facts belong in a verification-row table + the existing `--live` harness. Real precondition for §5.2: five per-runtime touchpoints spread over seven "keep in sync" sites → one adapter table. Supervisability: unsupervised rollover seam exists for all four; supervised chains = claude + codex (+ copilot-CLI unproven); gemini has no exit hook and a constant `workspace` id; copilot-vscode has no process. The logout classifier is claude-JSON-shaped: a codex logout closes a chain today. |
| §5.3 keep fleet | **AGREE for `dispatch-*`/`children`; AMEND** | Do **not** fold into the record (different lifetimes, a fourth writer). Isolate as `scripts/fleet.sh` + own suites + own doc, zero references from the daily loop. Delete `watch`. The transitive child-lock hierarchy (runs inside every rollover/release, no incident behind it, depends on the roles D-B retires) → relocate or delete. |
| D-E docs | AGREE | Fix the contradictions now; consolidate after the cut; never edit vendored `handoff`. |
| D-F recording as side effect | AGREE, narrowed | A 3-line escalation-time ledger append in hook-lib; reject the git-commit-hook variant. |
| D-G downloader hygiene | AGREE | Five dangling paths verified. `ROLLOVER_RELAUNCH=auto` vs ADR-0004 `manual` is a user decision (this repo is template *and* instance). |

**Top 5 hidden couplings a design must handle:** (1) successor identity across the launch→register gap (the `successor-pending` handshake; the `claude --bg` env-survival claim is unverified); (2) identity re-keying with a stable launch (`/clear`, IDE resume, fork) — seq must bind to the launch; (3) no positive liveness for copilot-vscode/gemini; silence-kill meaningless for shared-artifact runtimes; (4) runtime-specific end facts the record cannot hold (logout sniff, M12 first-turn STOP); (5) fixtures copy single scripts, tests pin log text, and a live supervisor reads its script by byte offset.

**Architect's "simplest design" (input to Stage 2, not yet the design): 7 kept concepts** — per-session registry minus roles; one per-item record (`seq`/`launch`/`session`/`staged`/`chain`/`options`) via one helper; pid-first liveness; a 3-verdict supervisor (*staged* / *quit* / *broken*); one adapter table + one hook dispatcher; isolated `fleet.sh`; launcher/ledger + one boundary skill. Full text: `stage1-architect-review.md` §7(d).

**Live hazard found (act before any edit to `session-loop.sh`):** the supervisor for this item (pid 72900) was started *before* commit a213b3d added 292 lines to `session-loop.sh`. Bash reads scripts by offset; the process is now running against a file that changed under it (it already left an orphan `.next-command.json`). The chain must be ended deliberately (Ctrl-C at the next interactive pause) before that file is touched again, and the first commit to it should be a `main "$@"` wrapper so this cannot recur.

## 1b.3 Scenario and flow evaluation (report: `stage1-scenario-evaluation.md`)

Scenarios in scope: S1–S10, E1/E2/E5/E6/E9/E11/E12/E13/E16/E17, I1–I8/I10 (excluded E3/E4/E7/E8/E10/E14/E15/E18/I9: product-knowledge, no session-management surface). §A of the report walks each loop (measure / rollover / supervise) as it runs today and as it would run under the directions, marking every user-visible change.

| Verdict | Scenarios | Why |
|---|---|---|
| **YES** | S1, S3, S5, E9, E12, E13, I3, I4 (needs an amending ADR), I8, S9 (once two defaults are decided) | Directions cover them; verification = probes V1/V3/V8/V11 below. |
| **PARTLY** | S2 | `--clear` relaunch has never run here; ADR-0009's rotation question open. |
| PARTLY | S4 | Roles go, the lock stays; dead-holder liveness rule undecided (C.4). |
| PARTLY | S6 | The record captures the *launch* fact; the *disposition* at exit is still unobservable — the lineage gate's reclaim/refuse rule needs a chosen replacement (C.3). |
| PARTLY | S7 | Attended rollover possible on all four runtimes; supervised chains only claude/codex/copilot-CLI (gemini: no exit hook, constant identity; copilot-vscode: `--emit` refused, launch:732-734). |
| PARTLY | S8 | Keep + isolate; children/dispatch keep their own mtime liveness. |
| PARTLY | E11/E16/I2/I5/I6/I7/I10 | Same causes as above per row (report §B). |
| NEUTRAL | S10/E17 | Easier later iff the record keeps `user` and stays gitignored; WORSE if tracked. |
| NO CHANGE | E2 | Out of scope. |

Catalog contradictions: `scenarios.md` I5/E16 and `ground-truth.md` §D list roles as best-tested — D-B deletes them (catalog edit + test rewrite); `gaps-and-coverage.md` Gap 1 (non-local liveness heartbeat) is compatible with pid liveness + a kept `user` field, multi-user stays future work; CONTEXT.md:286 `--mode interactive` still wrong.

**Verification catalogue (report §D, 13 end-to-end probes, all with explicit-env threshold overrides so STOP arrives in a few turns, ~10–30K tokens each):** V1 attended rollover; V2 `--clear` + rotation check; V3 three-session supervised chain; V4 kill -9; V5 plain exit/reopen; V6 logout (fixture); V7 concurrency + dead-holder reclaim; V8 worktree; V9a–c attended on codex/copilot-CLI/gemini (gemini needs an API key first); V9d supervised codex + copilot-CLI; V10 fleet with parent rollover; V11 clean clone (extend `test-template-instantiation.sh`); V12 doc-consistency grep; V13 resumed predecessor. Test posture: 168 `assert_contains` on prose in `test-session-loop.sh` alone → propose one new token, `reason=<code>` on halts, so behaviour tests pin codes not sentences.

## 1b.4 Where the three reports disagree or reinforce each other

- All three independently found the same four new state files and the same "inference re-added by #60" pattern; the D-B premise is now stronger than when the findings were written.
- Architect and scenario agent independently reject "launcher sole author" and converge on writers-with-field-ownership.
- Architect says drop `watch`; scenario agent notes deleting `watch` removes the hook-less delivery fallback (S9 note) — the design must say what a runtime with no hooks does (answer candidate: nothing; it is unsupported, documented as such).
- Scenario agent proposes dropping `--clear` unless probe V2 confirms rotation; the architect keeps it as one of two relaunch paths. Resolved by running V2 (cheap) before Stage 2 fixes the relaunch model.
- D-F: the architect narrows it to an escalation-time append; the scenario agent warns per-turn records change what the ledger *means* (three readers depend on work-unit semantics: launch:507-511, session-loop:949-961). Design must pick "escalation-time append only" or redefine the ledger.

## 1b.5 Decisions the user must make before Stage 2 (design)

> **RESOLVED 2026-09-14 (session 6): the user accepted all 17 recommendations as written.**

Recommendations are the agents' where they agreed; marked ⚖ where they did not.

1. **Record writers.** Accept three writers with disjoint field ownership through one helper (launcher / context-budget.sh / session-loop.sh), i.e. drop "launcher sole author". *Recommended: yes.*
2. **Session numbers.** Never reclaim a number; gaps are annotated in the ledger. Deletes the lineage gate's evidence legs, the resumed-predecessor fingerprint and `--unstage`'s rewind. *Recommended: yes (ADR-0008 precedent).*
3. **Orphaned record (S6).** What replaces the lineage gate when a session never came back: (c) always close as `abandoned` and mint N+1, or (b) reclaim iff no measurement/commit since open. *Recommended: (c), simplest; it changes the "two doors" contract wording.*
4. **Dead lock holder (S4).** Replace 3-hour artifact-mtime staleness with pid+pid_start liveness; mtime fallback only for copilot-vscode/gemini; fleet child locks keep mtime. *Recommended: yes.*
5. **`--clear` relaunch (S2).** ⚖ Run probe V2 first (does `/clear` rotate the transcript JSONL?). Keep `--clear` only if it passes; otherwise drop it and supersede ADR-0009. *Recommended: run V2 during Stage 2, decide on evidence.*
6. **Mode markers.** Delete both `.hands-off`/`.interactive` (rely on `--loop-mode` + the interactive pause), or keep exactly `.interactive`. *Recommended: delete both unless you have ever touched them by hand.*
7. **`--takeover`.** Keep as the single human override (overwrite the owner slot, logged). *Recommended: yes.*
8. **Chain budget vs session tokens.** Keep the chain budget as its own `chain` block in the record, named distinctly from per-session tokens. *Recommended: yes.*
9. **Copilot scope.** First-class Copilot = the CLI (process, `agentStop`, supervisable); VS Code agent mode = attended rollover only. *Recommended: CLI.*
10. **Gemini contract.** Accept "gemini = attended (unsupervised) rollover only" as its first-class contract, or fund the `AfterAgent` exit-hook probe (needs a Gemini login/API key). *Recommended: attended-only for now; probe if cheap.*
11. **Fleet.** Isolate `dispatch-*` + `children` in `scripts/fleet.sh` with own suite/doc; delete `watch`; drop the transitive child-lock hierarchy from the launcher and `release`. *Recommended: yes.*
12. **Live chain.** End the pid-72900 chain deliberately (Ctrl-C at the next interactive pause) before `session-loop.sh` is edited; first commit to that file = `main "$@"` wrapper. *Recommended: yes. Note: this item's own rollovers run through that supervisor.*
13. **Log text as contract.** `.session-loop.log` messages become free-form; tests pin exit codes, record fields and `reason=<code>` tokens. *Recommended: yes (follows §5.4).*
14. **D-F scope.** Escalation-time ledger append in hook-lib only; `record --label` stays optional annotation; ledger keeps work-unit semantics. *Recommended: yes.*
15. **Template defaults (S9).** `ROLLOVER_RELAUNCH=manual` at root with this repo's `auto` carried in a committed per-item override; `SESSION_LOOP_KILL_AFTER=0`; `jq` promoted to a hard `req` (every hook exits 0 silently without it). *Recommended: yes to all three.*
16. **Record is gitignored and keeps a `user` field** (keeps S10/E17 open later without designing multi-user now). *Recommended: yes.*
17. **`claude --bg` env check.** Authorise a one-minute probe of whether `claude --bg` preserves the launcher's environment (launch:1184), which decides whether the `successor-pending` handshake file can be retired. *Recommended: yes.*

## 1b.6 What Stage 2 takes as input

Stage 2 writes the design and architecture (Part 2): the record schema and its writers, the liveness rule, the supervisor's verdicts, the adapter table and the per-runtime support matrix, the fleet module boundary, the boundary skill, the doc set, and the test posture — as a design, not a phase plan. Inputs: this Part 1b, the three `evaluation/stage1-*.md` reports (the architect's §7(d) is the seed), the resolved decisions above, and results of the cheap probes (V2, V11-baseline, the `--bg` env check) if authorised. Stage 3 then evaluates that design against S1–S10 / E / I and the three loops with a fresh architect + scenario pass; Stage 4 plans implementation.

## 1b.7 Binding design constraint (user, 2026-09-14): reliable, repeatable, reproducible

The subsystem is operated by an LLM agent that can forget or hallucinate.
Therefore, for Stage 2 and after:

- **No load-bearing step may depend on the agent remembering, judging, or
  truthfully reporting.** Every fact the subsystem acts on is measured from
  disk or written by a script at the moment it is known (F1/F2 already point
  this way). Skill text may *explain*; it may not be the only thing that makes
  a step happen.
- **Every step is mechanically gated.** Register, record, seq assert, bump,
  stage, consume, close: each is a script with an exit code, and the next step
  refuses to run if the previous one's evidence is missing. An agent that
  skips a step gets a refusal, not a silent gap.
- **Repeatable:** the same inputs (record on disk, transcript, env) give the
  same verdict on every run of every runtime; verdicts are codes
  (`reason=<code>`), not prose, so tests and humans read the same thing.
- **Reproducible:** every probe in the verification catalogue is a script a
  downloader can run, with pass criteria the script checks itself; no probe's
  pass is a sentence an agent typed.
- **Where the agent must act** (write the ledger and launcher, run the
  rollover), the script verifies the artefact afterwards (file exists,
  headings present, seq matches) and blocks the launch otherwise — the
  existing `seq-sync` assertion is the pattern.

Bearing on §1b.5: strengthens 1 (script-written record), 2/3 (no agent
judgement about reclaim), 13 (codes over prose), 14 (hook-driven ledger,
`record --label` never load-bearing), and rules out any design where a skill
instruction is the sole guarantee of a state transition.
