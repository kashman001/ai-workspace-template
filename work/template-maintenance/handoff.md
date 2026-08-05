<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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
