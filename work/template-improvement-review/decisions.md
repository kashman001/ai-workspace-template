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

## 2026-09-17 — Stage 4 execution: one wave per session, live supervisor kept, `main` frozen until cutover

**Decision:** phases run as a fleet in waves (1∥2 → 3 → 4∥6 → 5 → 7 → 8 → cutover), one
wave per parent session, rolling over through the existing supervisor chain (pid 72900).
Waves merge to an integration branch `stage4`; `main` keeps the old scripts until cutover.
**Why:** the user wants each wave in a fresh session with the next kicked off automatically;
the supervisor already does that and is proven on this item. Phase 0 ended the chain only
to avoid editing scripts a live process runs — freezing `main` removes that hazard.
**Rejected:** ending the chain and relying on the old launcher's `auto`/`--bg` path (the
design found its successor binding inexact); one long session per several waves (context).
**Promote?:** no.

## 2026-09-17 — Rollovers between waves are hands-off (user)

**What:** every rollover in Stage 4 uses `--loop-mode handsoff`; fleet waves are launched without a per-wave okay. **Why:** the user asked that the next session start on its own rather than wait for Enter. **Rejected:** `interactive` mode per wave (session 10's launcher), so the user could approve each fleet launch — it stalls the chain on an absent human.

## 2026-09-17 — stage4 integration happens in a worktree, never in the primary tree

**What:** `stage4` is only ever checked out at `.claude/worktrees/stage4`; the primary tree stays on `main`. **Why:** the live supervisor and this session's hooks read the old scripts from the primary tree; a checkout would swap them under a running bash. **Rejected:** `git checkout stage4` in place between merges — cheaper, but exactly the "editing a script a live process is running" risk from Part 4.

## 2026-09-17 — Phase 1 record helper: interface and lock (agent, plans/phase-1.md)

**What:** one function `session_record_update <record> <precondition> <filter>`; exit 0 written, 1 precondition false (silent no-op), 3 usage, 4 refused with `reason=` (`record_unreadable`, `schema_mismatch`, `filter_empty`, …). An absent record reads as `{"schema":1}`. Lock is `mkdir <record>.lock`, 15 s wait, stale after 10 s, released by explicit code paths. **Why:** callers must tell a write from a no-op by exit code, not by parsing output; registration's "create if none" is just a precondition, not a second entry point; a record write holds the lock for milliseconds, so the 3 h `CONTEXT_LOCK_STALE_SECS` (a session-liveness knob) would block every writer for hours after one crash; a `trap` in a sourced function would clobber the caller's. **Rejected:** exit 0 plus a marker line; a separate create function; reusing the session-lock constant; `trap EXIT` release. Schema stays 1; import script untouched.

## 2026-09-17 — Phase 2 fleet extraction: copy helpers, ask the measurer for own session (agent, plans/phase-2.md)

**What:** `scripts/fleet.sh` carries its own ~40 lines of helpers; `children` resolves the caller's session through `context-budget.sh check` output; it accepts only the options its verbs read; the measurer refuses a moved verb with exit 3 and a message naming `scripts/fleet.sh <verb>`. **Why:** a shared library now would pre-empt phase 3's decision on sharing and cross phase 1's paths; copying the ~250-line per-runtime discovery stack would duplicate the most volatile code right before phase 3 rewrites it. **Rejected:** a shared `scripts/lib/` helper sourced by both; copying `resolve_session`; mirroring the measurer's full option list; silently dropping the verbs (an `unknown option` error names no fix). Phase 3 must keep `check`'s `runtime=`/`artifact=` lines or update `resolve_own_session` in `fleet.sh`.

## 2026-09-17 — Phase 3 measurer on the record: what stays, what goes (agent, plans/phase-3.md)

**What:** `register`/`release`/`close`/`--check` write the per-item record through `session_record_update`; the per-session registry record (`.context-budget/sessions/<rt>-<sid>.json`) stays, while `.active-session`, the roles, the `superseded_*` stamps, the `successor-pending-*.json` handshake and the child locks (`.agent-locks/`) leave the measurer. `record`, `watch`, `supervised` stay as verbs, unchanged. Deleted verbs (`seq-sync`, `opts-sync`, `rollover-complete`) refuse with a one-line pointer, exit 3. **Why:** the launcher, the supervisor, `fleet.sh children` and the `--session-id` pin all read the registry record, none of which are phase 3's to change; `supervised` is read by the launcher twice and its marker belongs to phase 5's `chain` block; child locks depended on `.active-session` and findings (g) moves them to fleet. **Rejected:** dropping the registry too; folding `supervised` into a record read before `chain` has a writer; re-pointing the parent-chain lock check at the record; silent fall-through to `unknown option`.

## 2026-09-17 — Phase 3 exit-code and binding rules (agent, plans/phase-3.md)

**What:** `register` never blocks — `owner_live` is a logged outcome (record untouched, session measured project-less), not an exit code. Non-owner `release` exits 1 (the "answer was no" convention, run by every SessionEnd hook); `close` refuses with 4 (`not_owner`, `ledger_seq_mismatch`, `ledger_shape`) because it is an explicit agent action with a remedy. Env binding needs both `TF_SESSION_PROJECT` and `TF_SESSION_SEQ` and an equal `seq`; `TF_SESSION_LOOP_PROJECT` no longer binds a work item. Ledger checks live in the measurer, not `session-lib.sh`; `--unstage` writes `.session-seq` directly. **Why:** a SessionStart hook must not report a failure for a correct outcome; a refusal code on every session end would be noise; the successor must never claim a launch it cannot prove is its own (the D14 swap class); an unused lib helper now is speculative (phase 4 lifts the checks if it wants them, same rule as phase 2's copy-not-share). **Rejected:** exit 4 on `owner_live`; exit 4 on non-owner release; binding on the project alone; a shared ledger-check helper; keeping `seq-sync` alive for `--unstage`'s one call. **Promote?:** the "never blocks" and binding rules are candidates for the ownership ADR in phase 8.

## 2026-09-18 — Phase 4 launcher on the record: gates, one write, what the supervisor still needs (agent, plans/phase-4.md)

**What:** the launcher reads the record once, runs twelve gates (exit 4, `launch-next-session: refused reason=<code> k=v`), then one `session_record_update` write: `seq`+1, outgoing owner into `launch.predecessor`, `session` null, `staged` (or `launch.pending` for `--clear`). `--check` and `--dry-run` run every gate and write nothing. `not_owner` = slot empty or owner dead (remedy `register --project`, which adopts); `owner_live` = another live session. `no_supervisor` fires only for a `TF_SESSION_LOOP=1` session staging with no live supervisor, so an unsupervised `--emit` succeeds (the ticket's slice expects `staged.by`). A missing `next-session.md` is `launcher_unchanged` detail `absent`. Runtime comes from `--runtime`, else the owner's `session.runtime`, else `ROLLOVER_RUNTIME`. `.session-seq` and its two sidecars are written, never read (compat mirror for the unchanged phase-5 supervisor); `launch.options`/`launch.reason` are not written. Deleted: `--bg` + poll, `--unstage`, `.rollover-options`, the counter lineage gate, `.active-session`/`.agent-locks` handling, the successor-pending handshake, the clear-seed hook + suite. Supervisor bootstrap with no owner to roll: dead owner recorded as `stopped` or `abandoned`, `predecessor` null when the slot was empty. **Why:** the record's `seq` is the only number source (two sources is the defect class this stage removes); a dry-run that passes where a launch refuses is a readout nobody can trust; a non-owner cannot vouch for the `predecessor` block; the reason-code list is closed. **Rejected:** the old "rollover is the authority" release of a dead holder; refusing every `--emit` without a supervisor; dry-run exemptions; reading the legacy counter for record-less items; a new reason code for a missing launcher; carrying `reason` in the record for one wave; the newest registry record as runtime fallback; refusing bootstrap on a dead owner. **Handoff:** the stage4 `.claude/settings.json` SessionStart entry for the deleted clear-seed hook is a guarded no-op (`[ -x "$h" ] || exit 0`) until the parent removes it; `--clear`'s prompt sits in `launch.pending.prompt` with no injector yet; prose naming `--bg`/`--unstage`/`.rollover-options`/seed file in the skill, `docs/context-budget.md`, ADR-0009, `CONTEXT.md` is phase 8's.

## 2026-09-18 — Phase 6 hook dispatcher: a data-file adapter table, shims stay (agent, plans/phase-6.md)

**What:** `scripts/hooks/context-budget-hook.sh <runtime> <event>` reads `scripts/hooks/context-budget-adapters.conf` (6 rows × 10 columns: session-id source, transcript at check/end hook, measure-as, register, pin env, check hook:envelope, turn-end hook:action, logged out). The six vendor wrappers and `context-budget-stop-hook.sh` are one-line `exec` shims at their old paths; `context-budget-hook-lib.sh` stays (sourced by `test-link-local-work.sh`; it is the measurer-facing core). `copilot-vscode` and `opencode` keep a row and a shim. `jq_missing` goes to stderr with exit 0 and the silent envelope on stdout, before any parsing. An empty session id is a silent exit for every runtime (claude/codex/gemini used to fall through to a shared `unknown` throttle key). The `stop_hook_active` guard now precedes registration (payloads identical). Proof is 47 committed fixtures captured from the 0a117c6 wrappers, compared byte-for-byte on rc/stdout/stderr; regeneration only with `HOOK_FIXTURE_WRITE=1`. **Why:** one line per runtime that a human can read without executing it; shipped wiring (`.github/hooks/`, `.opencode/plugins/`, `.codex/config.toml`, `.gemini/settings.json`, `.claude/settings.json`) names the wrapper paths and cannot be edited in this phase (and the codex trust hash re-prompts on any command change); stdout is the vendor payload channel and a hook must never block a turn; fixtures must survive a template download with no history. **Rejected:** a `case` block per runtime in the dispatcher; deleting the two non-goal runtimes; inlining the lib; `jq_missing` as exit 4 or on stdout; a per-row flag to reproduce the `unknown` key or the old guard order; extracting the old wrappers at test time; repointing configs and deleting shims now (optional later cleanup); editing `docs/context-budget.md` (phase 8).
