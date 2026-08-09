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

Rollover addendum (2026-08-09): user requested close-out rollover. The
twice-bitten worktree-Bash-guard learning was promoted to
docs/operational-knowledge.md (compound-commands section extended);
sessions 4+2 blocks archived to handoff-archive.md.

Suggested skills (next session): `checkpoint` (fold into close-out),
`decision-log` (if the HTML-supersede note gets promoted to an ADR).

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

