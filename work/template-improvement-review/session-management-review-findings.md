# Session-management subsystem review — findings (Part 1)

> Status: Stage 1 ACCEPTED (Part 1b). Stage 2 design drafted (Part 2, session 7).
> **Stage 3 DONE (Part 3, session 8, 2026-09-15): three independent reviews, all
> "sound with amendments"; design v2 drafted in plain language with the consensus
> amendments applied (`evaluation/stage3-design-v2.md`, supersedes Part 2 once
> accepted). Awaiting the user's three decisions (Part 3) and go for Stage 4.**
> Probe evidence for Part 2 (V2 `/clear` = ROTATES; `claude --bg` env = captured
> and replayed) is in `evaluation/stage2-probes.md`.
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

---

# Part 2 — Stage 2: design and architecture (2026-09-14, session 7)

> Target state of the session-management subsystem, shaped by Part 1 §1–§5, Part 1b (all 17 decisions accepted; §1b.7 binding), the architect's §7(d) seed, the scenario report's §A/§C/§D, and the two Stage 2 probes (`evaluation/stage2-probes.md`). A design, not a plan: no phases, no tickets. Citations are `file:line` on main `a213b3d`, verified by grep/sed unless marked INFERRED. cb = `scripts/context-budget.sh`, launch = `scripts/launch-next-session.sh`, loop = `scripts/session-loop.sh`, hook-lib = `scripts/hooks/context-budget-hook-lib.sh`.

## (a) Concepts kept

| # | Concept | One-sentence definition | Replaces (today) |
|---|---|---|---|
| 1 | **Per-session measurement record** | `.context-budget/sessions/<rt>-<sid>.json` `{runtime, session_id, artifact, project, pid, pid_start, supervisor_pid, registered_at, user}`, written by `register`, measured from disk by `check`/`record`; id-keyed artifact re-resolution stays (cb:125-138). | Same file minus `role`/`superseded_*` (cb:869-881); `parent_session_id`/`depth` move to fleet (g). |
| 2 | **One per-item lifecycle record** `work/<p>/session-state.json` | The single file that says what launch is open on a work item, who owns it, what is staged, and the chain budget — three writers, disjoint fields, one lib helper (b). | `.session-seq`, `.session-seq.provenance.json`, `.session-seq.bump.json`, `.next-command(.json/.stale)`, `.active-session`, `.rollover-options`, `.session-loop`, `.session-loop.budget`, `.chain-closed`, `.hands-off`/`.interactive`, `.rollover-complete`, `.pending-clear-seed`, `.context-budget/successor-pending-<p>.json` (architect §2a). |
| 3 | **Liveness = pid + pid_start first** | A recorded owner is live iff `kill -0 pid` and `ps -o lstart` equals `pid_start` (cb:697-723 already captures both); artifact-mtime only where no pid exists; `--takeover` the single override (c). | `lock_holder_age` + `CONTEXT_LOCK_STALE_SECS=10800` (cb:562-577, launch:777-783), `sweep_stale_primaries`/`backstamp_superseded` (cb:634-679), `holder_process_note` (launch:812-835). |
| 4 | **Three-verdict supervisor** | `session-loop.sh` decides *staged* / *quit* / *broken* from record fields + rc + one transcript question, with `reason=<code>` (d). | 23 halt sites, `staged_stale_reason`/`consumer_since` (loop:554-643), four bump checks (loop:908-921), `.chain-closed` (loop:885-889), min-lifetime record-mtime leg (loop:949-961). |
| 5 | **One adapter table + one hook dispatcher** | Per-runtime facts in one place; `scripts/hooks/context-budget-hook.sh <runtime> <event>` (f). | Seven "keep in sync" sites (cb:352, 360-374, 381-391, 402-407; launch:613, 755-761, 1155); five bash wrappers (claude/codex/copilot/copilot-vscode/gemini) + `rollover-clear-seed.sh`. |
| 6 | **Isolated fleet module** `scripts/fleet.sh` | `dispatch-*`, `children`, child registration and child locks, with their own state, suites and doc; zero references from the daily loop (g). | Same verbs inside cb (cb:449-457, 590-632, 1050-1243), child-lock sweep inside the launcher (launch:854-867) and `release` (cb:986-1014). |
| 7 | **Launcher/ledger + one boundary skill with mechanical gates** | `next-session.md`/`handoff.md` unchanged in role; one skill whose every load-bearing step is a script verb with an exit code and written evidence (h). | `session-rollover` (495 lines) + `checkpoint` tie-break duplicated (checkpoint SKILL.md:24-27), `seq-sync`/`supervised`/`record` agent-run verbs (skill:174-228, 315-348). |

Excluded, one line each: **roles** (ADR-0005) — "owner = the record's session" is a derived boolean, no scenario needs four names. **Lineage gate + reclaim + fingerprint + `--unstage` rewind** (launch:485-584) — decision 2/3. **`watch`** (cb:1112-1127) — hook-less delivery layer, every runtime has a hook; deleted (decision 11). **`rollover-complete`** + its suite — nothing reads it (hook-lib:142-148 is the one-release fallback). **Mode markers** — decision 6. **`MIN_LIFETIME` floor** — earned only by M12 on gemini (loop:945-947), and gemini is not supervised (decision 10); the *freshness* leg it carried survives as a record predicate (d). **`check --session-id`** stays as is (reads the registry, not item state; cb:411-444). **Stamp GC** — the existing 7-day purge (cb:802) is widened to `hook-*`; no new code.

## (b) The record: `work/<p>/session-state.json`

Gitignored (`.gitignore` gains one line and loses twelve of :34-63), common-dir-rooted like every file it replaces (ADR-0006; `link-local-work.sh` already links ignored `work/<p>` into worktrees, hook-lib:41-42). Every write goes through `record_update <project> '<jq filter>'` in `scripts/lib/session-lib.sh`: read → `jq` → temp file in the same directory → `mv` (atomic rename), refuse with `reason=schema_mismatch` when `schema != 1`, stamp `written_by`/`written_at` on the block the filter touched. No locking: the lifecycle orders the writers (supervisor writes before `eval`, launcher writes while the supervisor waits, `register`/`release` at session edges) and hooks other than `register`/`release` never touch the record (stamps/status stay per-session files, hook-lib:44-52). Writers: **launcher** (`launch`, `staged`, `seq`), **context-budget.sh** (`session`, `options`), **session-loop.sh** (`chain`); one deliberate shared touch: the supervisor *clears* `staged` before `eval` (consumption).

```json
{
  "schema": 1,
  "project": "template-improvement-review",
  "seq": 7,
  "launch": {
    "launched_at": "2026-09-14T22:18:41Z", "by": "session", "path": "emit",
    "mode": "interactive", "reason": "Stage 2 design",
    "predecessor": {"seq": 6, "runtime": "claude", "session_id": "b8ab07fd-…", "disposition": "rolled_over"},
    "pending": null,
    "written_by": "launch-next-session.sh", "written_at": "2026-09-14T22:18:41Z"
  },
  "session": {
    "seq": 7, "runtime": "claude", "session_id": "0f2c…", "pid": 35849, "pid_start": "Sun Sep 14 22:18:44 2026",
    "artifact": "/Users/kashif/.claude/projects/…/0f2c….jsonl", "registered_at": "2026-09-14T22:18:45Z",
    "source": "startup", "user": "kashif@mbp", "supervisor_pid": 72900,
    "rollover": null, "verified_at": null, "ended": null,
    "written_by": "context-budget.sh", "written_at": "2026-09-14T22:18:45Z"
  },
  "staged": null,
  "chain": {
    "supervisor": {"pid": 72900, "pid_start": "Sun Sep 14 17:55:58 2026", "started_at": "2026-09-14T22:55:58Z"},
    "used": 3, "cap": 10, "opened_at": "2026-09-10T00:20:11Z", "last_seq": 7, "closed": null, "reopened_at": null,
    "written_by": "session-loop.sh", "written_at": "2026-09-14T22:18:40Z"
  },
  "options": {"approval": "default", "model": "", "extra": [], "written_by": "context-budget.sh", "written_at": "2026-09-14T22:17:02Z"}
}
```

| Field | Single writer (script · verb) | Moment | Invariant the next step refuses on | Retires |
|---|---|---|---|---|
| `schema`, `project` | lib, on first write | record creation | any reader: `schema == 1` else `reason=schema_mismatch` | version skew class (§0.3 of the scenario report; `budget_read` halt loop:264-274) |
| `seq` | launcher · bump (exception: `register --project` on a record-less item opens `seq = ledger-top+1 \| 1`, `launch.by=adhoc` — the ADR-0008:107-109 ad-hoc self-heal, taken once at open) | the first write of a launch (launch:872-874 today) | monotonic, never reclaimed; `session.seq == seq` for the owner; `staged.successor == seq` | `.session-seq`, provenance sidecar, `seq-sync` verb (cb:1249-1315), stray-seq/max-wins scans (launch:461-474, rollover-prep:164-181) |
| `launch` | launcher · bump | same write as `seq`; the same write nulls `session` (the slot is released — launch:1117 today) | `predecessor.disposition ∈ {rolled_over, stopped, abandoned}` is set at the bump from the previous `session` (see below); `pending` is `{pid, pid_start, prompt, expires_at}` on the `clear`/`bg`/`exec` paths (nulled by the successor's `register`; TTL 600 s as cb:830) and `null` on `emit` (env binds) | `.session-seq.bump.json`, `.next-command.json`, `successor-pending-<p>.json` (as a file), `.pending-clear-seed`, `.hands-off`/`.interactive` (mode is `launch.mode`, set only by `--loop-mode`) |
| `session` | cb · `register` (fill/adopt), `rollover-start` (`rollover`), `verify` (`verified_at`), `close`/`release` (`ended`) | SessionStart hook or agent-run `register --project`; the rollover verbs; SessionEnd | owner iff `session.session_id == mine`; `register` refuses the slot while the owner is live and not me (`reason=owner_live`); `rollover-start` refuses a non-owner (`reason=not_owner`); `verify` refuses without `rollover`; launcher refuses without `verified_at > rollover.started_at` | `.active-session` (the slot *is* the lock), `role` and the four-role vocabulary, `own_record()` fallback (launch:631-641), `attach-session.sh fork_of()` (attach:89), resumed-predecessor fingerprint (launch:522-566) |
| `staged` | launcher · `--emit` (write); supervisor clears before `eval` | at emit; at loop top | supervisor: `staged.by.session_id == child's session_id ∧ seq == seq_before+1` (d); bootstrap: `staged` present ∧ `session.seq == staged.successor` ⇒ `reason=staged_spent` | `.next-command`, `.next-command.stale`, `staged_stale_reason`/`consumer_since` (loop:554-643), P4a/P4b file tests (loop:730, 751) |
| `chain` | session-loop.sh · start / iteration / quit / `--reopen` | marker at start (loop:437-438); `used` before the child starts (loop:278-286 semantics kept); `closed` on quit | launcher and supervisor refuse when `closed != null` (`reason=chain_closed`); `used < cap` else `verdict=cap` | `.session-loop`, `.session-loop.budget`, `.chain-closed`, `supervised` verb's env arm (cb:972-975) |
| `options` | cb · `opts-sync` (agent) and `rollover-start` (adapter capture, claude only) | prep | none (replayed by the launcher; malformed → `reason=options_invalid`) | `.rollover-options`, `capture-rollover-options.sh` as a script (becomes an adapter function), cross-checkout adoption (launch:933-949) |

**Orphaned record (decision 3).** At the bump the launcher classifies the previous launch from `session`: caller is the live owner (or adopted it) → `rolled_over`; `session.ended.door == "stop"` → `stopped`; owner absent or dead → `abandoned`, and the number is spent — `seq` still advances to N+1. The launcher prints the brief (what it found: `session.registered_at`, last ledger line, `git log --since`) and the successor's prompt carries "session N was abandoned" so the ledger block N+1 can annotate the gap; nothing rewinds. A live owner that is not the caller → `reason=owner_live` (remedy: `register --project p --takeover` from the session, or `--takeover` on the human launch path). `check-ledger.py` validates heading shape and order, not contiguity (check-ledger.py:4-7; contiguity is INFERRED not enforced), so a gap needs no grammar change.

**Lib helper interface** (`scripts/lib/session-lib.sh`, sourced by the three writers, the dispatcher, `rollover-prep.sh`, `attach-session.sh`, the statusline; the resolver duplicated in 12 files, cb:28-40 etc., lives here too):

```
record_path <project>                      # $WORKSPACE_ROOT/work/<p>/session-state.json
record_read <project>                      # prints JSON; exit 4 reason=record_unreadable|schema_mismatch
record_update <project> <writer> '<jq>'    # atomic; stamps .written_by/.written_at on the touched block
record_owner_live <project>                # 0 live / 1 dead-or-absent, per (c)
adapter_<field> <runtime>                  # (f); one case per field
reason <code> [detail…]                    # prints "refused reason=<code> …" or "verdict=<code> …"; exit 4 for refusals
```

**The record through one supervised iteration** (what each writer sees, S3 shape; `N` = the session that just ran):

| Moment | `seq` | `launch` | `session` | `staged` | `chain` | Written by |
|---|---|---|---|---|---|---|
| supervisor start | N | (prev) | (prev owner or null) | non-null or null | `supervisor` set, `used` | session-loop.sh |
| bootstrap, nothing staged | N+1 | `by=supervisor`, `path=emit` | null | `{successor:N+1, by:{supervisor}}` | — | launcher (`--emit`) |
| consume → `eval` | N+1 | — | null | **null** | `used+1`, `last_seq=N+1` | session-loop.sh |
| successor registers | N+1 | — | `{seq:N+1, sid, pid…}` | null | — | cb `register` (env binding) |
| session N+1 rolls over (`--emit`) | N+2 | `by=session`, `predecessor:{seq:N+1, disposition:rolled_over}` | **null** (slot released at the bump) | `{successor:N+2, by:{sid of N+1}}` | — | launcher |
| turn-end hook | — | — | — | reads `staged.by.session_id == mine` → SIGTERM `$PPID` | — | dispatcher (read-only) |
| verdict | `seq == seq_before+1` ✓ | — | `registered_at > launched_at` ✓ | `by == child` ✓ | — | session-loop.sh → `verdict=staged` |
| quit instead (`/exit`, nothing staged) | N+1 | — | dead | null | `closed:{at, by_seq:N+1, reason:quit_plain}` | session-loop.sh |

The unsupervised paths differ in two rows only: `launch.path ∈ {exec, clear, bg}`, `staged` is never written, and `pending` carries the binding until the successor's `register` nulls it.

**How the successor's `register` finds its record** — resolution order, first hit wins: (1) explicit `--project`; (2) `TF_SESSION_PROJECT` + `TF_SESSION_SEQ` in the environment (attached `exec` and supervisor `eval` paths); (3) a record whose `launch.pending.pid`/`pid_start` equals this process's (the `/clear` path — same process, new sid); (4) the freshest record with an unexpired `launch.pending` and `session == null` (the `--bg` path only). Detail and evidence in (e). `register` never guesses a project from mtime of *registry* records; a session that resolves nothing registers project-less and measures only.

## (c) Liveness rule per runtime

Positive liveness is asked of the record's `session.pid`/`pid_start` (or a child lock's, in fleet). `--takeover` (decision 7) is the single override: `register --project p --takeover` (session-side) and `launch-next-session.sh p --takeover` (human-terminal path, no session identity) overwrite the owner slot and log `reason=takeover` with the loser's identity; no record stamping (roles are gone).

| Runtime | Positive liveness source | Fallback | Silence-kill allowed (supervisor `KILL_AFTER`) |
|---|---|---|---|
| claude | pid + pid_start (argv0 walk, cb:704-716) | artifact mtime if the record carries no pid (registered from outside the process tree) | yes — per-session JSONL (docs/context-budget.md:893) |
| codex | pid + pid_start | same | yes — per-session `rollout-*.jsonl` (docs:894) |
| copilot-cli | pid + pid_start | same | yes — per-session `events.jsonl` (docs:896) |
| gemini | pid + pid_start (a `gemini` process exists; identity, not liveness, is the constant `workspace`, cb:389) | `.gemini/telemetry.log` mtime — shared, so "live" means *some* gemini session | **no** — shared artifact (architect §2d) |
| copilot-vscode (follow-up) | none — no process (cb:700-702) | `chatSessions/<sid>.jsonl` mtime | n/a — never supervised (launch:732-734) |
| opencode (follow-up) | pid | shared sqlite db | **no** |

Fleet child locks keep artifact-mtime liveness (a subagent leaves only `agent-*.jsonl`; scenario §C.4) — inside `fleet.sh` only.

## (d) Supervisor

`session-loop.sh` becomes `main() { … }; main "$@"` first (decision 12; bash reads by offset, the pid-72900 chain must be ended at its next pause before that commit). Per iteration: `budget` from `chain` (`used` written before `eval`, unchanged rationale), read `staged` → CMD → clear `staged` → hash `next-session.md`/`handoff.md` → `eval` → verdict from the record **R**, the child's rc, and one adapter question `logout_for <runtime> <artifact>` ∈ {yes, no, unknowable}:

| Verdict | Predicate | `reason=` | Effect |
|---|---|---|---|
| **staged** | `R.staged != null ∧ R.staged.by.session_id == child.session_id ∧ R.seq == seq_before+1 ∧ (flush hashes changed) ∧ R.session.registered_at > R.launch.launched_at ∧ R.session.seq == seq_before` | `staged` | next iteration (interactive: pause first) |
| **quit** | `R.staged == null ∧ R.seq == seq_before ∧ rc == 0 ∧ logout ≠ yes` | `quit_stop` (`R.session.ended.door == stop`), `quit_plain` (no door); suffix `logout=unknowable` on codex/copilot-cli | write `chain.closed = {at, by_seq, reason}`, notify, exit 0 |
| **broken** | anything else | `rc_nonzero`, `logout` (refund `used`, no close), `seq_moved_unstaged`, `seq_delta`, `staged_by_mismatch`, `flush_missing`, `no_own_measurement`, `record_unreadable`, `schema_mismatch`, `stall` | halt, exit 1, `chain` untouched |

`child` = `R.session` as captured by the alarm probe once the successor registered (pid, pid_start, artifact — one read replaces `child_probe`'s lock + registry join, loop:150-162). What each retired mechanism becomes: `staged_stale_reason`/`consumer_since` → bootstrap predicate `R.staged != null ∧ R.session.seq == R.staged.successor` ⇒ `reason=staged_spent`, clear and stage afresh via the launcher `--emit` (tagged `launch.by=supervisor`; the `$PPID` ancestry test launch:702-711 goes); four bump checks (loop:908-921) → the one `staged_by_mismatch` leg; `.chain-closed` → `chain.closed` (launcher gate launch:338-343 reads the same field; `--reopen` sets `closed = null`, `reopened_at`); the min-lifetime "measurement of its own" (loop:949-961) → `R.session.registered_at > R.launch.launched_at` (both script-written; the lifetime floor is deleted, see (a)). Chain cap → `verdict=cap`, exit 0 at start or end (loop:290-297 kept). `ROLLOVER_RELAUNCH=off` gate → `reason=relaunch_off` unless `--relaunch-override`.

**Bootstrap and loop, in order** (replaces loop:328-649 refusals + bootstrap and the 345-line body):

1. `record_read` → refuse `record_unreadable` / `schema_mismatch`; `chain.closed != null ∧ !--reopen` → `chain_closed`; `chain.supervisor` live → `supervisor_live`; `ROLLOVER_RELAUNCH=off ∧ !--relaunch-override` → `relaunch_off`; `--reset-cap` under a live supervisor → refused.
2. Write `chain.supervisor = {pid:$$, pid_start, started_at}`; `--reopen` → `closed = null`, `reopened_at`. `trap` clears `supervisor` on EXIT (loop:441 semantics kept).
3. `chain.used ≥ cap` → `verdict=cap`, exit 0.
4. `staged` present ∧ `session.seq == staged.successor` → `staged_spent`: clear it. `staged` absent → launcher `--emit --loop-mode <mode>` tagged `by=supervisor` (refusals propagate as `broken`).
5. Loop: read `staged.command` → clear `staged` → hashes → `chain.used+1` → start alarm subshell → `eval` → reap → verdict table above → interactive pause → repeat.

**Interactive pause** unchanged: `read </dev/tty`, Enter/Ctrl-C (loop:982-996), `reason=pause_interrupted` on Ctrl-C.

**Stall/alarm probe and the attended false page (policy).** Silence is `now − mtime(child.artifact)` and is asked only of runtimes whose adapter says `liveness_oracle = per-session-artifact` (c). Pages: `past_stop_unstaged` (P4a) and `staged_still_alive` (P4b, two ticks) are record facts and fire in both modes; `silent` and `killed_silent` fire in `handsoff` only — under `interactive` the human is the stall detector (the same reasoning the stall guard already applies, loop:970-972), which ends the two idle-at-a-prompt pages of 2026-09-14 (2055 s, 2847 s). `KILL_AFTER` default 0 (decision 15) and never armed in interactive mode.

## (e) Launch → register identity binding (couplings 1 and 2)

The successor's session id is born at its own `register`; the launch must be bindable to it without the agent. Evidence (`evaluation/stage2-probes.md`): **Probe B** — the environment reaches the SessionStart hook on an attached `claude -p` and on a *cold* `claude --bg`, but a second `--bg` 40 s later replayed the first launch's value because the daemon pre-forks spare sessions from the spawning caller's environment (`ps -E` on the daemon and on a spare showed the stale value). So env can carry the launch identity on the attached and supervised paths and **cannot** on `--bg`; launch:1184's comment ("must survive daemonization") is true in effect, false in mechanism, and the file handshake stays for `--bg` — relocated into the record. **Probe A** — `/clear` rotates: `SessionEnd(reason=clear)` then `SessionStart(source=clear)` with a new sid and a new JSONL; the old file froze at the clear instant; the process (pid) is the same.

| Path | Carrier of the launch identity | Binding test in `register` | Why |
|---|---|---|---|
| attached `exec` (launch:1311-1313) | `TF_SESSION_PROJECT`, `TF_SESSION_SEQ` exported by the launcher | env names the record; refuse if `seq != TF_SESSION_SEQ` (`reason=pending_mismatch`) | direct child of the launcher's shell; probe B's `-p` line |
| supervisor `eval` (`--emit`) | same two vars exported by `session-loop.sh` (as `TF_SESSION_LOOP_PROJECT` today, loop:436) | same | already the D14 fix (cb:815-827); env verified to reach Stop hooks (`.codex/config.toml:10-13`) |
| `--clear` (claude only) | `launch.pending.pid/pid_start` = the launching process; `pending.prompt` = the seed | `RUNTIME_PID/pid_start == pending.pid/pid_start` on `source == clear`; the dispatcher then returns `pending.prompt` as `additionalContext` and clears it (the `rollover-clear-seed.sh` role, folded) | exact, no heuristic; same process by probe A |
| `--bg` (claude only) | `launch.pending` with `expires_at` (600 s) | freshest unexpired record with `session == null`; **the launcher refuses a `--bg` while any other record's `pending` is unexpired** (`reason=pending_elsewhere`) — closes the D14 swap by construction instead of by TTL | env unusable (probe B); vendor `--name` is not in the hook payload (INFERRED) |

**Adoption rule** (replaces `own_record()` fallback, `fork_of()`, the fingerprint): `register` resolving record *p* whose `session != null` and `session.session_id != mine` adopts the slot — keeping `seq` — iff the owner is dead (c) **or** `session.pid == mine` (`/clear`); it logs `reason=adopted_resume | adopted_clear`, sets `session.source`. A live different owner → `reason=owner_live`, registered as non-owner (measured, never writes item state) unless `--takeover`. IDE resume (new sid, new pid, old process gone — cm_bugs 2026-09-03) and the D4 fork (launch:1106-1109) are the "owner dead" branch; no evidence legs.

**`--clear` decision (decision 5): KEEP.** V2 = ROTATES, so per-session accounting keys on transcript file = session and ADR-0009's open item closes as verified. Consequences for ADR-0009: (i) the open item (ADR-0009:141-148) is replaced by the probe's evidence; (ii) `.pending-clear-seed` and `rollover-clear-seed.sh` are folded into `launch.pending.prompt` + the dispatcher (also fixes F10's gitignore defect); (iii) two adapter caveats are recorded — the claude measure filters records by camelCase `sessionId` (the snake_case `session_id` on some records is stale), and the harness must run with `CLAUDE_CODE_CHILD_SESSION` unset (or `CLAUDE_CODE_FORCE_SESSION_PERSISTENCE=1`) or no transcript is written. The selection rule (same MCP set → `--clear`; different fragment/runtime/`--bg` → spawn) stands.

## (f) Runtime adapter table + support matrix

One table in `scripts/lib/session-lib.sh` (`adapter_<field> <runtime>`), replacing the seven enumerations. First-class: claude, codex, copilot-cli, gemini (decisions 9, 10). Follow-ups: copilot-vscode, opencode.

| Field | claude | codex | copilot-cli | gemini |
|---|---|---|---|---|
| discover | `~/.claude/projects/<slug>/<sid>.jsonl` | `~/.codex/sessions/…/rollout-*-<id>.jsonl` | `~/.copilot/session-state/<id>/events.jsonl` | `.gemini/telemetry.log` (shared) |
| measure | last main-chain `message.usage` sum, records filtered by camelCase `sessionId` == sid | last `last_token_usage.total_tokens` | `promptTokens`/`input_tokens`, else bytes÷4 | last `input_token_count`; reset at register (docs:898) |
| session-id source | `CLAUDE_CODE_SESSION_ID`, else basename (cb:382) | `CODEX_THREAD_ID`, else rollout id (cb:383, 404) | `COPILOT_AGENT_SESSION_ID`, else dirname (cb:384, 405) | constant `workspace` (cb:389) |
| env identity (runtime detection) | `CLAUDECODE`/`CLAUDE_CODE_ENTRYPOINT` (cb:344) | `CODEX_SANDBOX`/`CODEX_HOME` (cb:345) | none → newest-artifact heuristic (cb:352-357) | none → heuristic |
| launch command form | `claude --name "<p> #N" [--bg] <opts> "<prompt>"` (launch:1156-1157) | `codex <opts> "<prompt>"` | `copilot <opts> -i "<prompt>"` | `gemini <opts> -i "<prompt>"` |
| register hook | SessionStart (transcript path in payload) | first `UserPromptSubmit` fire registers (side effect, project-less) | `sessionStart` registers | `BeforeAgent` registers |
| exit-hook kind (turn-end SIGTERM `$PPID`) | `Stop` (stop-hook) | `Stop` — fired live 2026-08-26 (`.codex/config.toml:10-13`) | `agentStop` (copilot-hook:32-33) — never fired here | **none** (`AfterAgent` unprobed, gemini-hook:9-18) |
| in-band channel | PostToolUse stderr + exit 2 | `hookSpecificOutput.additionalContext` | `additionalContext` at start; `{decision:block}` at STOP | JSON `additionalContext` / `{}` |
| liveness oracle | pid; per-session artifact | pid; per-session | pid; per-session | pid; shared artifact |
| `logout_for` | `isApiErrorMessage ∧ authentication_failed` (loop:233-240) | unknowable (no captured shape) | unknowable | n/a (not supervised) |

**Coupling 4 (logout classifier)** is owned by the adapter: `logout_for` answers *unknowable* on codex/copilot-cli until a live logout transcript is captured as a fixture; the supervisor's quit verdict then carries `logout=unknowable` so the gap is visible in the code path and in tests, instead of a codex logout silently reading as a deliberate quit (today loop:854-857 never matches there).

**One hook dispatcher** `scripts/hooks/context-budget-hook.sh <runtime> <event>`, events `session-start | turn | turn-end | session-end`, one `case "$runtime:$event"` producing each vendor envelope byte-for-byte (`test-vendor-budget-hooks.sh` is the net). Wiring files stay (M31): `.claude/settings.json`, `.codex/config.toml` (one re-trust prompt), `.gemini/settings.json`, `.github/hooks/*.json`; the opencode JS plugin is untouched and keeps calling the old argument shape through a two-line shim. **A hook-less runtime does nothing**: no `watch`, no polling; it is unsupported and the support matrix says so.

| Runtime | Attended rollover (S1/S2) | Supervised chain (S3) | Reason |
|---|---|---|---|
| claude | **supported** — 275 ledger records, chains here | **supported** | only runtime ever exercised (F5) |
| codex | unverified → V9a | unverified → V9d | `Stop` fired live once (2026-08-26, probe log uncommitted); no rollover ever run |
| copilot-cli | unverified → V9b | unverified → V9d | `agentStop` wired, never fired; `trustedFolders` gate (copilot-hook:7-8) |
| gemini | unverified → V9c (needs auth) | **unsupported** | no exit hook; constant identity; shared artifact |
| copilot-vscode | follow-up (attended by design) | **unsupported** | no process; `--emit` refused (launch:732-734) |
| opencode | follow-up | follow-up | plugin untouched; shared db |

## (g) `scripts/fleet.sh` boundary

Moves there wholesale: `dispatch-contract | dispatch-open | dispatch-close | dispatch-list` (cb:1129-1243), `children` (cb:1050-1110, claude-only), child registration (`register --parent-session … --agent-id …`, cb:449-457, 856-862 → `fleet.sh register-child`), child locks `.agent-locks/` with artifact-mtime liveness and the I4 bottom-up release order (cb:590-632, 916-948) — all of it inside fleet. Own state: `work/<p>/.agent-locks/`, `work/<p>/.agent-dispatch/`, registry records with `parent_session_id`/`depth`. Own suites: `test-children-sweep.sh`, `test-dispatch-contract.sh`, `test-dispatch-records.sh` (already separate) → `test-fleet-*.sh`. Own doc: `docs/fleet.md` (today docs:802-883).

**Interface to the daily loop at runtime: none.** The launcher and `release` stop sweeping `.agent-locks` (launch:854-867, cb:986-1014 — decision 11); the parent's pre-rollover drain (`fleet.sh dispatch-list`, exit 1 iff a generation is open) is a step in the fleet doc and in the boundary skill's optional fleet branch, not a launcher call — the dispatch contract (report file + yield status) already survives a parent rollover by design (successor reads the report), so a missed drain is a fleet-side inconvenience, not an integrity failure. `successor_advisory` keeps its "a sub-agent is not the chain" test by `parent_session_id` (cb:549) — a registry read, no fleet import.

## (h) The boundary skill and the mechanical gates (§1b.7)

**One skill, `session-rollover`, two doors as an internal branch** (`continue` = stage/launch a successor; `stop` = close without one). `checkpoint`'s tie-break (checkpoint SKILL.md:24-27) becomes the skill's first line — measurement wins — and `skills/checkpoint/` is deleted; `/checkpoint` maps to `session-rollover --door stop`. Vendored `handoff` is not edited and not pointed at. The alternative (two skills sharing a table) is the duplication F7 measured. `record --label` remains optional annotation. Escalation-time ledger append lives in hook-lib (decision 14): the WARN/STOP transition (hook-lib:70-71) appends `{label:"escalation:<status>"}`; the ledger keeps work-unit semantics.

| Step | Script · verb | Exit | Evidence written | The NEXT step refuses when… (`reason=`) |
|---|---|---|---|---|
| register | dispatcher `session-start` → `cb register [--project p]` | 0 | registry record; `session` filled or adopted (b/e) | — (measurement never blocks); rollover verbs refuse a non-owner (`not_owner`) |
| measure | dispatcher `turn` → `cb check` | 0/1/2 (OK/WARN/STOP), 3 usage | `.stamp`/`.status`; on escalation a ledger line | — |
| escalate | hook-lib message in-band; `successor_advisory` on `record`/`register` | — | — | — (prose nudge; the gates below are what enforce) |
| prep | `rollover-prep.sh p [--reason]` → `cb rollover-start --project p` | 0; 4 refusal | `session.rollover = {started_at, ledger_hash, launcher_hash}`; `options` captured; handoff archive rotated | `verify` refuses without `session.rollover` (`prep_missing`); `rollover-start` refuses a non-owner (`not_owner`) |
| write-ledger (agent) | — | — | `handoff.md` top block `# Session Handoff — N` | `verify`: top block ≠ `session.seq` (`ledger_seq_mismatch`), `check-ledger.py` non-zero (`ledger_shape`), hash unchanged (`ledger_unchanged`) |
| write-launcher (agent, continue door) | — | — | `next-session.md` replaced | `verify`: hash unchanged (`launcher_unchanged`) |
| verify-artefacts | `cb verify --project p --door continue\|stop` | 0; 4 refusal | `session.verified_at` | launcher/`close` refuse without `verified_at > rollover.started_at` (`unverified`) — the `seq-sync` pattern, now on the artefacts instead of the counter |
| stage-or-launch (continue) | `launch-next-session.sh p [--emit \| --clear \| --bg \| bare] [--loop-mode m --loop-reason r]` | 0; 4 refusal | `seq`+1, `launch`, `staged` (emit) or `pending` (clear/bg/exec) | refusals: `unverified`, `not_owner`, `owner_live`, `chain_closed`, `supervised_stage_only` (bare/`--clear` under a live `chain.supervisor`; the launcher decides supervision from `chain.supervisor` pid liveness — the agent's exit-2 "stage anyway" rule (skill:321-348) is deleted because ambiguity no longer exists), `staged_unconsumed` (a `staged`/`pending` for seq N+1 with `session == null`, V13; remedy `--unstage` = mark N+1 `abandoned`, clear it, next launch mints N+2 — no rewind), `runtime_path_unsupported` (`--clear`/`--bg` off claude), `pending_elsewhere`, `worktree_unsynced` (L33 guard kept) |
| close (stop door) | `cb close --project p` | 0; 4 | `session.ended = {at, door:"stop"}` | next launch classifies `stopped`, no brief |
| consume (supervised) | `session-loop.sh` clears `staged` before `eval`; successor `register` fills `session` | — | — | verdict `staged_by_mismatch` etc. (d) |
| end | dispatcher `session-end` → `cb release` | 0 | `session.ended = {at, reason:<vendor>}` when the runtime reports one (claude `SessionEnd.reason`) — advisory over liveness | — |

What a skipping agent sees, in every case: `refused reason=<code>` on stdout, exit 4, and the one command that repairs it. Nothing is silently skipped; nothing is inferred from prose. Two examples:

```
$ scripts/launch-next-session.sh template-improvement-review --emit      # skipped prep + verify
refused reason=unverified project=template-improvement-review seq=7
  run: scripts/context-budget.sh verify --project template-improvement-review --door continue
$ scripts/context-budget.sh verify --project template-improvement-review --door continue
refused reason=ledger_seq_mismatch expected=7 top_block=6 file=work/template-improvement-review/handoff.md
  write the "# Session Handoff — 7" block, then re-run verify
```

The skill's six agent-facing steps collapse to: prep → write the two files → `verify` → launcher (continue) or `close` (stop). The launcher chooses `--emit` vs spawn/`--clear`/`--bg` itself from `chain.supervisor` liveness and `ROLLOVER_RELAUNCH`; the agent passes only `--loop-mode`/`--loop-reason` (interactive when the successor must ask a human something, CONTEXT.md:291-293).

## (i) Doc set — one rule, one place

| Document | Owns | Fate |
|---|---|---|
| `docs/session-management.md` (new, ≤250 lines) | the daily loop: measure, escalate, the record schema (b), liveness (c), identity binding (e), adapter + support matrix (f), reason codes (j) | replaces `docs/context-budget.md` §1–§8 and §Multi-session/Worktrees/Adapters/Hooks/Registration/Ledger; change-log narrative moves to ADRs (k) |
| `docs/session-supervisor.md` (new) | `session-loop.sh`: verdicts, knobs, signals, false-page policy (d) | replaces docs:383-640; fixes the missing index entry (F8) |
| `docs/fleet.md` (new) | `fleet.sh` (g) | replaces docs:802-883 |
| `docs/work-directory-conventions.md` | launcher/ledger roles; "two doors" rewritten: plain exit → `abandoned` at the next launch, no reclaim | edited |
| `CONTEXT.md` "Context Budget" | the three sentences an agent needs + links; the WARN rule stated once | shortened; `--mode interactive` (CONTEXT.md:293) → `--loop-mode`; CONTEXT.md:269 "ask" resolved below |
| `skills/session-rollover/SKILL.md` | the boundary skill (h), ≤150 lines | rewritten; `skills/checkpoint/` deleted |
| `context-budget.env` | knobs, assertion-only comments (no incident narrative, env:50-93) | root defaults: `ROLLOVER_RELAUNCH=manual`, `SESSION_LOOP_KILL_AFTER=0`, `CONTEXT_LOCK_STALE_SECS` deleted (liveness is pid), `SESSION_LOOP_MIN_LIFETIME` deleted; this repo's `auto` in committed `work/<item>/context-budget.env` (precedent: `work/automatic-session-rollover/context-budget.env`) |
| `scripts/check-dependencies.sh` | `jq` is `req` (already :39); the hooks stop exiting 0 silently without it — `check` prints `reason=jq_missing` once per session via the stamp | edited |
| `docs/adr/0010–0012` | the why (k) | new |
| deleted/folded | `docs/context-budget.md`, `test-rollover-sentinel.sh`, the sentinel rows (docs:414, 442, 951), `session-chain-scenarios.md` references (docs:228, 773, ADR-0009:112), the five `repos/ai-workspace-template/…` paths (docs:172, 897, 1011, 1019; skill:51) | — |

**WARN rule (one place).** CONTEXT.md:269 and ADR-0004:46-50 say *ask*; skill:29-31 says *do not ask*. Resolution without a new knob: at WARN the agent asks iff `ROLLOVER_RELAUNCH` resolves to `manual`/`off`; under `auto` it rolls without asking — `auto` is already defined as standing authorization (CONTEXT.md:289). The template default `manual` therefore gives downloaders "ask"; this repo's per-item `auto` gives the operator "do not ask". Recorded as an amendment to ADR-0004 (k).

**Downloader hygiene (decision 15, V12).** One value per knob everywhere; no dangling paths; retired names appear only under `docs/adr/` and `docs/archive/`. Enforced by `scripts/tests/test-doc-consistency.sh` (V12): greps the retired-name list and the path list, and asserts every `ROLLOVER_RELAUNCH=` literal in docs equals the root env default. `scripts/tests/test-template-instantiation.sh` gains the file-level half of V11 (hooks tracked, gitignore lines present, env defaults neutral).

## (j) Test posture

Behaviour tests pin three observable things: **exit code**, **record fields** (`jq` on `session-state.json` and the registry), and **`reason=<code>`**; `.session-loop.log` and every `note`/`die` sentence are free-form (decision 13). `assert_contains` on prose (168 in `test-session-loop.sh`, 286 in `test-launch-next-session.sh`) is replaced by `assert_reason <code>` and `assert_field <jq-path> <value>`.

**Fixture helper** (ADR-0006 amendment): `scripts/tests/lib/fixture.sh` → `make_workspace [--worktree]` copies `scripts/*.sh`, `scripts/lib/`, `scripts/hooks/`, and `context-budget.env` into a `mktemp` git repo (initial commit, optional worktree) and returns its root; every suite uses it instead of `cp` of single scripts (e.g. test-context-budget-registry.sh:10, test-session-loop.sh:12, test-emit-mode.sh:13). Suites: **deleted** `test-rollover-sentinel.sh`, `test-seq-sync.sh` (verb gone), `test-rollover-clear-seed.sh` (hook folded); **merged** `test-emit-mode.sh` → `test-launch-next-session.sh`, `test-session-numbering.sh` → `test-session-record.sh`; **renamed** `test-vendor-budget-hooks.sh` → `test-hook-dispatcher.sh`, `test-children-sweep.sh`/`test-dispatch-*.sh` → `test-fleet-*.sh`; **new** `test-session-record.sh` (lib helper: atomicity, schema refusal, field ownership, adoption rule), `test-liveness.sh` (pid+pid_start incl. recycled pid, mtime fallback), `test-verify.sh` (the gates of (h)), `test-doc-consistency.sh` (V12). `test-turn-end-exit.sh --live <runtime>` (test-turn-end-exit.sh:5-7) is the live harness for V9d.

**Probe catalogue** (from scenario §D; every pass criterion is checked by the probe script itself; live probes run with `CONTEXT_DUMB_ZONE_TOKENS`/`_WARN_TOKENS` overrides so STOP arrives in a few turns):

| Probe | Scenarios | Kind | Self-checked pass criterion |
|---|---|---|---|
| V1 attended rollover | S1, E9, I3, I4, I8 | live, human gate (one paste) | record: `launch.predecessor.disposition=rolled_over`, `seq` advanced by 1, successor `session.seq == seq`; ledger 2 blocks, `check-ledger.py` 0; no retired file under `work/<p>/` |
| V2 `/clear` rotation | S2, ADR-0009 | **done** (probes.md) — rerun as live, human gate | new sid + new JSONL; `record` tokens near 0; `pending.prompt` drained (null) |
| V3 three-session chain | S3, I2 | live, unattended | log verdicts `staged` ×3 then `cap`; `chain.used=3`; no `broken` |
| V4 kill -9 mid-chain | S6 | live | `reason=rc_nonzero`, `chain.closed == null`; restart classifies `abandoned`, mints N+1 |
| V5 plain exit / stop door | S6, E11 | live | `quit_plain`/`quit_stop`; `chain.closed` set; bare launcher → `chain_closed`; `--reopen` clears |
| V6 vendor logout | S6 | fixture | `reason=logout`, `used` refunded, `chain.closed == null` |
| V7 concurrency + dead owner | S4, E16, I5 | live ×3 | second session → `owner_live`; after kill -9 → `adopted_resume` without waiting |
| V8 worktree | S5, E12 | live | record in main checkout only; M16 re-pin note; launcher ff-push |
| V9a–c attended on codex / copilot-cli / gemini | S7, I1 | live, vendor gates | that runtime's first ledger line; launcher prints/execs the adapter's command form |
| V9d supervised codex + copilot-cli | S7 | live | rc 143 verdict `staged`; two-session chain |
| V10 fleet + parent rollover | S8, I6 | live | `dispatch-list` exit 1 before rollover; successor re-dispatches gen 2; `children` measures both |
| V11 clean clone | S9, E1, E5, I7, I10 | scripted (+ one live start) | `check-dependencies.sh` fails without `jq`; hooks register with no manual step; no background launch under `manual` |
| V12 doc consistency | D-E, D-G | scripted | zero retired names outside `docs/adr/`, `docs/archive/`; zero dangling paths; one `ROLLOVER_RELAUNCH` value |
| V13 resumed predecessor after staging | S6 | live | second launch → `staged_unconsumed`; `--unstage` → `abandoned`, next mints N+2 |

**Canonical `reason` codes** (the list lives in `scripts/lib/session-lib.sh`; the doc table is checked by V12):

| Emitter | Codes |
|---|---|
| `register` | `owner_live`, `adopted_resume`, `adopted_clear`, `takeover`, `pending_mismatch`, `pending_expired`, `no_record` (info) |
| launcher | `not_owner`, `owner_live`, `unverified`, `chain_closed`, `supervised_stage_only`, `staged_unconsumed`, `runtime_path_unsupported`, `pending_elsewhere`, `worktree_unsynced`, `options_invalid`, `ledger_gap` (warn), `schema_mismatch` |
| `rollover-start` / `verify` / `close` | `not_owner`, `prep_missing`, `ledger_seq_mismatch`, `ledger_shape`, `ledger_unchanged`, `launcher_unchanged`, `unverified` |
| supervisor verdicts | `staged`, `quit_stop`, `quit_plain`, `cap`, `pause_interrupted`, `staged_spent` (info), `relaunch_off`, `supervisor_live`, `budget_unreadable` |
| supervisor broken | `rc_nonzero`, `logout`, `seq_moved_unstaged`, `seq_delta`, `staged_by_mismatch`, `flush_missing`, `no_own_measurement`, `record_unreadable`, `schema_mismatch`, `stall` |
| alarm | `past_stop_unstaged`, `staged_still_alive`, `silent`, `killed_silent` |
| hooks | ledger label `escalation:WARN|STOP`; `jq_missing` |

Exit codes: `cb check/record` 0/1/2 (OK/WARN/STOP); every verb 3 = usage, 4 = refusal (`reason=` on stdout); supervisor 0 = chain ended (`quit_*`, `cap`, `pause_interrupted`), 1 = broken.

**Migration shape** (one paragraph, not a plan): flag-day between chains — end the pid-72900 chain at its next interactive pause, land `main "$@"`, then cut all three scripts to the record in one change with the suites rewritten alongside; the only compatibility code is a one-time import (`seq` from `.session-seq` when the record is absent, deleted after one release, the sentinel-shim precedent hook-lib:142-148); `.gitignore` swaps twelve lines for one.

## (k) ADRs

| ADR | Effect | By |
|---|---|---|
| 0003 automate relaunch | unchanged | — |
| 0004 multi-session model | **amended**: lock → record owner slot; staleness → pid liveness; "WARN asks" keyed to `ROLLOVER_RELAUNCH`; runtimes in scope → the support matrix (f); default `manual` restored at root | 0010, 0012 |
| 0005 roles + child registry | **superseded** for roles/lineage/`superseded_by` stamping; child registry part **moved** to fleet unchanged | 0010, 0012 |
| 0006 repository-keyed state | **amended**: the "no shared lib" consequence (ADR-0006:59-62) replaced by lib + fixture helper | 0010 |
| 0007 / 0008 session number | canonical-source and assertion rulings **kept**; mechanism (`.session-seq`, `seq-sync`) **superseded** by `seq` + `verify`; never-reclaim made explicit | 0010 |
| 0009 `/clear` relaunch | **amended**: open item closed by probe A; seed folded into `launch.pending`; measurement caveats recorded | 0010 |

**ADR-0010 — One per-item session-state record with three writers.** *Decision:* every fact about a work item's current launch lives in `work/<p>/session-state.json` (schema in (b)), written only through `record_update`, by the launcher (`seq`, `launch`, `staged`), `context-budget.sh` (`session`, `options`) and `session-loop.sh` (`chain`); numbers are never reclaimed, an orphaned launch closes as `abandoned` at the next bump; owner = the record's session, liveness = pid+pid_start with mtime fallback where no pid exists; identity binding per path as in (e). *Rejected:* launcher as sole author (the successor's id is born at `register`, ADR-0005:67-68); dual-write migration (keeps every inference path alive); env-only identity for `--bg` (probe B); tracked record (dirties every session, defeats the stall guard, collides across people — scenario §C.9); reclaiming numbers on evidence (the cluster D-B exists to remove).

**ADR-0011 — Mechanical gates and reason codes.** *Decision:* §1b.7 as a standing rule: every load-bearing step of the session lifecycle is a script verb with an exit code (`4 = refused`) that writes evidence to the record, and the next verb refuses on missing evidence; verdicts and refusals are `reason=<code>` tokens from one canonical list; log and message text is free-form and never a test contract; probes are scripts with self-checked pass criteria. *Rejected:* skill-text-only guarantees (three "I think I rolled over" incidents, hook-lib:74-77); golden-string tests (half of 600+ assertions pin prose, architect §2e); a `--json` output mode (speculative; the `key=value` line plus `reason=` is enough).

**ADR-0012 — Runtime contract: adapter table, support matrix, fleet isolation.** *Decision:* four first-class runtimes described by one adapter table and one hook dispatcher; a runtime is *supported* for a mode only after the corresponding probe (V1/V3/V9) has passed on it and its row says so; hook-less runtimes are unsupported (no polling layer); gemini and copilot-vscode are attended-only; fleet machinery lives in `scripts/fleet.sh` with its own state, liveness rule, suites and doc and is never called by the daily loop. *Rejected:* a `verified` flag gating code paths (speculative configurability, architect §4); folding per-child measurement into the record (wrong grain, fourth writer); keeping the transitive child-lock hierarchy in the launcher/`release` (no incident, depends on roles).

## (l) Explicit non-goals

- **Multi-user / second person (S10, E17)** — kept possible (record gitignored, `session.user`), not designed; Gap 1's non-local heartbeat stays future work.
- **VS Code agent-mode supervision** — no process to own or kill (copilot-vscode-hook:15-19); attended rollover only, as a follow-up.
- **opencode** — plugin untouched, shim only; follow-up runtime.
- **Gemini supervised chains** — no exit hook probed; attended-only contract (decision 10).
- **Per-turn or commit-hook ledger records** — escalation-time append only (decision 14); the ledger stays work-unit evidence.
- **Windows** — BSD/GNU `stat` fallbacks stay; nothing new.
- **Dual-write or long compatibility shims** — one-time `seq` import only.
- **Stamp GC subcommand, `--json` output, verified-flag, `watch`** — rejected above.
- **Editing vendored skills** (`skills/handoff`) — never.
- **`check --session-id`** — unchanged.

## (m) Open questions for Stage 3

1. **WARN rule keyed to `ROLLOVER_RELAUNCH`** (i): confirm that "ask iff manual/off" is the one rule, or name the alternative (a third consent knob was rejected as speculative).
2. **`--bg` binding** (e): the launcher-side `pending_elsewhere` refusal closes the D14 swap; is a freshest-unexpired scan still acceptable as `--bg`'s only binding, or should `--bg` be restricted to supervised chains (where env binds exactly), leaving `--clear` as the sole unsupervised hands-off path?
3. **Codex / copilot-cli logout shapes** (f): `logout=unknowable` until a live logout is captured as a fixture — who captures it, and is a quit-with-unknowable acceptable to close a chain meanwhile?
4. **`--unstage` spends a number** (h): an IDE restart after staging (V13) now costs a lineage gap (N+1 abandoned, N+2 minted). Accept, per ADR-0008's over-count precedent, or carve out "pending never consumed ⇒ reuse N+1" as the single exception to never-reclaim?
5. **Vendor exit facts** (h): claude's `SessionEnd.reason` (probe A: `clear`, `prompt_input_exit`, `other`) is recorded in `session.ended` as advisory; should Stage 3 promote it to a liveness short-circuit for claude, or leave pid liveness as the only oracle for symmetry across runtimes?

---

# Part 3 — Stage 3: evaluation of the design (2026-09-15, session 8)

> Three independent reviewers read the Stage 2 design (Part 2 above): an architect, a scenario-and-flow walker, and a developer who would implement it. Reports: `evaluation/stage3-architect-review.md`, `stage3-scenario-evaluation.md`, `stage3-developer-review.md`. This part synthesises them in plain language. The design rewritten with their amendments is `evaluation/stage3-design-v2.md`, which supersedes Part 2 once the user accepts it (Part 2 is left as the pre-review record rather than edited in place, because the user asked for a readable rewrite).

## Verdict

All three reviewers judged the design sound in its core and fit for implementation planning once a short list of amendments lands: architect "yes with amendments", scenario walker "sound with amendments", developer "yes after clarifications". The core they all endorse: one uncommitted state record per work item with three script writers; process liveness as the only ownership test; a supervisor with three verdicts; one runtime adapter table; fleet machinery isolated; every step a script that refuses with a reason code. Nothing found was structural. The scenario walk scored 30 rows: 15 handled, 12 partly (all fixable by the amendments below, or unchanged non-goals), 1 not (a team-shared repo, an explicit non-goal), 2 not applicable.

## Glossary for this part

Session (one run of an agent with one context window) · work item (a `work/` directory) · session number (never reused) · record (the one JSON state file per item) · owner (the session the record names) · rollover (handing work to a fresh session) · handoff ledger and launcher file (the two files a rollover writes) · staged command (the successor's launch command, left for the supervisor) · supervisor and chain (the script that runs sessions back to back) · verdict and reason code (the supervisor's outcome, and the token every refusal prints) · liveness (is the owner's process still running) · runtime adapter (one table row per agent runtime).

## What all three reviewers agree on

1. **The record and the supervisor contradicted each other.** The launcher empties the owner field when it advances the number, yet the supervisor's "staged" verdict then read that field. Fix: the launcher copies the outgoing owner into a predecessor block at the same atomic write, and the verdict reads only that block, the number before and after, and who staged the command.
2. **Delete the background-daemon launch path.** The probe showed the environment is captured by the first daemon and replayed into later sessions, so the launch can never be bound exactly, and the fallback (newest unexpired launch within a time window) could be claimed by any plain session a human started. The in-place restart remains the only unsupervised hands-off path.
3. **Delete the agent-run options sync.** The launcher captures the permission mode from the transcript at launch time; an agent that forgot the sync got no refusal, which violates the binding constraint.
4. **Process id plus start time is the only liveness oracle.** The vendor's exit reason is advisory at best (the end and start hooks can land in the same second) and is dropped from the record.
5. **At WARN the agent asks only when relaunch is set to manual or off.** No new consent knob.
6. **Strip the citations and migration bookkeeping.** Roughly a third of the text by characters was file-and-line citations; two of three sentences carried a pointer only this repo can resolve. Migration columns, doc fates, ADR tables and probe catalogues move to a Stage 4 appendix.
7. **Owner-only release.** The session-end hook changes nothing unless the record still names the calling session; it merges into the ended block, never replaces it.

## Amendments

| # | Change | Why | From | Status |
|---|---|---|---|---|
| A1 | Verdict reads the predecessor block written at the bump, not the owner field | owner field is empty by then; a watchdog snapshot could miss a short child | all three | consensus, in v2 |
| A2 | Delete the background-daemon launch path and its time-window binding | cannot bind exactly; claimable by any human start | all three | consensus, in v2 |
| A3 | Delete the separate prep and verify verbs; the launcher and close run the file checks inline, with a dry-run flag | the snapshot hashes trapped an agent that wrote the ledger before prep, and a verification stamp could go stale | architect (keep verify, drop snapshot) and scenario (inline) | consensus on direction; inline variant chosen, footnoted in v2 |
| A4 | Delete the options block and its agent-run sync; launcher captures at launch | forgotten sync had no refusal | architect, scenario | consensus, in v2 |
| A5 | Record helper takes a directory lock and every writer's filter carries a compare-and-set precondition | three real write races found (supervisor exit trap vs child, release vs register on restart, release vs close) | developer | uncontested, in v2 |
| A6 | A child may end its turn with a signal only when a supervisor is recorded live; hand staging without one is refused | otherwise a hand-run stage kills the session with nobody to launch the next | scenario | uncontested, in v2 |
| A7 | File checks fire only when the caller is a session, never on the supervisor's bootstrap launch; the number is exported per iteration; quit requires that the child registered | undefined in Part 2; a child that never registered and exited 0 would have closed the chain | scenario | uncontested, in v2 |
| A8 | Name the git stale-launcher guard as kept, with a code | it exists today and no section carried it forward | scenario | uncontested, in v2 |
| A9 | Cut unread record fields and merge the reason codes (about 45 to about 28) | nothing gates on them; stamps invite tests to pin them | architect, developer | consensus, in v2 |
| A10 | The tool-missing message is printed by a check before any JSON parsing | a hook without the JSON tool cannot parse its own payload | developer | uncontested, in v2 |
| A11 | The supervisor's stall guard watches the three markdown files, not the record | the record is uncommitted, so it drops out of the git-based guard | architect | uncontested, in v2 |
| D1 | Logout on Codex and Copilot CLI: drop the "unknowable" code or keep it | reviewers split | all three | **user decides** |
| D2 | A predecessor resumed after staging: occupy the open launch, or spend a number | architect vs the other two | all three | **user decides** |
| D3 | Session identity on Copilot CLI and Gemini is a newest-transcript heuristic: accept or require an explicit id | only the developer raised it | developer | **user decides** |

## Consolidated cut list

| Cut | What breaks |
|---|---|
| Background-daemon launch path, its time window and two refusal codes | hands-off relaunch with a different tool set from inside an unsupervised session; it prints the command instead |
| Separate prep and verify verbs, the rollover snapshot, the verification stamp, four codes | nothing; the launcher runs the same checks inline |
| The unstage verb, its code and its probe (if D2 = occupy) | nothing |
| Options block, agent-run sync, cross-checkout adoption | nothing; captured at launch |
| Per-block author stamps, vendor exit reason, duplicate supervisor pid, launch path and reason strings, chain timestamps | nothing reads them |
| About 17 reason codes merged into their families with a `key=value` detail | nothing; tests pin the detail the same way |
| Supervisor flush-hash check | nothing; the launcher's file gate already guarantees it |
| Follow-up runtime rows (VS Code agent mode, OpenCode) in the liveness and adapter tables | nothing; they are non-goals |
| Replaces/retires columns, doc-fate table, ADR amendment tables, probe catalogue, all file-and-line citations | nothing in the design; they become a Stage 4 appendix |
| A separate supervisor document | nothing, if the one session-management document stays under its line cap |

Kept on purpose: the staged-already-spent check at supervisor restart, the explicit stop door, the watchdog pages, takeover, the schema check, the chain block, the silence-kill knob (default off, the user's earlier call).

## Points needing the user's decision

1. **Logout on Codex and Copilot CLI.** Nobody has captured what a logout looks like on those runtimes. The developer would drop the "unknowable" code path entirely (those quits read as plain quits; the support matrix says "not classified"; a wrongly closed chain is reopened with one command). The architect and scenario walker would keep a `logout=unknowable` suffix so the gap is visible in tests. *Recommendation: drop it. Less code for a gap the matrix already states; the fixture gets captured by whoever first runs the supervised probe on those runtimes.*
2. **A predecessor resumed after it staged a successor** (for example an IDE restart). The architect proposes that whoever explicitly registers against an open launch simply becomes that session: no number spent, no unstage verb, no probe, and no judgement about whether anything was consumed. The developer and scenario walker would accept spending a number (refuse, mark abandoned, mint the next). *Recommendation: the architect's rule. It deletes a verb, a code and a probe, and is one sentence.*
3. **Session identity on Copilot CLI and Gemini.** The session id there is "the newest transcript", so the owner test is a heuristic. Accept and say so in the matrix while those runtimes are unverified, or require an explicit id flag. *Recommendation: accept; both runtimes are unverified and Gemini is attended-only.*

## Readability findings

The architect estimates two-thirds of sentences carry a token only this repo can resolve and about 40 percent of the text has no meaning outside it; the developer counts roughly 120 file-and-line citations, 60 decision or ADR ids and 50 scenario or probe ids, about 35 to 40 percent of the characters. Both list some 40 undefined terms and agree on 12 essential ones (the glossary above). Both recommend the same one-page shape: four diagrams (lifecycle, record and writers, supervisor decision, three loops), two-sentence explanations for liveness, identity binding and runtimes, a glossary, and footnoted pointers. Design v2 follows that shape: 158 lines, no ids in the body.

## What Stage 4 needs before planning

- The three decisions above.
- The live supervisor chain ended at its next pause before the supervisor script is edited; implementation done on a throwaway work item, not this one, since this item's own rollovers run through that supervisor.
- A committed per-item override keeping this repo on automatic relaunch when the root default flips to manual, in the same change.
- The one-time import of the old session counter scripted and tested before the flag day.
- Implementation order all three reviewers converge on: record helper and its tests; fleet extraction (a pure move); measurer verbs; launcher; supervisor (wrapper commit first); hook dispatcher; skill, docs, ignore file, env defaults. First end-to-end slice: an attended rollover on a stub runtime with no supervisor.
- Probe criteria to rewrite: the chain probe drops its prose criterion; the fleet probe drops the child-lock gate; two new suite-level cases (supervisor restart with a spent stage; the refused hand stage).
