<!--
ARCHIVE of work/automatic-session-rollover/handoff.md — older ledger blocks,
newest first. Moved here when handoff.md exceeds the two most recent blocks.
-->
# Session Handoff — 2026-08-06 (session 12: HTML review rendition shipped; STOP rollover at 155K mid-turn)

**What shipped (committed on `main`, pushed):**

- **`subagent-rollover-research.html` — `d93daea`:** standalone, self-contained
  HTML review rendition of the research note, restructured per user direction:
  problem (with the stats evidence) → the model (§2: roles/policy, verb,
  protocol, files, lock hierarchy, state machines, drain mode, invariants
  I1–I8 — with 5 hand-authored inline-SVG diagrams: system model, resume-vs-
  successor, lock hierarchy, child lifecycle, parent budget modes) → machinery
  already in place (§3) → findings (§4) → proposal R1–R8 + inventory (§5) →
  evaluation model (§6) → next steps. Light/dark via CSS tokens; no external
  deps. Diagrams visually verified in Chrome (3 label-overlap fixes applied
  pre-commit). The markdown note remains the raw record (footer says so).
- Tier-2 decision note (HTML-vs-Artifact) in `decisions.md`; claude-in-chrome
  `file://` gotcha routed to `docs/operational-knowledge.md`.

**Mid-turn user request (binding, NOT started):** enumerate rollover
*scenarios* — mainline functional plus corner/edge cases for resilience,
recoverability, and performance — to (a) keep in mind while working through
the doc and (b) drive evaluation, *before* any implementation. User asked
whether their dimension list misses anything (candidates to consider:
concurrency/contention incl. human attach during drain, observability/
auditability, cost/token-economy, schema evolution of records, degradation on
opaque runtimes, human-in-the-loop policy edges). Seed material: S1–S10 +
P1–P5 + §13 fault model already in the research doc — the new catalog should
extend, not duplicate, those.

**Rollover:** WARN fired mid-diagram-verification (134K), STOP (155K) two
edits later; wrapped the atomic step (commit `d93daea` + this ledger) and
rolled. Second consecutive session terminated on schedule by its own subject
matter.

# Session Handoff — 2026-08-06 (session 11b: subagent-rollover research phase; STOP rollover at 157K)

**What shipped (committed on `main`, pushed through `4fa0cdb`):**

- **`subagent-rollover-research.md`** (this work dir) — full research/design
  note on parent-managed child-session rollover: what transfers from
  main-session rollover, parent-as-manager policy mapping, successor-dispatch
  as the only rollover verb (resume worsens context), per-child files +
  dispatch records, lock hierarchy with transitive validity, drain-mode
  invariant (no parent rollover with live children), checkpoint/yield
  protocol (§8), 14-row rollover inventory (§9), delta requirements R1–R8
  (§10), vendor-agnostic layering (§11), depth/resilience model (§12),
  evaluation model — state machines, invariants I1–I8, scenarios S1–S10,
  fault properties P1–P5, cost model (§13).
- **`subagent-rollover-stats.md`** — measured: 30 subagent transcripts, 3
  crossed 120K WARN, max 141.8K (a *resumed* implementer), 0 ≥ 150K; claude
  child transcripts live at `<project-dir>/<parent-uuid>/subagents/agent-*.jsonl`
  with `.meta.json` siblings.
- **`subagent-vendor-survey.md`** — 4-runtime capability survey: only claude
  (and partially copilot) expose child identity; codex/gemini children are
  opaque; opencode forbids nesting; no runtime reports per-child usage.

**How it was produced:** three parallel background research agents (local
stats; Claude Code docs mechanics; live-CLI vendor survey) + controller
synthesis; user added mid-flight: vendor-agnostic requirement, the
communication protocol, the rollover inventory, and the evaluation model.

**Rollover:** STOP hook fired at 156,987 tokens right after the eval-model
section landed — the system being designed terminated its own design session
on schedule.

# Session Handoff — 2026-08-05 (session 8: plan execution started — Task 1 shipped; WARN rollover)

**What shipped (committed + pushed on `main`):**

- **Task 1 of `plans/2026-08-05-vendor-hook-deployments.md` — commit `4a39bf8`:**
  shared lib `scripts/hooks/context-budget-hook-lib.sh` (throttle /
  escalation-only / fail-open core, canonical WARN/STOP text);
  `context-budget-claude-hook.sh` refactored to a thin wrapper sourcing it
  (byte-identical messages; state files renamed `hook-claude-<sid>.*` — stale
  old files harmless); new suite `scripts/tests/test-vendor-budget-hooks.sh`,
  13 asserts green (T1 escalation, T2 throttle, T3 fail-open, T4 claude
  envelope).

**Session friction (resolved, no action needed):** primary checkout lagged
origin/main — session 7 had pushed its rollover commit from the worktree
branch; `git pull --ff-only` fixed it (the launcher's First-action warning
worked). The live claude hook fired WARN in-band at 121K right after plan
load — the push channel this whole item builds is demonstrably working.

**What did NOT happen:** Tasks 2–8 untouched (opencode runtime, codex/gemini/
opencode/copilot deployments, option inheritance, docs gate). Task 1 was
executed as the final work unit under WARN; rollover began at ~135K.

**Loose ends:** leftover locked worktree
`.claude/worktrees/vendor-hook-deployments` (branch fully merged into main) —
safe to `git worktree remove --force` + `git branch -d` when convenient.

**Suggested skills for next session:** `superpowers:executing-plans` on the
plan (Tasks 2–8); `session-rollover` at WARN/STOP.


# Session Handoff — 2026-08-05 (session 7: item #3 planned — vendor hooks + option inheritance; STOP rollover before execution)

**What shipped (committed + pushed from worktree branch
`worktree-vendor-hook-deployments`):**

- **Item #3 implementation plan, complete and self-contained:**
  `plans/2026-08-05-vendor-hook-deployments.md` — 8 tasks, all code inlined
  (no placeholders), TDD steps per task. Covers: shared hook lib extracted
  from the claude hook (Task 1); **new `opencode` runtime for
  context-budget.sh** (Task 2 — gap found this session: the script had no
  opencode branch; sqlite schema live-verified against
  `~/.local/share/opencode/opencode.db` v1.18.14: `message.session_id` +
  `json_extract(data,'$.tokens.total')`, session-column fallback); codex
  `UserPromptSubmit` (Task 3), gemini `BeforeAgent` (Task 4 — envelope pinned
  from bundled v0.46.0 reference.md: `hookSpecificOutput.additionalContext`,
  JSON-only stdout), opencode `chat.message` plugin (Task 5), copilot
  `sessionStart`+`agentStop` STOP-only block (Task 6); **successor option
  inheritance** (Task 7 — user request mid-session: approval mode + model
  replay via `work/<proj>/.rollover-options`, mapped per runtime in
  launch-next-session.sh); docs/backlog/decisions + full verification gate
  (Task 8).
- **Ops finding** routed to `docs/operational-knowledge.md`: EnterWorktree
  re-keys the Claude Code project dir — the live transcript moves, the
  registry artifact goes stale, and discovery misattributes another session's
  usage (a predecessor's 148K WARN read as ours; real reading was 45K then).
  Re-register after entering a worktree.

**What did NOT happen:** no plan task was executed — the session hit STOP
(171K, measured exact against its own worktree-keyed transcript) right after
the plan was written. Execution is entirely the successor's.

**User inputs this session (both folded into the plan, Task 7):** the
successor session must inherit the predecessor's options (approval/auto mode,
model, etc.), for all vendor agent types.

**Loose ends:** main checkout's `work/context-decay/context-ledger.jsonl` has
uncommitted rows (this session's record calls ran there); fold into the next
work commit. Session-5 ledger block moved to `handoff-archive.md` (2-block
rule).

**Suggested skills for next session:** `superpowers:executing-plans` (or
subagent-driven-development) on the committed plan; `session-rollover` at
WARN/STOP.


# Session Handoff — 2026-08-05 (session 6: implementation item #2 shipped — launch-next-session.sh; WARN rollover)

**What shipped (all committed + pushed, `b6d245a`, `d468f7c`, `ef42a12`):**

- **Item #2 complete.** `scripts/launch-next-session.sh` per ADR-0003/0004:
  verbatim bootstrap prompt (single source of truth in the script); runtime
  resolution --runtime flag > dying session's own registry record (D6,
  env-first identity mirroring `context-budget.sh session_id_for()`) > newest
  record for the project > `ROLLOVER_RUNTIME` > claude; 5 runtimes
  seeded-interactive (`claude` [+`--bg`], `codex` positional, `gemini -i`,
  `opencode --prompt`, `copilot -i` — all flags re-verified against live
  `--help` this session); modes off/manual/auto honored (auto+claude implies
  --bg); --bg claude-only (die otherwise); D8 successor confirmation poll
  after --bg (`ROLLOVER_CONFIRM_SECS`, default 120s, non-fatal); non-tty
  manual prints `run: <cmd>` instead of exec'ing a TUI; copilot-vscode
  degrades to prompt-only.
- **Tests:** `scripts/tests/test-launch-next-session.sh` — 13 cases /
  28 asserts, all green (dry-run flag assembly + stub-binary --bg/D8/timeout/
  non-tty paths). Registry suite still green (13/13).
- **Docs:** `docs/context-budget.md` §Rollover trigger policy status note
  flipped to implemented; backlog changelog row appended; four Tier-2 notes
  in `decisions.md` (tty guard, copilot-vscode degradation, --bg-only D8
  confirmation, always-print prompt); plan committed at
  `plans/2026-08-05-launch-next-session.md`; stale `workspace-structure.html`
  rebuilt.

**Where things stand:** items #1+#2 done; item #3 (four vendor hook
deployments) not started — next session's mission. Working tree clean apart
from the live `.active-session` lock (untracked by design).

**Suggested skills for next session:** superpowers:writing-plans →
executing-plans (the pattern items #1 and #2 both used successfully);
session-rollover at WARN/STOP.

# Session Handoff — 2026-08-05 (session 5: implementation item #1 shipped — session-keyed registry, lock, release, gemini guard; WARN rollover)

**What shipped (all committed + pushed, `15ec961`…`187f926` + rollover commit):**

- **Item #1 complete, M13 closed.** `scripts/context-budget.sh` migrated to the
  session-keyed registry per ADR-0004: `session_id_for()` (env-first identity,
  artifact-derived fallback, gemini fixed id `workspace`); resolve-self in
  `check`/`record` (own session file only, never another's);
  `.context-budget/sessions/<runtime>-<session-id>.json`; `register --project`
  acquires `work/<proj>/.active-session` (advisory: live holder warned never
  stolen; stale >`CONTEXT_LOCK_STALE_SECS` [new knob, 3h] reclaimed); new
  `release` subcommand (self-only, project defaults from own session record);
  gemini concurrent-session guard (fresh non-empty telemetry log → skip reset,
  degrade to chat-log estimate).
- **Tests:** `scripts/tests/test-context-budget-registry.sh` — 13 asserts, all
  green; T1 is the live M13 clobber repro (was red against the old scalar
  registry). Self-contained throwaway workspace in mktemp; fake $HOME.
- **Docs:** `docs/context-budget.md` (§Multi-session status → implemented;
  §Session registration rewritten for sessions/ + lock + release; gemini-only
  limitation para), `skills/session-rollover/SKILL.md` (release call after
  verification gate), backlog M13 → Resolved, new L16 (phantom test suite in
  workspace-structure.md, fixed same session), summary line → all 31 resolved.
- **Plan + decisions:** implementation plan at
  `plans/2026-08-05-session-keyed-registry.md` (all tasks checked off in
  execution, file committed with this rollover); three Tier-2 notes appended to
  `decisions.md` (identity derivation, advisory-not-blocking lock, gemini
  freshness guard).

**Verification state:** `bash scripts/tests/test-context-budget-registry.sh`
exits 0; live register/record in this session used the new registry and
correctly tracked this session's own transcript (dogfood: the WARN that
triggered this rollover came from it).

**Suggested skills for next session:** `superpowers:writing-plans` then
`superpowers:executing-plans` (same pattern as this session) for item #2;
`docs/context-budget.md` §Relaunch knobs is the spec.

# Session Handoff — 2026-08-05 (session 4: documentation phase shipped in one commit; WARN rollover into implementation phase)

Executed the session-3 launcher's documentation plan verbatim; no design was
reopened. Substance is in the committed docs themselves; this block is
provenance only.

- One commit, `9c6a097`, pushed to main: `docs/context-budget.md` gained
  "Rollover trigger policy" / "Relaunch knobs" / "Multi-session model"
  sections (each with an explicit design-accepted-implementation-pending
  status note) and corrected stale copilot-cli "unverified" claims (smoke
  test verified 73.0k exact); knob block landed in `context-budget.env`
  (`ROLLOVER_RELAUNCH=manual`, `ROLLOVER_RUNTIME=claude`);
  `skills/session-rollover/SKILL.md` gained hybrid trigger semantics, the
  hook-less cadence fallback (~10 exchanges), and the relaunch closing step
  (graceful when the script is absent); pointer lines in `CONTEXT.md` +
  `docs/workspace-structure.md`; ADR-0004 companion promoted from the three
  session-3 notes (Promote? fields flipped; ADR-0003 got a Refined-by link);
  `issues/01-vscode-agent-mode-hooks.md` ticket created; backlog card M13
  (registry-clobber bug, Open with approved fix) + scorecard updated.
- Doc-phase decision recorded in `decisions.md` (newest note): one companion
  ADR-0004, not an amended 0003 or four ADRs.
- Ops note: `workspace-structure.md`'s scripts tree already lists planned
  entries (`scripts/tests/` doesn't exist on disk), so the
  `launch-next-session.sh` tree line landing pre-implementation is consistent;
  `check-workspace-structure.sh` iterates existing scripts only.
- WARN (122.7K) fired at commit time; user approved rollover. Docs summary was
  presented; user raised no objections before approving — treat the doc set as
  baseline unless they say otherwise.

Suggested skills for the next session: `superpowers:writing-plans` or `tdd`
(implementation of the registry migration), `decision-log`,
`session-rollover` at the boundary.

---


# Session Handoff — 2026-08-05 (session 3: ALL open questions closed; research + smoke tests landed; user-directed rollover into documentation phase)

Design discussion is COMPLETE. Every open question is closed and recorded;
substance lives in `relaunch-analysis.md` (open-questions section, final
state), `decisions.md` (three new Tier-2 notes), and the three research docs.
This block is provenance only.

- Closed with user: #1 multi-session identity redesign approved (operating
  model: one developer, N concurrent sessions, one per work item); #2 knobs
  (`context-budget.env`, off/manual/auto, `manual` default); #3 all four hook
  deployments in scope (smoke tests collapsed the deferral rationale); #4
  launcher covers all five runtimes seeded-interactive, background claude-only.
- Research delivered (background agents): `vendor-hooks-research.md` (all
  four runtimes PUSH-CAPABLE — the "agent discipline only" matrix rows were
  stale); `smoke-test-opencode.md` (opencode 1.18.14 installed; chat.message
  injection CONFIRMED live, part shape trap documented; sqlite token store);
  `smoke-test-copilot.md` (copilot CLI 1.0.78 installed; hooks CONFIRMED
  live; `copilot -i` seeded-interactive REFUTED the headless-only claim;
  VS Code agent mode ships hooks since v1.109, Preview, reads our formats —
  live verification is the one spun-out ticket).
- Machine state changed: opencode (brew) + copilot CLI (npm) now installed;
  scratch test dirs under the session scratchpad; a stray `$schema` line
  opencode auto-added to `.opencode/opencode.json` was reverted.
- Next phase (user-agreed sequence): documentation first, then
  implementation. See `next-session.md`.

Suggested skills for the next session: `writing-for-agents` (doc edits),
`decision-log` (promotions to the ADR-0003 family), `checkpoint` or
`session-rollover` at the boundary.

---

*Older blocks: `handoff-archive.md`.*
# Session Handoff — 2026-08-05 (session 2: design discussion — hybrid settled, ADR-0003, codification walkthrough, multi-session redesign proposed; WARN rollover)

Same calendar day as session 1, fresh context. All substance lives in
`relaunch-analysis.md` (written incrementally — effective write-ahead) and
ADR-0003; this block is provenance only.

- Settled with user: consent axis reframe; hybrid trigger (WARN asks, STOP
  automatic); dying agent conducts rollover; write-ahead on declined WARN;
  answer-then-rollover as discussion atomic step; D1–D8 local-vs-LLM verdicts
  + conductor state machine.
- ADR-0003 promoted (user-directed) from a Tier-2 note; committed + indexed.
- User challenged D6 (global active-project state) → multi-session identity
  redesign proposed (session-keyed state + per-project advisory lock);
  **awaiting user verdict** — the successor's first question.
- The registry-clobber bug fired live mid-session (record measured the dead
  demo session); evidence in the analysis, workaround in
  docs/operational-knowledge.md.
- Commits this session: 506a68e, 8e2ac7d, 8eabdb0, 56dc888 + the rollover
  commit; all pushed to main.

---

# Session Handoff — 2026-08-05 (session 1: project spun out of template-maintenance; demo run; analysis captured)

Spun out of `work/template-maintenance/` mid-discussion: its queued
`launch-next-session.sh` mission grew into this focused project at the user's
request ("this deserves a good discussion and proper focused project").

What got done this session (while still under template-maintenance):
- Verified launch flags against installed CLIs — caught that
  `claude --bg --name` doesn't exist (no `--name` flag).
- Live demo: `claude --bg` launched a detached seeded session in this cwd; it
  read the launcher and answered correctly in ~11s; stopped cleanly.
- Full analysis written to `relaunch-analysis.md` (pipeline concept, vendor
  matrix, knob proposal, four open questions).
- User widened scope beyond the script: cross-vendor *triggering* reliability
  and workspace-parameter optionality are explicitly part of the problem.

State: no code written; `main` clean apart from this new work directory and a
retarget note in `work/template-maintenance/next-session.md`. Immediate next
step: the open-questions discussion (see launcher).
# Session Handoff — 2026-08-06 (session 11: Task 9 shipped + final whole-branch review — PLAN COMPLETE)

**What shipped (committed on `main`, pushed through `75e8cbc`):**

- **Task 9 — `3fafd13` + `6d0f448`:** `scripts/attach-session.sh` (find latest
  session for a work dir; attach when alive+locked) + `test-attach-session.sh`
  (19 asserts, bash-3.2 verified), docs front-door update, backlog row,
  Tier-2 note. Live `--help` verification: no `claude attach` subcommand
  exists — wired `claude --resume <session_id>`; limitation recorded in
  script header, docs, and decision note. One fix round (backlog row missing
  commit hash), then review clean.
- **Final whole-branch review (`13201b5..6d0f448`, most capable model):** no
  Criticals. One Important — `skills/session-rollover/SKILL.md:141` still
  instructed the nonexistent `claude attach` — fixed in `75e8cbc` along with
  a new open backlog card **L17** bundling the deferred follow-up minors
  (attach-session unlocked-case wording; space-unsafe `ls -t` loops in
  attach/launch scripts; unquoted SQL interp in `opencode_measure`; registry
  suite filename drift in docs). Re-review clean except one **parked** Low:
  backlog scorecard counts drifted (Open reads 2 vs 1 actual; Resolved 29 vs
  31 — pre-existing) — ruled cosmetic, folded into L17's scope.
- Ledger deferred minors all triaged by the final review: T3 lib-sourcing
  fail-open ruled fine as-is; T7 docs pointer and T8 footer date verified
  fixed. SDD workspace deleted after completion (git history is the record).

**Plan status: all 9 tasks complete, reviewed, pushed. The
vendor-hook-deployments plan is DONE.**

# Session Handoff — 2026-08-06 (session 10: plan Tasks 7–8 shipped; user added Task 9 (attach helper); WARN rollover)

**What shipped (committed on `main`, pushed):**

- **Task 7 — `e0cb70d`:** successor option inheritance —
  `work/<proj>/.rollover-options` read in `scripts/launch-next-session.sh`,
  mapped to per-runtime flags; rollover-skill step 6 added; suite
  `test-launch-next-session.sh` now 38 asserts. Live `--help` verification
  corrected the plan's table: codex `--full-auto` does not exist in codex-cli
  0.142.4 → shipped `--ask-for-approval never`; opencode `--auto` exists so
  opencode stayed in the approval mapping. Review clean.
- **Task 8 — `f9e003a`:** docs gate — `docs/context-budget.md` "Vendor hook
  deployments" section + `.rollover-options` under Relaunch knobs, CLAUDE.md
  Context Budget updates, backlog rows, 6 Tier-2 notes in `decisions.md`.
  All three suites green (37/38/13). Review clean. Includes two user-requested
  additions: "Chained rollovers & re-attach" passage (attach-vs-relaunch
  decided by the `.active-session` lock; bg chains are claude-only) and the
  gemini successor spurious-STOP caveat (workspace-scoped telemetry).

**Mid-session user input (binding):** (1) analysis of 2+-hop rollovers per
vendor — delivered in-session, durable parts flushed into
`docs/context-budget.md` by Task 8; (2) attach helper is NOT YAGNI — user
mandated `scripts/attach-session.sh`; scoped as **Task 9 (user-added)**, brief
written at `.superpowers/sdd/2026-08-05-vendor-hook-deployments/task-9-brief.md`,
NOT yet implemented.

**What did NOT happen:** Task 9 implementation/review; the final SDD
whole-branch review (range `13201b5..HEAD`, plus deferred-minor triage).
SDD ledger with per-task record + deferred minors:
`.superpowers/sdd/2026-08-05-vendor-hook-deployments/progress.md`.

**Suggested skills for next session:** `superpowers:subagent-driven-development`
(mid-plan, resume at Task 9); `session-rollover` at WARN/STOP.

# Session Handoff — 2026-08-06 (session 9: plan Tasks 2–6 shipped via subagent-driven development; WARN rollover)

**What shipped (committed on `main`, pushed at rollover):**

- **Task 2 — `6a78138`:** `opencode` runtime in `scripts/context-budget.sh`
  (sqlite measurement from `message.data` tokens.total, session-column
  fallback; env-only detect). Suite T9.
- **Task 3 — `4543645`:** codex `UserPromptSubmit` hook
  (`scripts/hooks/context-budget-codex-hook.sh` + `.codex/config.toml`). T5.
  Smoke check needed `-m gpt-5.5` (machine's global codex config pins an
  unavailable model — see docs/operational-knowledge.md).
- **Task 4 — `93e9d45`:** gemini `BeforeAgent` hook + `.gemini/settings.json`
  wiring (graphify BeforeTool + telemetry preserved). T6/T10. Live smoke
  blocked by missing gemini auth on this machine (pre-documented gotcha);
  gemini parsed the new config shape cleanly.
- **Task 5 — `f9579fe`:** opencode `chat.message` plugin + wrapper. T7.
  Justified 4th file: plugin registered in `.opencode/opencode.json` `plugin`
  array (plugins do NOT auto-load from `.opencode/plugins/`). Live smoke green.
- **Task 6 — `9fa16b7`:** copilot CLI `sessionStart`/`agentStop` hooks +
  `.github/hooks/context-budget.json`. T8. Live smoke green; this workspace
  added to `~/.copilot/config.json` `trustedFolders` (was absent).

Suite `scripts/tests/test-vendor-budget-hooks.sh`: 37 asserts green.
Per-task review record + deferred minors: `.superpowers/sdd/2026-08-05-vendor-hook-deployments/progress.md`
(SDD ledger — final whole-branch review still pending, do after Task 7).

**What did NOT happen:** Task 7 (option inheritance in launch-next-session.sh
+ SKILL.md step) and Task 8 (docs/backlog/decisions + verification gate +
final review). Two machine gotchas routed to docs/operational-knowledge.md.

**Suggested skills for next session:** `superpowers:subagent-driven-development`
(SDD ledger above is mid-plan); `session-rollover` at WARN/STOP.

