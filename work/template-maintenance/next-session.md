<!-- LAUNCHER: forward-looking only; REPLACED at each rollover. History: handoff.md -->

# Next Session — template-maintenance (session #8)

## Mission

Finish backlog item **M31** (Claude Code hook wiring is now committed, updating
with `git pull` like every other runtime): complete the docs, test the change,
get it reviewed, then deliver — commit, merge to `main`, push to remote. The
user has explicitly authorized the full delivery ("commit, merge and deliver to
remote"); do not stop to re-ask for push permission.

## Read these, in order

1. `git show a660150` — the partial fix + its commit body's remaining-steps list.
2. `docs/template-workspace-backlog.html` — grep `M31` (card carries evidence/fix).
3. `docs/context-budget.md` — grep "Vendor hook deployments" (the table row and
   the two registration paragraphs to update).

## Do NOT reload

- `skills/session-rollover/SKILL.md` / supervisor internals — the relaunch-gap
  diagnosis is settled and recorded in handoff.md session #7 block.
- The Claude Code settings JSON schema — already validated; `_comment` is
  rejected in tracked `.claude/settings.json`, allowed in `.example`.
- Whether other runtimes need the same fix — they don't; wiring already
  committed (verify with one `git ls-files` in step 2 below, nothing more).

## State snapshot

- Branch `vendor-mattpocock-skills`, **ahead of origin by 1** (a660150) plus
  this rollover-bookkeeping commit; working tree otherwise clean.
- Backlog M31 card: **Open** (correct — fix not fully landed). Scorecard 7 open.
- `.claude/settings.json` tracked as of a660150; example stripped of hooks.
- PR #23 (M30 vendoring) context: this branch is long-lived and was merged
  with main at 036a0af; delivery = merge this branch to main and push.

## First actions

1. `scripts/context-budget.sh register` (hook likely already ran it — don't re-run if so).
2. **Finish M31 edits:**
   - `docs/context-budget.md`: Claude Code row in "Vendor hook deployments"
     (wiring file is now committed `.claude/settings.json`; personal
     permissions in gitignored `settings.local.json`); the two paragraphs
     saying registration lives in `settings.json.example`; add an
     existing-workspace migration note (untracked local `settings.json`
     collides on pull — move it aside, keep personal bits in
     `settings.local.json`, then pull).
   - `CONTEXT.md`: fix "committed for all but Claude Code, whose copy
     scripts/setup.sh materializes" → committed for all six runtimes.
   - Verify: `git ls-files .codex .gemini .opencode .github/hooks .claude/settings.json`
     shows all six runtimes' wiring tracked.
   - Backlog: move M31 card to `docs/template-workspace-backlog-archive.html`
     as Resolved with a `Fixed:` note; scorecards Open 7→6, Resolved 68→69.
3. **Test — scenarios to cover (add/execute, keep surgical):**
   - `bash scripts/tests/test-vendor-budget-hooks.sh` — existing suite; extend
     it (or add a small test) to assert `.claude/settings.json` is tracked,
     valid JSON, carries all four hooks (SessionStart/PostToolUse/SessionEnd/
     Stop) in the resolver form, and that `settings.json.example` contains NO
     hooks/statusLine (the double-fire guard).
   - Fresh-clone simulation: `git worktree` or temp clone → `scripts/setup.sh`
     → assert `settings.local.json` created from example WITHOUT hooks and
     tracked `settings.json` present.
   - Migration collision: temp clone at a660150^ with an untracked
     `.claude/settings.json` → `git merge`/checkout forward → assert git
     refuses (documents the migration note's claim).
   - Run the neighbouring suites touched by this area if cheap:
     `test-session-loop.sh`, `test-turn-end-exit.sh` (Stop-hook path).
4. **Review:** run the `code-review` skill over the branch's M31 commits
   (standards + spec vs the M31 card). Address findings.
5. **Deliver (authorized):** commit remaining edits (Decision trailer per
   convention), merge `vendor-mattpocock-skills` → `main` (ff or merge commit
   per repo habit — recent history uses PRs; a direct merge+push is authorized
   here), push `main` and the branch to origin. Update backlog card timestamps
   if the merge SHA differs from what the card cites.
6. Record work-unit boundaries: `scripts/context-budget.sh record --label ...`;
   at WARN/STOP follow `skills/session-rollover/SKILL.md`.
