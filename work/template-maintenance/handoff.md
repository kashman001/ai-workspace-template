<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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
