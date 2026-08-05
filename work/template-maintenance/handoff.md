<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
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
