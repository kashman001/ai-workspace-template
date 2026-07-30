<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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
