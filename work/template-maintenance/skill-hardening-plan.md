# Skill-hardening plan — learn from mattpocock/skills comparison

Approved by the user 2026-08-05 ("let's go with all 7 and also include
writing-for-agents"). Source analysis: two subagent sweeps (all 35 upstream
SKILL.md files at clone `8b36d4f`; all 6 workspace skills + conventions docs).
Every finding needed for execution is restated here — **do not re-run the
comparison agents**.

Execution order: items 1–2 (small, unambiguous) → 3–8 → 9 (wrap-up). Each item
lists its files and a verify step. Commit in 2–3 logical commits with
`Decision:` trailers; push to `main` (standing instruction for this work).

## 1. Fix checkpoint's promotion-scan gap  [bug]

**Finding:** `skills/checkpoint/SKILL.md` scans only `work/*/decisions.md` for
`Promote?:` flags. But `docs/agents/issue-tracker.md` defines a resolved
wayfinder ticket as a Tier-2 decision recorded in `work/<effort>/map.md` →
"Decisions so far" (map substitutes for decisions.md). Promotable wayfinder
decisions silently escape the scan.

**Change:** extend checkpoint's scan to also sweep `work/*/map.md` Decisions-
so-far entries; one-line cross-reference in `skills/decision-log/SKILL.md`'s
promotion section so both ends name the same rule.
**Verify:** grep both skills for `map.md`; wording names the tracker doc.

## 2. Placement/consistency fixes  [small]

- `skills/onboard-repo/SKILL.md`: the mandatory per-step
  `context-budget.sh record` cadence currently sits *after* the Steps list —
  a top-down reader executes all 8 steps before seeing it. Move/announce it
  **above** the steps.
- Unify convention pointers: `skills/rlm/SKILL.md` says the convention home is
  `CLAUDE.md`; `docs/agents/issue-tracker.md` cites `CLAUDE.md → Decision
  Records`; `skills/decision-log/SKILL.md` says `CONTEXT.md`. Canonical name
  in this template is **CONTEXT.md** (CLAUDE.md/AGENTS.md/GEMINI.md are its
  symlinks) — but NOTE: in this template repo itself the real file is
  CLAUDE.md and there is no CONTEXT.md; check what actually exists (`ls -la`
  the root symlinks) and standardize on the name the template's own docs use
  (`CONTEXT.md` per workspace-structure.md), mentioning the symlink once.
- `skills/create-work-item/SKILL.md`: step 6's optional-files list never
  mentions `spec.md`, `map.md`, `issues/` even though
  `docs/work-directory-conventions.md` lists them — a tracker-backed/wayfinder
  effort gets scaffolded past the layout. Add them with a one-line pointer to
  the conventions doc + issue-tracker doc.

**Verify:** grep rlm/issue-tracker for `CLAUDE.md` (should be gone or
symlink-note only); create-work-item mentions map.md/issues/.

## 3. Verification / "Done when:" retrofit

**Finding (upstream pattern):** the best upstream skills gate steps with
explicit "Done when:" criteria and *runnable* verification (some
falsification-style: break it deliberately, watch it fail, revert).
Ours: `checkpoint` and `decision-log` have **no** verification section;
`create-work-item`'s Verification block is assertion-only (no command);
`session-rollover` never verifies that handoff.md was *prepended*
(newest-on-top) nor that archival happened.

**Change:** add a short Verification section with concrete commands to:
- `checkpoint` (hand-off file exists on disk; promotion scan ran — e.g.
  `ls` the doc, `grep -l 'Promote?:' work/*/decisions.md work/*/map.md`)
- `create-work-item` (`ls work/<name>/{README.md,next-session.md,handoff.md}`
  + `head -1` purpose-header check)
- `session-rollover` (top block of handoff.md is the new one:
  `grep -n '^# Session Handoff' | head`; archive rule when >2 blocks)
- `decision-log` (note appended: `tail` decisions.md; ADR promotion:
  new file exists + note flipped to `done → ADR-NNNN`)
Keep each to 3–5 lines; commands over assertions.

## 4. Boundary-skill arbitration (checkpoint vs session-rollover)

**Finding:** both produce hand-off artifacts with no stated rule for which
applies; upstream's `ask-matt`/PHASE-BOUNDARIES pattern is an ordered
decision tree ("first yes wins").

**Change:** add an identical short "Which boundary skill?" block near the top
of both skills, first-yes-wins:
1. Budget WARN/STOP signal (hook or exit code) → `session-rollover`.
2. Deliberate end of a work chunk, budget OK → `checkpoint`.
3. Both true → `session-rollover` (measurement wins), fold checkpoint's
   reconciliation steps into its reflect/flush.
Optionally one summary line in CONTEXT.md's skill bullets.

## 5. Resolve the dangling `handoff` dependency

**Finding:** `checkpoint` and `session-rollover` both invoke the global
`handoff` skill (`~/.claude/skills/handoff`, from mattpocock/skills) which is
NOT in this repo — template downloaders get a broken prerequisite. Violates
the "template additions are first-class / agent-agnostic" memory rules.

**Decision (made, record as Tier-2 when executing):** **inline** the three
load-bearing handoff rules into both skills — (a) reference artifacts by
path/URL, don't duplicate content; (b) include a "suggested skills" section
for the next session; (c) redact secrets/PII. Keep a one-line "if the global
`handoff` skill is installed you may use it; the rules above are the
contract" note. *Rejected:* vendoring the whole skill (another pinned copy to
maintain for ~10 lines of rules).

## 6. Invocation-axis pass (frontmatter)

**Finding (upstream pattern):** `disable-model-invocation: true` for
human-only skills = zero standing context cost; model-invoked skills pay
description cost for discoverability. Upstream pairs it with
`agents/openai.yaml` `policy.allow_implicit_invocation: false`.

**Change:** add `disable-model-invocation: true` to **create-work-item**,
**onboard-repo**, **rlm** (all user-driven via slash commands; slash commands
keep working). KEEP model-invocable: **decision-log** (its trigger-phrase
frontmatter is the set's best — don't touch), **session-rollover** (must fire
on hook WARN/STOP messages), **checkpoint** (fires on "finishing a chunk"
signals). `wayfinder` already has it. Note the change in each skill's
`.claude/commands/` wrapper only if the wrapper restates invocation.

## 7. ADR three-way AND test in decision-log

**Finding (upstream `domain-modeling`):** promote to ADR only if the decision
is *hard to reverse* AND *surprising* AND *a real trade-off* — if any leg is
missing, skip. Our Tier-3 criterion ("lasting weight") is vaguer, and Tier-2
("any real rejected alternative") has a known over/under-application problem
with no negative example.

**Change:** in `skills/decision-log/SKILL.md`: state the AND test as the
Tier-3 promotion criterion (credit upstream domain-modeling); add ONE worked
"don't log this" Tier-2 example (e.g. a reversible pick between equivalent
libs with no real trade-off → Tier-1 trailer only). Check
`docs/adr/README.md` for criterion wording to keep in sync.

## 8. Vendor `writing-for-agents`

**Decision (user-approved; record as Tier-2 when executing):** vendor as
`skills/writing-for-agents/` following the wayfinder pattern. *Rejected:*
docs-page copy (passive; loses the trigger on "creating or editing skills").

- Copy from clone at `8b36d4f`: `SKILL.md` + `SKILL-MECHANICS.md` +
  `agents/openai.yaml` (upstream dir has exactly these; SKILL-MECHANICS.md is
  a disclosed reference — must come along).
- Provenance comment after frontmatter in SKILL.md (mirror
  `skills/wayfinder/SKILL.md` lines 7–16 wording; pin `8b36d4f`, date, list
  all three files in the refresh procedure). Verify diff vs upstream is
  comment-only.
- Wire: CONTEXT.md "Workspace Skills" bullet; `docs/recommended-tooling.md`
  §3 — extend the existing "`wayfinder` is vendored" blockquote to cover both
  vendored skills incl. the duplicate-copy caveat (this machine also has the
  global symlink); backlog row.
- No `.claude/commands/` wrapper (model-invoked reference skill, not a
  command). Use it as the style guide while executing items 1–7.

## 9. Wrap-up

- Backlog (`docs/template-workspace-backlog.html`): one changelog row
  covering the whole hardening batch + both last-updated dates.
- Commits with `Decision:` trailers; push to `main`.
- Tier-2 notes for items 5 and 8 in `work/template-maintenance/decisions.md`
  (created this session with the item-8 note; append item 5's at execution).
- Sanity: `bash -n scripts/*.sh` untouched (no script edits planned);
  re-read each edited SKILL.md top-to-bottom once — items are cross-file,
  wording drift is the main risk.
