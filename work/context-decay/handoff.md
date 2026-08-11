<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-11 (session #6: dormant watch check + security audit + email history rewrite)

- Watch check: 0 rollovers since session #5; only post-change data point is
  #5's own delta (~4.2K, beats the 6–7K prediction). Fixed launcher count
  baseline 37→40 (4 pre-change completes were miscounted as new); comparison
  triggers at ≥45 total `rollover complete` ledger entries.
- Verified the pasted context-decay research against primary sources via
  Chrome: Pocock dictionary 125K–150K "debated" verbatim; Chroma + RULER
  confirmed (with precision fixes); the research's "better mechanism" is
  largely lifted from the same Anthropic post it critiques, and Pocock's
  dictionary states dilution, not the quadratic story attributed to him.
  Outcome baked into `context-budget.env` header comment (threshold update
  rule + source links) — rejected a prose note in docs/context-budget.md as
  standing-context weight.
- Full secrets/PII audit of the workspace: no secrets in tree, history, env,
  or scripts; no emails/phones/IPs in file content; .gitignore coverage
  verified. Findings: commit-metadata emails on the public repo. User kept
  the yahoo address; work email purged via `git filter-repo` rewrite (12
  commits → noreply), force-pushed. **All SHAs from 2026-07-23 onward
  changed** (e.g. R1–R5 commit `6d637b1`→`23f3b9b`); tree content verified
  identical. Backup bundle (contains old history — delete when satisfied):
  `~/Developer/experiments/ai-workspace-template-pre-filter-backup.bundle`.
  Decision note appended to `decisions.md`.
- USER ACTION PENDING: other machine must `git fetch && git reset --hard
  origin/main` and switch its `git config user.email` off the work address,
  or the leak recurs on its next push.

Suggested skills: `session-rollover` (watch cadence); `decision-log`.

Learnings:
- Pre-rewrite SHAs in older handoff blocks/ledger/backlog rows are stale —
  map via commit message (`git log --all --format='%h %s' | grep`).
- gitleaks/trufflehog not installed on this machine; pattern-grep sweep is
  the fallback (`sk-` pattern false-positives on "disk-state").

# Session Handoff — 2026-08-11 (session #5: rollover-cost analysis + R1–R5 shipped)

- User question (from heavy deployment's F3): why does rollover cost ~20K, how
  to cut it. Wrote `rollover-cost-analysis-2026-08-11.md`: 36 local ledger
  deltas show median ~4.6K (July) → ~11K (Aug), tracking SKILL.md growth
  4.6→12.1KB; floor ~8–10K mechanical + 0–25K deferred bookkeeping; heavy 20K
  is the same curve further along.
- Applied R1–R5 (user-approved), commit `6d637b1` + rollover commit after it:
  `scripts/rollover-prep.sh` one-shot prep (29-assert suite
  `scripts/tests/test-rollover-prep.sh`), SKILL.md 12,074→9,222 bytes,
  write-ahead as standing discipline, ≤40-line handoff-block cap,
  self-sufficiency note (no context-budget.md load mid-rollover).
- Two-axis review (Standards+Spec subagents) findings applied: `--reason`
  infinite-loop fix + T9d, WARN-declined write-ahead branch restored, stale
  step-7 refs fixed (ADR-0007, work-directory-conventions.md). Green:
  29/29 rollover-prep, 27/27 template-instantiation, structure checks.
- Backlog: M18 filed + resolved (archived), scorecard 3/52/4/0/6, change-log
  row. Tier-2 decision note in `decisions.md` (sibling script over
  subcommand; rotate-to-one-block-pre-write).
- First live prep run archived 4 overdue blocks from this file (verified
  lossless vs HEAD). This session then dogfooded the new procedure at STOP
  (~160K after apply+review+commit) — its start→complete ledger delta is the
  first post-change data point for the savings validation.

Suggested skills: `decision-log`; `session-rollover` (measure at unit ends).

Learnings:
- Backlog change-log rows are chronological-ascending (append at table END);
  cards are newest-on-top — easy to get backwards.
- `$c:path` in zsh triggers history-modifier parsing — quote `"$c:path"` in
  `git show` loops.

