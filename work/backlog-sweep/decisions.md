# Decisions — backlog-sweep

Tier-2 decision notes (`skills/decision-log/SKILL.md`), newest last.

## 2026-10-18 — One work item and one plan for L85, L95, L96, L98, L86

- **Decision:** run the remaining open cards as one plan in this item,
  wave 1 in parallel subagents, instead of a work item per card.
- **Why:** the user asked for one plan executed in parallel with fitting
  model tiers; the cards are small and independent, so one board and one
  reconcile per wave is the least overhead.
- **Rejected:** a separate `dispatch-contract-hardening` item for L95, as
  its card suggested — it would split the board for a one-node piece of work.
- **Rejected:** putting L97 in the plan — its card defers it until
  `work/concurrent-sessions/` settles R1.

## 2026-10-18 — L98 pilot spend is authorized, with a cap

- **Decision:** the L98 pilot's headless runs need no further approval: the
  user asked for the remaining work to be done ("accomplish it"). Node 04 sets
  a cap (target ≤ 45 headless runs) and states its estimate; node 06 stops at
  the cap.
- **Why:** a `hitl` gate before spend would stall the chain on a question the
  user has already answered.
- **Rejected:** a `hitl` approval node before the pilot run.
- **Promote?:** no.

## 2026-10-18 — Backlog files are written only by reconcile nodes

- **Decision:** child agents never edit `docs/template-workspace-backlog*.html`;
  each wave's reconcile node moves the cards it verified.
- **Why:** two other sessions share this checkout; isolated children merging
  scorecard edits would conflict, and only a verified claim should close a card.

## 2026-10-18 — L96: document the usage-limit/watchdog interaction, no code fix

- **Decision:** a paragraph in `docs/context-budget.md` (raise or zero `SESSION_LOOP_KILL_AFTER` per work item) instead of teaching the watchdog to recognise the wait.
- **Why:** whether Claude Code writes to the transcript during the wait is unverified, so there is no signal a test could assert on (`l96-findings.md`).
- **Rejected:** a watchdog change guessed without a real limit-hit transcript.

## 2026-10-18 — L85: test-doc-consistency keeps running in instances

- **Decision:** in an instance, `test-doc-consistency.sh` drops only the `work/plans/` pins and exits 0; the other three suites exit 77.
- **Why:** the card's fix says to skip only the template-work pins for that suite; node 01's Acceptance box 2 ("each exits 77") over-read it.
- **Rejected:** skipping the whole suite — it would hide instance-valid doc checks.

## 2026-10-18 — L86 Codex desktop probe runs on Codex inside ChatGPT.app

The standalone Codex desktop app (`codex-app` cask) is discontinued upstream; brew names
`chatgpt` as its replacement. The probe ran Codex inside ChatGPT.app ("Codex Desktop",
local folder) instead. Rejected: installing the deprecated cask — it probes a surface
on its way out. Node 12 writes `probes/codex-app.md` from this run.

## 2026-10-18 — Claude hooks: allowlist own transcripts, not denylist foreign ones

Codex Desktop runs `.claude/settings.json` hooks, as Copilot CLI does. The claude hooks now
act only on a Claude Code transcript (`<config>/projects/<slug>/*.jsonl`,
`budget_hook_is_claude_transcript`), and settings.json carries no logic (`cc1173e`). User's
call, s5. Rejected: a per-runtime denylist (one more regex per leaking runtime, copied in
three places), or a denylist table (still needs a new row after each leak).

## 2026-10-18 — L99 prune `code-simplification`; L100 re-test `unslop` first

User's call, s5, on the agent's suggestion. L99: remove from the vendored set. It scored
below no-skill, and the judge flagged behaviour-changing rewrites; `karpathy-examples`,
the always-on principles and `/simplify` cover the ground. L100: re-run the pilot on
harder, longer writing tasks (2–3 samples per task) before deciding; remove it if it
ties again. Rejected: keeping both (no measured gain), or pruning L100 on a tie from
3 easy tasks.

## 2026-10-18 — L100: keep `unslop`

Re-test on six harder, longer tasks (two samples each) scored none/dummy/skill 37/37/52 of 60;
the skill won or tied every cell, so it meets the keep rule. Tasks follow the user's s6 call
that unslop is for coding work: PR, README, code comment and design-doc prose, plus the
email and announcement. Rejected: pruning on the t1–t3 tie, whose short buzzword inputs
every arm already fixed.
