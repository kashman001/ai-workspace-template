<!--
ARCHIVE of work/template-maintenance/handoff.md — older Session Handoff
blocks, newest first. See handoff.md for the purpose header + live blocks.
-->
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
