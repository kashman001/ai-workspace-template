# Session Handoff — 2026-08-12 (session #5: L37 fixed — house-sale mission COMPLETE)

**Trigger:** normal completion (background session, worktree
`worktree-template-maintenance-s5-l37`; well under WARN).

**What shipped (on the worktree branch, NOT yet on main — user merges):**
- **L37** (portable agent brief): new "Portable agent brief" section in
  `docs/work-directory-conventions.md` (between Verification evidence and
  Naming) + a `briefs/<audience>-vN.md` row in the optional-files table.
  Convention: one sealed file per version (corrections = v(N+1)), supersession
  header ("Supersedes all earlier briefs; discard them"), explicit
  never-reveal section (fact + deflection), ledger notes at issue and at
  staleness, skeleton included. Contrasted with dispatch records
  (same-machine children). Convention-only — no skill (simplicity-first;
  promotable if the pattern recurs); Tier-2 note in `decisions.md`
  (2026-08-12: convention-over-skill).
- Card Resolved → archive (Low, before Decisions); scorecard **1 Open
  (M16) / 66 Resolved**. Doc-only change — no suites affected.
- Backlog hygiene: added the change-log row session 4 omitted for its own
  M26+L36 resolution (marked retroactive), fixed the stale footer date.
- `work/README.md` status row refreshed.

**House-sale mission (M26 → L36 → L37) is COMPLETE.** Remaining open card
M16 was explicitly out of mission scope.

---

# Session Handoff — 2026-08-12 (session #4: M26 + L36 fixed; L37 next)

**Trigger:** context-budget WARN at 123K after closing L36.

**What shipped (main, commits `208a228` + `405810b`, local — ahead of origin):**
- Mission queued in the launcher: house-sale cards M26 → L36 → L37 (filed by
  `bc0f682` from the devex-review evidence pass).
- **M26** (no-git "private" mode): `docs/template-usage.md` §1 third
  instantiation variant + "No-git mode" subsection (paste-in Privacy Posture
  block for CONTEXT.md, Tier-1→Tier-2 decision-capture rewrite, N/A list for
  git-dependent machinery); one-line N/A notes at each point of use
  (CONTEXT.md Tier-1 bullet, decision-log / checkpoint / session-rollover
  skills). No code changes — launch-next-session.sh already degrades
  gracefully without git.
- **L36** (instantiation prune): §5 broadened to the full
  template-development prune list (backlog pair, template-usage itself,
  mcp-fragments, LICENSE swap, README index rows, operational-knowledge trim;
  scaffolding dirs stay — check-workspace-structure.sh expects them);
  setup.sh prune reminder gated on the backlog pair (regression T1c); M19
  ledger-migration shim verified via registry G3. Tests: 72/72 registry,
  28/28 instantiation.
- Both cards Resolved → archive with Fixed: notes; scorecard **2 Open
  (M16, L37) / 65 Resolved**. Tier-2 decision notes for both in
  `decisions.md` (2026-08-12: posture-block-over-CONTEXT-section;
  reminder-over-prune-flag).

**Learnings (parked):**
- The backlog *archive* HTML has no scorecard block — the active file's
  scorecard is the single copy; its counts span both files.

**Suggested skills:** `writing-for-agents` (before authoring the L37
convention text); `decision-log`.
<!--
ARCHIVE of work/template-maintenance/handoff.md — older Session Handoff
blocks, newest first. See handoff.md for the purpose header + live blocks.
-->

# Session Handoff — 2026-08-07 (session #3: L17+L18 resolved — backlog at 0 Open)

**Trigger:** normal completion (background session; 107K tokens, under WARN).

**What shipped (branch `worktree-l17-l18-backlog-fixes`, NOT yet on main —
worktree-isolated background session; user merges):**
- L17 (four deferred rollover-script issues): attach-session.sh
  live-but-unlocked message reworded to match its flags (T4d updated); both
  `ls -t` glob loops (attach-session.sh, own_record in
  launch-next-session.sh) made space-safe via `while IFS= read -r`;
  opencode_measure SQL-escapes `$PWD`/`$sid`; the stale registry-suite
  filename was only in the test file's own `# File:` header — the
  docs/context-budget.md reference was already correct.
- L18: per-variable precedence around the context-budget.env source in
  context-budget.sh (capture-before/restore-after, the launch-next-session.sh
  ROLLOVER_* pattern). New regression test T16 — verified red on the pre-fix
  script, green after. Tier-2 decision note (capture/restore over default-only
  env assignments; the latter inverts the per-item override chain).
- All eight test suites green (343 asserts). Backlog: L17+L18 cards moved to
  archive with Fixed: notes; scorecard 0 Open / 46 Resolved; change-log row.

**Learnings (parked):**
- L30's session added no change-log row for L30 in the backlog (card+scorecard
  only); left as-is per surgical-changes.

---

---

# Session Handoff — 2026-08-07 (L30: GitHub MCP removed, gh required; rollover)

**Trigger:** user-requested rollover. Same conversation continued past the
2026-08-06 STOP rollover and shipped one more approved plan.

**What shipped (all on `main`, clean tree, pushed):**
- `2ba9f11` — L30: GitHub MCP fully removed; `gh` CLI promoted to required
  prerequisite (20 files, −101 net). Fragment deleted (re-add recipe in
  `mcp-fragments/README.md`), PAT-export plumbing gone (auth runbook is just
  `gh auth login`), docker dep dropped, ADR-0002 amended, setup-guide.html
  swept (exploration had missed it). Both check scripts verified passing.
- Launcher touch-up commit marking L30 done in the floor-trim thread.
- Backlog: L30 resolved card (scorecard 44); Tier-2 decision note in
  `decisions.md` (full-removal over escape-hatch; `Promote?: no`, ADR-0002
  amendment carries it).

**Learnings (parked):**
- github MCP on this machine was project-local only (stale pre-split live
  `.mcp.json`); user-scope `~/.claude.json` has no `mcpServers` at all —
  `claude mcp list` confirms clean. No user-scope removal was needed.
- Old worktree `.claude/worktrees/session-30-issue-10/` still holds pre-L30
  file copies (separate checkout; intentionally untouched).

---

# Session Handoff — 2026-08-06 (context audit: L25–L29 shipped; STOP rollover)

**Trigger:** context-budget STOP (151K, then 157K mid-rollover) right after the
L29 commit. All work committed and pushed; clean tree.

**What shipped (three commits on `main`):**
- `f9bceae` — L25–L27 demand-load trims: context-budget.md section index +
  grep-the-header access note; decision-log skill heredoc-append + 16KB
  archive rule; CONTEXT.md condensed 14.0→12.6KB (graphify removal steps
  moved into recommended-tooling.md §5, ending its circular pointer).
- `4b94d76` — L28: `register` tolerates a missing/empty transcript at
  SessionStart (`method=deferred status=OK`, exit 0) instead of "error:
  measurement failed"; register instruction scoped so Claude Code agents
  don't re-run what the hook already did. Verified live.
- `a3da781` — L29: /context under-reports ~10K until the first real message
  (harness listing attachments materialize with turn one); gotcha documented
  in `docs/operational-knowledge.md`. Tracker was correct throughout.
- Backlog: L25–L29 resolved cards in the archive file, scorecard 43 Resolved.
- Tier-2 decision note (index-over-split, condense-over-delete) in
  `decisions.md`.

**Learnings (parked):**
- Empty-session floor measured ~44.7K (2026-08-06): harness-fixed ~22.5K;
  superpowers plugin ~1.8K; MCP-attributable ~2.2K (github ~900,
  chrome ~500 + ~800 hidden in system prompt/skill, claude.ai connectors
  ~410, rest small); skills roster ~4.9K. Per-server/per-skill tables live
  only in the 2026-08-06 session transcript — re-derive from a fresh
  session's jsonl if needed (method: jq over attachment types).
- Warp terminal plugin injects a `hook_success` envelope per PostToolUse —
  model-visible cost unmeasured; worth checking if it bites again.

---
# Session Handoff — 2026-08-05 (closed out: launch-next-session effort spun out to its own project)

The open question in the block below (background demo vs interactive) was
resumed and resolved: demo run, discussion held, and the whole effort spun
out into **`work/automatic-session-rollover/`** at the user's request — it
grew from one script into script + optionality knobs + cross-vendor trigger
reliability + multi-session identity redesign. See that project's
`relaunch-analysis.md` and ADR-0003 for everything; nothing about this
effort remains pending in template-maintenance. The launcher here is
retargeted to umbrella/backlog duty.

---

# Session Handoff — 2026-08-05 (follow-up: claude-handoff comparison; launch-next-session.sh mission queued; STOP rollover)

**Trigger:** user-requested rollover; budget hit STOP (150K) as it started.
Same session as the hardening execution below, continued interactively.

**What happened after the hardening close-out:**
- Compared upstream `claude-handoff` (in-progress bucket, clone `8b36d4f`,
  18 lines) against `session-rollover` — the comparison the recon note had
  skipped. Verdict: its three content rules already landed via the inlined
  hand-off contract (hardening item 5); its prompt-only background-handoff
  mechanism stays rejected; the one adopted concept is launch acceleration.
- User approved building `scripts/launch-next-session.sh` (multi-runtime,
  vendor specifics confined to the script per CLI-first). Full mission spec +
  verdict + implementation notes queued in `next-session.md`, pushed
  (`01a851c`) — read that, not this, for what to build.
- **Open question, paused mid-answer:** how to start the implementing session
  — a `claude --bg` background demo of the concept vs interactive
  implementation. The user chose "roll over and continue the discussion".
  Resume that question before implementing.
- No code written this segment; only launcher/ledger bookkeeping mutated.

---

# Session Handoff — 2026-08-05 (skill-hardening plan EXECUTED; all 8 items shipped)

**Trigger:** mission complete — the full `skill-hardening-plan.md` executed and
pushed to `main`; work-unit boundary at ~110K tokens (OK).

**What shipped (three commits on `main`; see `git log` for shas):**
1. Items 1–7 — skill fixes: checkpoint's promotion scan now also sweeps
   `work/*/map.md` Decisions-so-far (cross-ref in decision-log); onboard-repo's
   budget cadence moved above its steps; convention pointers unified on
   `CONTEXT.md` (rlm, issue-tracker.md); create-work-item optional files gained
   `spec.md`/`map.md`/`issues/`; runnable Verification sections added to
   checkpoint / create-work-item / session-rollover / decision-log; identical
   "Which boundary skill?" first-yes-wins block in checkpoint +
   session-rollover; global-`handoff` prerequisite replaced by an inlined
   3-rule hand-off contract in both; `disable-model-invocation: true` on
   create-work-item / onboard-repo / rlm; ADR bar restated as the three-way
   AND test in decision-log + `docs/adr/README.md` with a "don't log this"
   counter-example.
2. Item 8 — vendored `skills/writing-for-agents/` (SKILL.md +
   SKILL-MECHANICS.md + agents/openai.yaml) at pin `8b36d4f`, provenance
   comment mirroring wayfinder's; diff vs upstream verified comment-only.
   Wired: CONTEXT.md bullet (+ checkpoint bullet updated for the arbitration/
   contract changes), recommended-tooling §3 blockquote now covers both
   vendored skills.
3. Item 9 — backlog changelog row for the whole batch; Tier-2 note for the
   inline-handoff-contract decision appended to `decisions.md`; this ledger/
   launcher rollover.

**Verification done:** per-item greps from the plan; diff-vs-upstream for the
vendored skill; `bash -n scripts/*.sh` clean; each edited SKILL.md re-read
top-to-bottom (one drift caught: checkpoint Outputs still naming the handoff
skill's default location — fixed).

---

# Session Handoff — 2026-08-05 (skill-comparison analysis → hardening plan; rollover before execution)

**Trigger:** user-requested rollover at ~114K tokens (75%, OK) — execution of
the approved plan deliberately deferred to a fresh session.

**What happened (same session as the sync execution below):**
- After the sync, the user asked for a comparison of Matt Pocock's skill
  library vs this workspace's own skills. Two Explore subagents swept all 35
  upstream SKILL.md files (clone `8b36d4f`) and all 6 workspace skills +
  conventions docs; findings synthesized into 7 improvement areas, all
  **approved by the user**, plus an 8th (vendor `writing-for-agents`).
- Full execution spec written to `skill-hardening-plan.md` (every needed
  finding restated there — the comparison agents need not be re-run).
- Tier-2 note recorded in `decisions.md` (vendor-as-skill vs docs-page).
- Ledger housekeeping: blocks older than the top two archived to
  `handoff-archive.md` (first archival for this work dir).
- **No skill files were modified** — the tree at rollover contains only these
  work-dir artifacts.

**Notable findings that drove the plan** (detail in the plan file):
checkpoint's promotion scan misses wayfinder `map.md` decisions; checkpoint +
session-rollover both depend on the global `handoff` skill absent from this
repo; no verification sections in half the skill set; boundary-skill
arbitration undefined; invocation-axis (`disable-model-invocation`) unused;
upstream's ADR three-way AND test is sharper than our "lasting weight".

---

# Session Handoff — 2026-08-05 (upstream-sync EXECUTED; pushed `823f8c2`)

**Trigger:** work-unit boundary — the sync scoped by the previous session's
recon is fully executed, committed, and pushed; ~83K tokens (OK).

**What shipped (`823f8c2` on `main`, pushed):**
- Global symlinks (`~/.config/agent-context/skills/`): broken
  `writing-great-skills` removed; `writing-for-agents`, `wizard`,
  `to-questionnaire`, `wait-what` linked from the clone (at `8b36d4f`).
  Broken-symlink scan clean. `global.md` setup/util list updated to
  `writing-for-agents` (machine-side, outside the repo).
- `skills/wayfinder/` refreshed to `8b36d4f`: SKILL.md re-copied, provenance
  comment re-added with new pin+date; `agents/openai.yaml` verified identical
  to upstream (no copy needed); diff vs upstream re-verified comment-only.
- `docs/recommended-tooling.md` §3: three new table rows, rename, "worth
  watching" note rewritten (graduated skills dropped; `batch-grill-me` →
  folded into `grilling`; in-progress remainder listed). Top summary table
  (line ~24) never listed `writing-great-skills` — no change needed there.
- Backlog: 2026-08-05 changelog row + both last-updated dates.

**Notes for later:** historical mentions of `writing-great-skills` /
`batch-grill-me` in the backlog changelog, the 2026-07-30 spec, and these
work-dir files were left as-is (provenance, not live docs).

---

# Session Handoff — 2026-08-05 (upstream-sync recon; STOP before execution)

**Trigger:** context-budget STOP (~158K) fired right after recon completed;
per convention no integration work was started. **Nothing mutated**: global
symlinks, vendored `skills/wayfinder/`, and all docs are untouched by this
session. Only the reference clone was pulled (to `8b36d4f`).

**What this session produced:** a complete recon of upstream
`mattpocock/skills` changes since our `2ab9580` pin, plus a scoped execution
plan (tasks #8–#11 in the session task list; full detail re-stated in
`next-session.md` — read that, not this, for what to do).

**Key facts (verified against the clone at `8b36d4f`):**
- Newly **released** skills: `wizard` → `engineering/`; `to-questionnaire`,
  `wait-what` ("that message didn't land — re-pitch it"), and
  `writing-for-agents` → `productivity/`. `writing-for-agents` is a
  rename+restructure of `writing-great-skills` (upstream `1fc6573`), which
  leaves `~/.config/agent-context/skills/writing-great-skills` a **broken
  symlink**.
- `batch-grill-me` is gone — folded into `grilling` (upstream `a4b2009`,
  round-by-round frontier interview).
- `wayfinder` upstream diff since our pin: cosmetic emphasis-char churn plus
  one real line — Grilling ticket type is now "Conversation. The default
  case. Always invoke the /grilling and /domain-modeling skills."
  `agents/openai.yaml` not yet diff-checked.
- Upstream `issue-tracker-local.md` changed only trivially (wording);
  our `docs/agents/issue-tracker.md` adaptation is unaffected.
- A `deprecated/` bucket exists upstream but holds only a README at HEAD.
- User's earlier deferral of `wizard`/`to-questionnaire` applied only while
  they were in-progress; they explicitly asked to integrate formally
  released skills now.

---

# Session Handoff — 2026-07-30 (wayfinder integration)

**Trigger:** context-budget WARN (~129K tokens) after work completed.

**What shipped (all committed to `main`, tree clean):**

- `3b86e3c` — approved design spec:
  `docs/superpowers/specs/2026-07-30-wayfinder-integration-design.md`.
- `eb3bd4d` — the integration itself (hybrid approach):
  - `skills/wayfinder/` vendored from `mattpocock/skills` @ `2ab9580`
    (SKILL.md + agents/openai.yaml; provenance comment carries the pinned
    commit + refresh procedure). Diff vs upstream verified comment-only.
  - `docs/agents/issue-tracker.md` — local-markdown tracker; maps at
    `work/<effort>/map.md`, tickets `work/<effort>/issues/NN-<slug>.md`
    (adapted from upstream's `.scratch/`); decision-log tie-in (resolved
    ticket = Tier-2 note; promote via `/decision promote`).
  - Wiring: `CONTEXT.md` Workspace Skills bullet, `.claude/commands/wayfinder.md`,
    `docs/workspace-structure.md` (also fixed `create-work-item` missing from
    its skills listing), `docs/work-directory-conventions.md` optional-files
    table, backlog changelog row (dated 2026-07-30).
  - `docs/recommended-tooling.md`: `in-progress/` bucket documented,
    vendored-copy/duplicate caveat, "newer upstream skills worth watching"
    note.
- `a079b85` — correction: `agent-context-sync` scans only
  `engineering/productivity/misc` buckets (BUCKETS array, script line 30), so
  `in-progress/` skills need manual `ln -sfn`.

**Also done:** reference clone `~/Developer/references/mattpocock-skills`
pulled to upstream HEAD `2ab9580` (all installed skills are symlinks → now
current). Memory saved: integrations must be agent-agnostic (incl. Copilot).

**Decisions (with rejected alternatives) — recorded in spec + commit trailers:**
hybrid vendoring (only wayfinder in-repo; full-vendor and document-only
rejected); maps under `work/<effort>/` not `.scratch/`.

**User declined (do not re-raise unprompted):** linking the `in-progress`
skills `to-questionnaire` / `wizard`; adding `in-progress` to the sync
script's BUCKETS.
