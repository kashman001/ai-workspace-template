> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.

# Next Session — context-decay

## Mission

**Watch mode: rollover-cost savings validation.** R1–R5 from
`rollover-cost-analysis-2026-08-11.md` shipped (new `scripts/rollover-prep.sh`
+ slimmed `skills/session-rollover/SKILL.md`). Predicted mechanical floor
~10K → ~6–7K. Post-change data points so far: session #5's delta ~4.2K,
session #6's delta (last two ledger entries). When `grep -c 'rollover
complete' work/context-decay/context-ledger.jsonl` reaches **≥45** (40
pre-change + 5 post-change), compare post-change `rollover start`→`complete`
deltas against pre-change medians (~11K local / ~20K heavy) and record the
verdict in the analysis doc. No other active mission.

## Read these, in order

1. This file.
2. TOP block of `handoff.md` (session #6) — only if picking up related work.

## Do NOT reload

- `plan-snapshot-tool.md`, `context-decay-spec.md`, `design.html`,
  `trim-estimates.md` — reference only.
- **Gemini auth on this machine** — settled dead ends
  (`docs/operational-knowledge.md`); do not retry.
- `ledger-analysis.md` — superseded on rollover cost by
  `rollover-cost-analysis-2026-08-11.md`; re-read only at the next full pass.
- Turn-1/standing-context trims — declined by user 2026-08-07; do not
  re-propose.
- Security/PII audit — done session #6, workspace clean; yahoo commit email
  accepted by user; do not re-scan or re-raise.

## Open items

1. Savings validation (the mission above) — gated on ≥45 total completes.
2. USER ACTION: other machine needs `git reset --hard origin/main` + git
   config email change (history was rewritten session #6 — old SHAs stale;
   see handoff.md). If its push fails or SHAs mismatch, this is why.
3. Gemini live-response verification — needs a user `GEMINI_API_KEY`.
4. Copilot CLI adapter live verification — needs Copilot CLI installed.
5. Next full ledger analysis — after ~40 new entries / first
   `method=estimate` rows.
6. User-global context cleanup — deferred by user 2026-08-07; only if raised.

## State snapshot

Session #6 worked on `main`, committed and pushed everything (tip `4fc894a`
before the rollover bookkeeping commit). Whole history rewritten by
filter-repo — pre-2026-08-11 SHAs in older docs are stale; backup bundle at
`~/Developer/experiments/ai-workspace-template-pre-filter-backup.bundle`
(user deletes when satisfied). No worktree, no running processes.
`.rollover-options` carries `ROLLOVER_OPT_APPROVAL=auto`. Unrelated untracked
dir `work/kimi-k3-agent-integration/` belongs to another effort — leave it.

## First actions

1. `scripts/context-budget.sh register` (skip if the SessionStart hook ran).
2. `git pull --ff-only origin main` (another deployment also pushes here; if
   it diverges, that machine hasn't reset onto the rewritten history yet —
   do NOT merge old-history commits back in; tell the user).
3. `grep -c 'rollover complete' work/context-decay/context-ledger.jsonl` —
   ≥45: run the savings comparison (mission); otherwise ask the user what's
   next or stay dormant.
