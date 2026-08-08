# Catchup prompt — usage-scenarios (paste into a new agent session)

We're resuming usage-scenarios. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## First actions

1. `git fetch origin` + confirm `git log HEAD..origin/main` is empty before
   trusting this launcher (L33 race). If in a fresh worktree, also
   `git merge --ff-only main` — worktrees branch from origin/main, which
   may lag local main.
2. Confirm session-4's branch (`worktree-quiet-marinating-dolphin`) was
   merged to main. If not, deliver it first — it carries Gaps 6+2 and the
   walk-through verdicts.

## Mission (session 5): Gaps 3+8 — tooling manifest + capability authoring doc

Per the user-adopted sequencing (see decisions.md, 2026-08-08): Gap 6
(clean-room test) and Gap 2 (Z0 templates) are DONE. Next up together:

- **Gap 3** — extend `scripts/check-dependencies.sh`'s existing `req`/`rec`
  lists as the required-vs-optional manifest; add the same hard-fail
  distinction to `check-service-access.sh` (today it always exits 0); one
  "required for everyone" table in recommended-tooling.md replacing its
  blanket "everything optional". NO new manifest file format.
- **Gap 8** — documentation only: a capability-authoring section with the
  container decision rule (scripts/ vs skills/ vs .claude/agents/ vs
  runbooks/), the two mechanical wiring steps (.claude/commands/ mirror +
  CONTEXT.md listing), and a hook into Gap 3's required list. NO
  create-capability skill.

Then Gap 7 (zoom docs + execute the endorsed HTML retirement) in a later
session. Gaps 4 and 1 stay deferred until a second service/person is real.

## Read these, in order

1. `work/usage-scenarios/gaps-and-coverage.md` — Gap 3 + Gap 8 sections
   and the simplicity guardrails (binding don't-build list).
2. `work/usage-scenarios/decisions.md` — the two 2026-08-08 verdict notes.
3. `scripts/check-dependencies.sh` + `scripts/check-service-access.sh`
   before touching them; run `scripts/tests/test-template-instantiation.sh`
   after any change (it clones COMMITTED state — commit first).

## Do NOT reload

- `ground-truth.md`, `scenarios.md` — open only to verify a specific fact.
- docs/context-budget.md, workspace-structure.md, ADRs — targeted reads only.

## Constraints already decided (do not re-litigate)

- Simplicity guardrails (user, 2026-08-08) are binding; prefer documenting
  over building.
- Sequencing adopted as-is; usage-scenarios.html retirement endorsed
  (execute under Gap 7, not before).
- Update the M15 backlog card + change-log row when gaps land; M15 closes
  when Gaps 3+8 and 7 are done.

## State snapshot

- Branch: worktree-quiet-marinating-dolphin (session 4) — merge to main
  pending, then delete.
- Backlog: M15/M16/L32/L33 Open (4). Nine test suites, all green.
- No running processes, no open subagents.
