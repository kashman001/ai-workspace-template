<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 21 (2026-10-09): Matt Pocock skills refreshed to 49dd158; GLOSSARY.md adopted

**Summary.** Mission job 1 (refresh) is done. Job 2 (L70 patched class) has not started.

**What got done (on main, not pushed):**
- `08eeee3` synced the vendored set `068b6e0` → `49dd158`. It added `implement-spec`, `pr` and `retro` (all pristine, with slash wrappers for implement-spec and retro) and removed `resolving-merge-conflicts` (dropped upstream). Catalog: `skills/vendored-skills.md`; table: `docs/recommended-tooling.md` §3.
- Same commit: the glossary moved from `CONTEXT.md` `## Language` into a new root `GLOSSARY.md`, following upstream's CONTEXT.md→GLOSSARY.md rename (#876). CONTEXT.md is now 13.9K. Map rows are in `docs/workspace-structure.md`.
- `a447345` filed backlog cards **M48** (`isolated: yes` has no effect) and **L71** (plans for code work have no review step). Source: `work/template-maintenance/implement-spec-vs-plans.md`, a subagent's comparison. Its isolated claim was verified at `scripts/plan.sh:80,164,571`.
- Outside the repo (no git), backups in the s21 scratchpad: `~/.claude/skills` symlinks fixed (the stale link was removed and 3 new ones added). The GLOSSARY.md wording was applied to `~/.config/agent-context/{global.md,README.md,project-template/CONTEXT.md,project-template/docs/agents/domain.md}` and `~/.local/bin/init-project-ai-infra`, and `init --full` was smoke-tested.
- `run-checks.sh` passed 40/0/0 twice.

**Decisions:** `decisions.md` has 2026-10-09 "Adopt upstream's GLOSSARY.md" (Promote?: yes, ADR candidate) and "Vendor implement-spec despite its overlap with plans". Both were chosen by the user.

**Open questions:** existing projects made with the old init (e.g. `~/Developer/experiments/NeogeoEmu`) still keep their glossary in CONTEXT.md. They were not migrated and the user was not asked.

**Learnings:**
- The global `~/.claude/skills/<matt-skill>` entries are symlinks into the upstream clone, so `git pull` there updates the global skills at once, before any sync.
- Upstream changed `code-review` in this refresh (3da8c01), so the L70 patch must be rewritten against the new text and not taken from the old issue draft.

**Suggested skills:** `tdd` (L70 sync-script test), `writing-for-agents` (vendored-skills.md class text), `decision-log` (promote the GLOSSARY ADR at checkpoint).

# Session Handoff — 20 (2026-10-09): DeepSeek Harness cards M46, M47, L66–L69 fixed; L70 sent upstream

**What got done (on main, not pushed):**
- `fa7d5f4`: all six fixes in one commit.
  - M46: `test-agent-entrypoints.sh` E6 checks that a skill's
    `disable-model-invocation: true` and its Codex
    `allow_implicit_invocation: false` agree. Six skills gained `agents/openai.yaml`.
  - M47: under `CI`, a skip (exit 77) fails `run-checks.sh` unless the check
    carries `# run-checks: may-skip-in-ci`. No check exits 77 today.
  - L66: the "report what you ran" rule is now in `CONTEXT.md` rule 4 and in
    checkpoint, plans reconcile, and research-wave.
  - L67: the "Readable without the transcript" test is in
    `docs/work-directory-conventions.md` (Ledger), not `writing-for-agents`,
    because that skill's body is vendored and the sync script would wipe an edit.
  - L68: the repair order is in `check-drift.sh` (comment and message).
  - L69: root `.rgignore`.
- `4577d61`: `TEMPLATE_VERSION` set to 2026-10-09.
- L70 stays Open. Step 3 and the Standards brief in step 4 already cover part
  of what the card asked for, so the card's evidence was corrected. Filed
  upstream as mattpocock/skills#1242 (draft in `upstream-issue-code-review.md`).

**Verification:** `CI=true scripts/run-checks.sh` reported 40/0/0 before the
commits. E6b failed on exactly the six skills until their yaml existed.
`test-run-checks.sh` R3b failed until `run-checks.sh` was changed.
`test-template-version.sh` passes 9/9.

**State:** `main` is 4 ahead of `origin` and unpushed (push is the
maintainer's call). The backlog has 1 Open card (L70), waiting on upstream.

**After the stop door (user asked):** pushed `main` (`8d3c7dc..570096c`).
`checks` run 37987347172 passed 40/0/0, so no check skips on the runner.
#1242 is open and labelled `needs-triage`, with no replies yet.

**Rolled over at WARN (131K tokens) with two jobs for session 21.** The user
does not want to rely on #1242 being merged, and chose the "patched" vendored
class for L70 (`decisions.md`, 2026-10-09). The user also asked to update to
the latest `mattpocock/skills` and integrate any new skills. The local clone
`~/Developer/references/mattpocock-skills` is at `068b6e0`, the commit every
vendored skill is pinned to; it has not been pulled.

**Suggested skills for session 21:** `writing-for-agents` (before any edit under
`skills/`), `tdd` (sync-script change), `decision-log`.

