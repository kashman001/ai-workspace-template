> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.

# Next Session — context-decay

## Mission

**Watch mode: rollover-cost savings validation.** R1–R5 from
`rollover-cost-analysis-2026-08-11.md` shipped in session #5 (new
`scripts/rollover-prep.sh` + slimmed `skills/session-rollover/SKILL.md`).
Predicted mechanical floor ~10K → ~6–7K. After ~5 post-change rollovers
accumulate in `context-ledger.jsonl`, compare `rollover start`→`complete`
deltas against pre-change medians (~11K local / ~20K heavy; session #5's own
delta is the first data point) and record the verdict in the analysis doc.
No other active mission.

## Read these, in order

1. This file.
2. TOP block of `handoff.md` (session #5) — only if picking up related work.

## Do NOT reload

- `plan-snapshot-tool.md`, `context-decay-spec.md`, `design.html`,
  `trim-estimates.md` — reference only.
- **Gemini auth on this machine** — settled dead ends
  (`docs/operational-knowledge.md`); do not retry.
- `ledger-analysis.md` — superseded on rollover cost by
  `rollover-cost-analysis-2026-08-11.md`; re-read only at the next full pass.
- Turn-1/standing-context trims — declined by user 2026-08-07; do not
  re-propose.

## Open items

1. Savings validation (the mission above) — gated on ~5 real rollovers.
2. Gemini live-response verification — needs a user `GEMINI_API_KEY`.
3. Copilot CLI adapter live verification — needs Copilot CLI installed.
4. Next full ledger analysis — after ~40 new entries / first
   `method=estimate` rows.
5. User-global context cleanup — deferred by user 2026-08-07; only if raised.

## State snapshot

Session #5 worked on `main` directly, committed and pushed (`6d637b1` + the
rollover bookkeeping commit). No worktree, no running processes.
`.rollover-options` carries `ROLLOVER_OPT_APPROVAL=auto`. Unrelated untracked
dir `work/kimi-k3-agent-integration/` belongs to another effort — leave it.

## First actions

1. `scripts/context-budget.sh register` (skip if the SessionStart hook ran).
2. `git pull --ff-only origin main` (another deployment also pushes here).
3. Count post-change rollovers:
   `grep -c 'rollover complete' work/context-decay/context-ledger.jsonl`
   minus the 40 pre-change ones (everything before session #5's own complete
   at 2026-08-11T17:28:36Z; verified session #6). Session #5's own delta is
   post-change data point #1, so run the savings comparison (mission) when
   the total reaches ≥45; otherwise ask the user what's next or stay dormant.
