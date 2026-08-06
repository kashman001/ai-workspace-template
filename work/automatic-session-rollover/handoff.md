<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->


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

