<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

# Session Handoff — 2026-08-07 (session #4: trims declined, Warp attribution settled, inspector fixed)

**Ran as a background job (worktree `context-decay-s4`), user live mid-session.**

**Trim candidates (mission steps 1–2):** measured live (turn-1 = 43,855 exact).
skill_listing ~4,026 tok is only ~307 tok workspace-controlled (built-ins
~1,511 / user-global skills ~954 / plugins ~872); CLAUDE.md moderate pass
~600–800, aggressive ~1,000–1,300, all with real downsides (non-Claude
runtimes, downloaders, always-on behavioral rules). Full table:
`trim-estimates.md`. **User declined all trims** — bar was "unused AND no
negative implications"; decision note in `decisions.md` (2026-08-07). Don't
re-propose.

**Warp attribution (mission step 3): settled.** hook_success stdout/stderr
never enter model context; only the `content` field does (context-budget
SessionStart hook: content≈stdout and visibly in context; Warp PostToolUse/
Stop: content=0; superpowers SessionStart arrives as separate
hook_additional_context). Residual analysis over two Warp-heavy transcripts:
whole-JSON attribution → median residual −43/−14 with 57–73% turns negative;
content-only → uniform small-positive (median ≈ +155). Fixed both jq measure
sites in `scripts/context-inspect.sh` (hook_success now content-length);
verified: 136 Warp records drop to 0 tok, residuals all small-positive.
Backlog L31 (archive), scorecard 49.

**Learnings (parked):**
- Every session on this machine carries Warp plugin hooks — there is no
  non-Warp control session; residual-delta comparison within a session is
  the usable method.
- Backlog archive has pre-existing duplicate IDs (two L19s, two L20s from
  parallel passes; L-series otherwise runs to L30 — new cards start L31).

---

