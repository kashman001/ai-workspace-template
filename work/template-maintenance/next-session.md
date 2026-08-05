> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.

## Mission

Execute the already-scoped **upstream skill sync**: integrate the latest
`mattpocock/skills` (clone at `~/Developer/references/mattpocock-skills`,
pulled to `8b36d4f`) — refresh the vendored wayfinder, link the newly
**released** skills globally, and update the template docs. Recon is done
(facts in `handoff.md` top block); this session only executes.

## Read these, in order

1. `work/template-maintenance/handoff.md` — top block only (recon facts).
2. `docs/recommended-tooling.md` §3 — the table + the two blockquote notes
   you'll be editing (file was recently modified by other sessions — re-read,
   don't assume).
3. `skills/wayfinder/SKILL.md` lines 1–17 — the provenance comment whose
   refresh procedure you'll follow.

## The plan (session tasks #8–#11, restated)

1. **Global symlinks** (`~/.config/agent-context/skills/`): remove broken
   `writing-great-skills`; `ln -sfn` from the clone: `writing-for-agents`
   (productivity), `wizard` (engineering), `to-questionnaire`, `wait-what`
   (productivity).
2. **Vendored wayfinder refresh**: re-copy upstream `SKILL.md` +
   `agents/openai.yaml` over `skills/wayfinder/`, re-add the provenance
   comment, update pin `2ab9580` → `8b36d4f` + date. Verify diff vs upstream
   is comment-only.
3. **`docs/recommended-tooling.md` §3**: table — add `wizard`,
   `to-questionnaire`, `wait-what`; rename `writing-great-skills` →
   `writing-for-agents` (also in the summary table at the top of the file,
   line ~24, if present). Rewrite the "newer upstream skills worth watching"
   note: drop graduated ones, note `batch-grill-me` folded into `grilling`;
   remaining in-progress = `claude-handoff` (still anti-recommended vs
   `session-rollover`), `loop-me`, `setup-ts-deep-modules`, `writing-*`.
4. **Backlog** (`docs/template-workspace-backlog.html`): changelog row +
   both "last updated" dates. Then commit (Decision: trailer) and push.

## Do NOT reload

- The wayfinder-integration spec and the 2026-07-30 handoff block — that
  work shipped; only the provenance-comment refresh procedure matters.
- Upstream `in-progress/` skills — still deferred; only released buckets
  are in scope.
- `docs/agents/issue-tracker.md` — verified unaffected by upstream changes.
- The wayfinder smoke test idea from the previous launcher — superseded by
  this sync; re-raise only after the sync lands.

## State snapshot

- Branch `main` at `b1273ea` (+ this rollover commit), tree otherwise clean;
  **no integration changes made yet** — symlinks, vendored copy, docs all
  pre-sync. Session tasks #8–#11 exist (pending) if task state survives;
  otherwise this file is the authority.

## First actions

1. `scripts/context-budget.sh register`
2. Work the plan above in order; verify, commit, push (user has asked for
   push on this work).
