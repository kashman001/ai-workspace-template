# Decisions — template-improvement-review

Tier-2 notes (see `skills/decision-log/SKILL.md`). Newest on top.

## 2026-09-10 — L45: share local-only work items into worktrees by symlink (not copy-back, not a guard exemption)

**Decision:** a new `scripts/link-local-work.sh` symlinks every ignored
(`.gitignore` or `.git/info/exclude`) top-level `work/<item>/` from the main
checkout into a worktree that lacks it, so a worktree-isolated session reads
and writes the real directory and nothing dies with the worktree. It runs on
every per-tool hook firing (shared `context-budget-hook-lib.sh`, so all six
runtimes get it, unthrottled so no write can race the link) and at
`context-budget.sh register`. Pre-existing real directories in the worktree
are never touched; untracked-but-not-ignored items are never linked (a
symlink would be committable).
**Why:** the "repo guard" named on the card does not exist in repo code —
the redirect is the runtime's own worktree isolation (Claude Code
`EnterWorktree` / `isolation: worktree` / background sessions), so
"exempt the dirs from the guard" is only realizable by sharing the directory
in. Verified in-session that Claude Code's Write/Edit tools write through a
symlinked *directory* (the symlink-file refusal in CONTEXT.md is about
symlinked files).
**Rejected:** (a) guard exemption — no repo-owned guard to edit. (b) copy-back
on worktree exit / in `rollover-prep.sh` — lossy by construction: a worktree
whose only changes are ignored files looks *unchanged* and is auto-removed
before anything repo-owned runs, and `ExitWorktree(remove)` is a runtime
tool with no repo hook. (c) doc-only — the operator already does the manual
`cp`; the card is about removing that.
**Reversal cost:** delete the script and its two one-line call sites.
**Promote?:** no.

## 2026-09-10 — User approved the session-2 checkpoint requests

**Decision:** the user approved "the things requested above" at the session-2
checkpoint: merge `review/template-improvement-review-s1` into main; the five
build-under-assumption choices below stand as built; L45 is to be built (fix
direction left to the building session — investigate the repo guard first).
The §E machine/credential items remain user-only. **Promote?:** no.

## 2026-09-10 — Build the 5 design-gap cards under stated assumptions

**Decision:** the user asked this session to review and improve the template
autonomously ("leave you to think, try, and improve"). That supersedes the
template-maintenance session-15 rule "do not design conventions solo" for
these cards. Each card follows the options brief's proposed shape, choosing
the simplest posture where the brief left a choice:
- **L38** → routed into `work/quality-gates/` (brief's recommendation).
- **L39** → posture (b) "bring your own tracker", documented in
  `docs/agents/issue-tracker.md`, with the template's own backlog files named
  as a copyable worked example. Rejected (a) a `create-backlog` scaffold:
  real ongoing surface with no adopter demand on record.
- **M29** → (a) committed `docs/postmortems/` with a blameless template;
  threshold = any incident that cost a session or reached a user, adopter-
  tunable; ships with a forward pointer to feedback-intake rather than
  blocking on it. Rejected (b) work items (pruned over time) and (c) a
  paragraph in operational-knowledge (not a landing place for artifacts).
- **M28** → convention only (a `uat.md` slot beside `verification.md`);
  no-go recorded as a Tier-2 decision note. A `/uat-plan` skill is not built.
- **M27** → advisory companion skill `design-for-testability` (no gate);
  specs get a suggested "Testability" heading, not a required one.
**Reversal cost:** each is a doc/skill addition; delete or reshape freely.
**Promote?:** no.

## 2026-09-10 — ASR `.session-seq` synced 31 → 32

Ledger top block was session 32; ADR-0007 says the counter is canonical and
drift is repaired toward the prompt number, so the counter was raised via
`context-budget.sh seq-sync`. Machine-local file, no commit.

## 2026-09-14 — Session-management redesign must be reliable, repeatable, reproducible without trusting the agent

**Decision:** Every load-bearing step of the measure / rollover / supervise
loops is script-executed and script-verified, with coded verdicts; skill text
explains but never guarantees a transition. Recorded in findings Part 1b §1b.7.
**Why:** The operator is an LLM agent that can forget or hallucinate; the
history shows 63% of STOP sessions never saw the WARN checkpoint the agent was
told to run.
**Rejected:** relying on skill instructions ("record at every boundary") as the
mechanism, with scripts only as helpers.
**Promote?:** maybe — becomes an ADR when the Stage 2 design lands.

## 2026-09-15 — Stage 3 (design evaluation) starts; three reviewers, with a simplicity mandate

**Decision:** The user gave the go for Stage 3 on Part 2 without section-by-section
review, after judging the design document too long. Stage 3 runs three parallel
reviewers instead of the planned two: architect (AGREE/AMEND/REJECT per section),
scenario/flow (S1–S10 / E / I + the three loops), and a new developer/implementer
lens ("can I build this from the text; what is ambiguous or over-specified").
All three carry a simplicity mandate: every section must justify its existence
and Part 3 must include a cut list.
**Why:** Part 2 was drafted by one agent and has had no independent review; the
user's only review finding was length, which is itself a design smell under §1b.7.
**Rejected:** the user reading Part 2 section by section first (too long); a
one-page summary before review (deferred — Stage 3's cut list produces it).
**Promote?:** no.

## 2026-09-15 — Design v2 decisions D1–D3 settled (user accepted the reviewers' recommendations)

**Decision:** D1 drop the "unknowable" logout code path on Codex/Copilot CLI (quits
read as plain quits; the support matrix says "logout not classified"). D2 a predecessor
resumed after staging: whoever registers against the open launch becomes that session
(no number spent, no unstage verb). D3 accept the newest-transcript identity heuristic
on Copilot CLI / Gemini while unverified, stated in the matrix.
**Why:** each is the least code for a gap the support matrix already states; D2 removes
a verb, a code and a probe and needs no judgement about consumption.
**Rejected:** D1(b) `logout=unknowable` suffix; D2(b) refuse + spend a number; D3(b)
mandatory `--session-id`.
**Promote?:** with the design ADRs at Stage 4.

## 2026-09-15 — Stage 4 plan shape: phase-level Part 4 + just-in-time per-phase task plans + a tracker file

**Decision:** Part 4 is a ≤120-line phase plan (9 phases + cutover, one vertical slice and
its proving test each, a session estimate). Task-level detail (files, test code, commands)
is written by the executing session into `plans/phase-<n>.md` when that phase starts.
Progress lives in `stage4-tracker.md` (a "Now" line + one row per phase with status,
estimate, sessions used, commit).
**Why:** the user's readability rule (short, plain, self-contained) and the user's ask for
"what is the plan / where are we / what remains" at any point; task-level detail for
eight phases over 4,000 lines of bash would go stale before it ran and would exceed
the reading budget.
**Rejected:** one full task-level plan now (the writing-plans skill's default shape:
stale by phase 3, unreadable); tracking via tickets only (`/to-tickets` still runs on
acceptance, but tickets do not answer "where are we" in one line).
**Promote?:** no.

## 2026-09-16 — Phase 0: record file shape, import semantics, notify path resolution

**Decision:** the per-item record is `work/<item>/session-state.json`; the counter import
writes `{"schema": 1, "seq": N}` and phase 1 inherits schema version 1 as that shape.
Import: record absent or behind the counter → write; equal → no-op; ahead → refuse
`seq_conflict`; the old counter is never deleted before cutover. `SESSION_LOOP_NOTIFY`
resolves from the env file's own location via `${BASH_SOURCE[0]}`.
**Why:** the design names `schema_mismatch` but no version field, so the import had to
pick one; comparing rather than consuming the counter keeps the import retryable while
old scripts still bump the counter; every sourcer of the env file is bash, and a
caller-variable path resolved against the cwd for every caller but the supervisor.
**Rejected:** writing `{"seq": N}` only (phase 1's schema check would reject imported
records); consuming the counter on import (breaks the old scripts before cutover);
`${WORKSPACE_ROOT:-${ROOT:-.}}` (still a caller variable, still wrong from a hook).
**Promote?:** no — phase 8 promotes the record itself.
