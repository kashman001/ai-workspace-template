<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-08 (session 2: catalog complete + gap analysis + backlog cards; finished well under WARN)

What got done (all on branch `worktree-usage-scenarios-s2` — needs delivery
to main):
- `scenarios.md` §4 internal catalog I1–I10 (from ground-truth §D groups
  A–G, each with support status AND test status incl. T:⊘
  untestable-by-construction) and §5 scenario→docs→tests coverage matrix
  (all E1–E18 + I1–I10 rows). Status flipped to COMPLETE.
- `gaps-and-coverage.md`: 8 ranked gaps (multi-user; product onboarding/Z0;
  required-tooling manifest; shared secrets; personal-layer unevenness;
  template eval harness; zoom doc restructure — includes the decision to
  **supersede usage-scenarios.html** with the E-catalog; team capability
  authoring) + cross-cutting observations + recommended sequencing.
- Mid-turn user addition (brief req 10): teams author shared
  skills/agents/runbooks/scripts for common product work → new E18 (◐),
  Gap 8, matrix row.
- Post-close user directive: keep it simple, push back where a simple path
  or documentation suffices → "Simplicity guardrails" section added to
  gaps-and-coverage.md (per-gap don't-build list; Gaps 3/8 recommendations
  amended to reuse-existing / documentation-only).
- Backlog updated per convention: opened M15 (catalog meta-card) and
  promoted un-carded CL-1/2/3 to cards M16/L32/L33; scorecard 4 Open;
  change-log row added. **M16 reproduced live this session** (artifact path
  switched to the worktree-scoped dir after EnterWorktree); **L33's shape
  recurred too** (fresh worktree branched from origin/main which lagged
  local main by the session-1 commit — fixed with `git merge --ff-only
  main` before editing).

State: Tasks #3–5 done → work item's build phase COMPLETE. Peak recorded
context 102K (OK). Branch not merged: background-session policy forbids
merging to main; delivery is the successor's/user's one remaining step.

Learnings: harness-enforced worktree isolation for background sessions
interacts with both M16 and L33 — every background session on this
template will hit the lagging-origin worktree base unless local main is
pushed before dispatch.

What got done:
- Scaffolded the work item; committed per-item `context-budget.env` with
  `ROLLOVER_RELAUNCH=auto` (user directive: hands-free rollover).
- Captured user requirements in `brief.md` (multi-repo products, multi-user,
  per-user settings/secrets/tooling with non-negotiable baseline, three
  onboardings, concurrent work items, root product docs, context budget,
  zoom-level abstraction). Mid-session user additions: (1) zoom = product
  information specifically (architecture → source file), (2) keep the
  operational hierarchy as a second orthogonal dimension, (3) agents per
  zoom level as profiles — all incorporated into `scenarios.md` §1/§1b/§1c.
- Ran 4 parallel read-only subagents over the repo; distilled ALL findings
  into `ground-truth.md` (backlog state, settings/secrets/tooling, external
  lifecycle docs, internal machinery + full test-coverage map). That file is
  the successor's evidence base — the raw reports are gone with this session.
- Drafted `scenarios.md`: §1 zoom model (Z0–Z3 + budgets), §1b operational
  hierarchy (O0–O4), §1c agents-per-zoom-level principle, §2 harness-vs-
  template table, §3 external catalog E1–E17 with support verdicts.

State: all files in `work/usage-scenarios/`; committed at rollover (see git
log). Tasks #1–2 done, #3 half done (§4 internal catalog pending), #4–5 not
started.

Suggested skills for next session: none beyond conventions; `decision-log`
when recommendations settle into decisions.

Learnings: (parked) 4-way subagent fan-out for doc mining worked well but
each report is ~80K child tokens — distill-to-disk immediately, reports are
the bulk of what pushed this session to WARN.
