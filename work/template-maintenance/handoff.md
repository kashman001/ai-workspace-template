<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 23 (2026-10-09): ADR-0014, glossary migration script, patch tracking

**Summary.** All three jobs queued in session 22 are done. Backlog: 1 open (L74), 1/126/5/0/6.

**What got done (on main; pushed at session end):**
- **L72**: `docs/adr/0014-glossary-in-its-own-file.md` is promoted from the decisions.md GLOSSARY note (now `done → ADR-0014`) and indexed.
- **M49**: `scripts/migrate-glossary.sh <repo>` + `docs/runbooks/glossary-migration.md` + `scripts/tests/test-migrate-glossary.sh` (64 checks, red first). It refuses on a dirty tracked tree (untracked is OK), no commits, an existing `migrate/glossary` branch, or GLOSSARY.md beside real terms. It commits on `migrate/glossary` in the target. Not run on any real project.
- **L73**: `Upstream: mattpocock/skills#1242` header on `skills/code-review/workspace.patch`; the sync prints "upstream may have landed this; delete the patch" when `gh api` reports it closed (quiet without gh). `check-drift.sh` warns when the oldest Matt Pocock provenance date is >60 days old. Documented in `skills/vendored-skills.md`.
- Opened **L74**: `test-session-lib.sh` S8 failed once in six reruns (subagent's report); the final `run-checks.sh` passed 42/0/0.
- Jobs 2 and 3 ran as parallel subagents; the ADR, backlog, ledger and launcher stayed in the main session.

**Decisions:** user chose both patch-tracking checks, and to build on main, commit, then push. Glossary migration design choices are in the M49 Fixed line.

**L74 (same session, after the push):** fixed a second lost race in `_session_record_lock` — a lock re-taken by a third writer between the failed `mkdir` and the path check was refused as `record_unwritable`. Probe-confirmed; test S10r–t; S8 stress loop 4/30 → 0/100. Backlog now 0/127/5/0/6.

**Pushed:** `main` at `a030733` (L72/M49/L73 in `618889d`, L74 in `a030733`); CI was green on `618889d`. Rolled over at the user's request (budget WARN, ~132K).

**Open questions:** NeogeoEmu has no commits yet (unborn `master`), so the script will refuse there until the user makes an initial commit. Running it there needs the user's go-ahead. The 60-day warning uses the upstream commit date, so it persists after a refresh if upstream goes quiet.

**Learnings:**
- A test that backgrounds a job inside `$(…)` must redirect that job's output (`>/dev/null 2>&1 &`), or the command substitution waits for it — the race the test meant to plant never happens (S10r was green before the fix until this was added).
- Suggested skills next session: none specific; `diagnosing-bugs` if another flake shows up.

# Session Handoff — 22 (2026-10-09): L70 patched class, M48 and L71 resolved; backlog empty

**Summary.** The launcher's L70 mission is done, and the user also approved finishing M48 and L71 in this session. The backlog now has 0 open cards (0/123/5/0/6).

**What got done (on main, not pushed; 6 commits ahead of origin):**
- `244ccd0` **L70**: a new *patched* vendored-skill class. `scripts/sync-vendored-skills.sh` re-copies a pristine skill, keeps its `workspace.patch` (rsync exclude), and re-applies it with `patch -F0 --dry-run`, then `--no-backup-if-mismatch`. If the patch no longer applies, it exits non-zero and names the skill. The first user is `skills/code-review/workspace.patch` (Spec brief marks blocker/suggestion; step 5 groups each axis into Blockers/Suggestions and drops findings a passing check enforces). The patch was cut so it applies at zero offset against `49dd158`. New `scripts/tests/test-sync-vendored-skills.sh` runs a copy of the script inside a temp workspace against a fake upstream: it was red 7/17 before the change and 17/17 after. `skills/vendored-skills.md` lists three classes.
- `d0afd03` **M48 + L71** in `skills/plans/SKILL.md`. M48 describes what an orchestrator does with `isolated: yes`: own worktree and branch, merged back before `done`. L71 adds a closing review wave for code plans. A review subagent found 6 gaps (an uncommitted `start` is invisible to the worktree, the review node has no Goal/Acceptance, the base SHA is only in the title, and others); all were fixed before the commit.
- `TEMPLATE_VERSION` was not bumped. It is an ISO date and origin already holds today's `2026-10-09`.
- `run-checks.sh` passed 41/0/0 on each commit's final state.

**Decisions:** in `decisions.md`, the L70 note (patched class, recorded in s21) and the new 2026-10-09 "M48: merge back before done". The choice to give the review its own wave is in the `d0afd03` trailer.

**Open questions:** whether to comment on mattpocock/skills#1242 (only if the user asks). Delete `skills/code-review/workspace.patch` once upstream lands the change.

**Learnings:**
- Apple `patch` 2.0 writes `SKILL.md.orig` whenever a hunk applies at an offset. `--no-backup-if-mismatch` stops it and is GNU-compatible.
- A test for a script that writes into `$ROOT` should run a *copy* of the script placed inside the fixture. Running the real one would clobber the repo before any override exists.
- New user preference (memory `parallelize-independent-tasks`): dispatch dependency-free tasks to parallel subagents.

**Rollover addendum (after the push).** `main` was pushed (`4f56d4d..c0b4d2e`); CI checks and Pages are green. At 137K tokens, the user queued three jobs for session 23, all written into `next-session.md`: (1) promote the GLOSSARY.md decision to an ADR; (2) a runbook plus script so an agent can migrate older projects whose glossary is still in CONTEXT.md; (3) tracking for patched vendored skills (proposed to the user: an `Upstream:` header in each patch that the sync checks with `gh`, plus a check-drift age warning; the user has not yet confirmed the design).
