<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-08 (session 5 continued: Gaps 7+4+1 shipped, M15 CLOSED)

User directive mid-session: finish all remaining gaps + holistic re-review
by another agent + ensure usage/development guides present; user away,
complete autonomously. Context WARN (~122K) hit — heavier pieces delegated
to subagents to keep the parent lean.

What got done (same branch `worktree-usage-scenarios-s5`):
- **Gap 7**: scenarios.md §1/§1b/§1c promoted to `docs/zoom-model.md`
  (standalone doc; rejected workspace-structure.md section — file already
  ~900 lines). usage-scenarios.html retired to `docs/archive/` with a
  supersede banner (stale `work/<user>_` refs die with it); README
  repointed to zoom-model.md + the E-catalog. Guide HTML rebuilt.
- **Gap 4** (interface only, per guardrail): service-access.md gains
  Scope field (personal|shared), per-OS keychain command table, and the
  team-vault interface (fetch-by-name / bootstrap / rotation) with a
  1Password worked example. Scope line added to the registry entry shape
  in workspace-structure.md.
- **Gap 1** (phase 1 only, per guardrail): "Before You Add a Teammate"
  breakage-points section in workspace-structure.md; additive `user`
  (`$USER@hostname`) field in session registry records, .active-session
  lock, and dispatch generation entries (subagent; documented in
  context-budget.md shapes). Phases 2–3 stay deferred BY DESIGN until a
  second person is real.
- **Docs consumption pass**: new `docs/README.md` need→doc index (three
  audience tables: using / developing product / developing template);
  CONTEXT.md pointers to it + zoom-model.md.
- **M15 CLOSED** (subagent): card → backlog archive with Fixed note;
  scorecard 3/50/4/0/6; change-log row added. Open cards: M16, L32, L33.
- All nine suites green post-commit (363 asserts), incl. clean-room
  instantiation; structure check green; guide HTML in sync.
- Holistic fresh-eyes review agent ran over the full branch diff: verdict
  clean on simplicity and audience coverage; 9 small findings (3 med, 6
  low), 8 fixed in the final commit (archive HTML relative links, CONTEXT.md
  "All optional." reword, README label on the scenarios link + docs-index
  link, check-dependencies comment wording, heading-cite alignment,
  check-service-access bullet moved to shipped list, Windows credential
  module note). Skipped by judgement: gating the hook-wiring req on Claude
  Code presence — the failure message already prints the setup.sh fix.
- Context STOP (~154K) hit after the review dispatch; per protocol only the
  in-flight atomic unit (review fixes + push) was finished, then the
  session ended; close-out deferred to the launcher's mission.

State: branch pushed to origin; merge to main left for the user (background
session). Work item's mission is COMPLETE — all 8 gaps resolved or
deliberately deferred; consider closing/checkpointing the work item next.

# Session Handoff — 2026-08-08 (session 5: Gaps 3+8 shipped)

What got done (branch `worktree-usage-scenarios-s5`, pushed to origin —
needs delivery to main):
- **Gap 3 shipped** (tooling manifest, no new file format per guardrail):
  - `check-dependencies.sh`: `req jq` added (context-budget.sh hard-requires
    it — was entirely unlisted), plus a required hook-wiring check (I7):
    `.claude/settings*.json` must mention `context-budget-claude-hook`,
    else exit 1 with a fix pointer to setup.sh. Script now cd's to ROOT.
  - `check-service-access.sh`: required/optional split; required services
    (GitHub) unreachable → exit 1 (was always exit 0). Header documents it.
  - `setup.sh`: dependency check moved from step 0 to after the per-user
    copies (step 3b) so its hook-wiring verdict reflects post-setup state —
    otherwise every fresh instantiation printed a spurious hooks failure.
  - `recommended-tooling.md`: blanket "everything optional" replaced by a
    "Required for everyone" table (git, gh auth, jq, hook wiring) naming
    the check scripts as the machine-readable manifest.
  - Runbooks: dependencies.md gains jq rows + per-OS install lines;
    authentication.md documents exit-1-means-required-missing.
  - workspace-structure.md scripts-section descriptions updated to match.
- **Gap 8 shipped** (documentation only per guardrail — no skill):
  "Authoring a Team Capability" section in workspace-structure.md after the
  skills taxonomy: container decision rule (scripts/ vs skills/ vs
  .claude/agents/ vs docs/runbooks/), the two mechanical skill-wiring steps
  (.claude/commands/ mirror + CONTEXT.md listing), and the make-it-required
  hook into Gap 3's manifest. Discoverability pointer added in CONTEXT.md →
  "Workspace Skills" intro.
- Backlog: M15 progress paragraph + session-5 change-log row.
- Verification: all nine suites green (363 asserts), incl. clean-room
  instantiation post-commit; check-service-access fail path tested via
  PATH-hidden gh (rc=1); setup.sh→check-dependencies loop verified rc=0.

State: committed on `worktree-usage-scenarios-s5`, pushed to origin; merge
to main NOT done (background session — merge/push-to-main reserved for the
user per harness rules). Finished ~102K tokens, under WARN.

Learnings: setup.sh's old step order (dependency check before per-user
copies) made any settings-dependent required check self-contradictory on
first run — order preflights after the state they check.

# Session Handoff — 2026-08-08 (session 4: walk-through verdicts + Gaps 6 and 2 shipped)

What got done (branch `worktree-quiet-marinating-dolphin` — needs delivery
to main):
- Interactive walk-through held (AskUserQuestion): user adopted the gap
  sequencing as-is, endorsed retiring usage-scenarios.html (Gap 7's
  supersede), green-lit Gaps 6+2 now, queued 3+8 then 7, deferred 4
  (until a second service) and 1 (until a second person). Two Tier-2 notes
  in decisions.md; verdicts paragraph added to backlog card M15.
- **Gap 6 shipped**: `scripts/tests/test-template-instantiation.sh` —
  clean-room clone→setup→structure-check, idempotency, symlink repair,
  placeholder --clone-repos, plus doc-accuracy pins (T6) for the two false
  claims, both fixed in workspace-structure.md (reconciliation claim
  removed; --clone-repos ignores-tiers stated honestly). 20/20 green.
  Note: the suite clones committed state — commit before running it.
- **Gap 2 shipped**: Z0 product interview checklist beside the S0
  preconditions in workspace-structure.md; SPEC.md + docs/system-design.md
  rewritten as fillable Z0 templates; E1 local-vs-remote fork documented as
  an explicit choice point in template-usage.md. Deliberately skipped (per
  guardrail): no /onboard-product skill, no placeholder-Z0 check extension.
- Backlog: M15 verdicts paragraph + session-4 change-log row. Guide HTML
  rebuilt twice (workspace-structure.md edits).
- L33's shape recurred AGAIN (worktree branched from lagging origin/main;
  fixed with `git merge --ff-only main` before editing). M16 mitigation
  applied (re-ran `register` after EnterWorktree).

State: delivered — user directed merge+push in-session: main fast-forwarded
to c6a2f03, pushed to origin/main, worktree + local branch deleted (remote
branch copy remains, deletable). Rolled over at WARN (~124K).

Learnings: (parked) the worktree-isolated Bash guard also refuses
`git -C <shared-checkout>` redirects, not just compound commands — merging
to main from a background session requires ExitWorktree(keep) first; and
the shared-checkout edit guard forces a second throwaway worktree for
rollover bookkeeping written after delivery.

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
