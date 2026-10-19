# Catchup prompt — html-kit (paste into a new agent session)

We're resuming html-kit. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

Finish plan `plans/04-adopt` (decisions.md → "Adopt the HTML kit, small first
step"). Wave 1 is done; work the frontier node by node.

<!-- plan:begin position -->
Position: plan 04-adopt, open, wave 2 of 3, done 3/7, doing 0, todo 4, blocked 0, dropped 0, sessions 1.
Frontier: 04-move-and-convert. Remaining: 4 of 7 — wave 2: 04-move-and-convert todo, 05-reconcile-w2 todo.
<!-- plan:end position -->

## First actions

1. `scripts/context-budget.sh register --project html-kit`
2. `scripts/plan.sh status`, then `scripts/plan.sh start 04-move-and-convert`
   and work its Goal/Acceptance (node file). Move with `git mv`; fix the
   render-check default out-dir and the sample's kit path; convert
   `docs/setup-guide.html` from `prototype/setup-guide.html`; greps,
   check-links, render-check, view every shot (contact sheet: Session 8
   learning in `handoff-archive.md`/block 8). Then reconcile 05.
3. Node 06: docs index, `docs/workspace-structure.md`, backlog card (CONTEXT.md
   "Template Backlog"), and promote the adopt decision as **TADR-0015** in
   `docs/template-adr/` (template machinery; `decision-log` promote) — include
   "SVG allowed but themed", render-check rule, and the Copilot/Codex/Gemini
   evidence (RESULTS Sessions 8–9). Then reconcile 07 and close the plan
   (`status: closed` in plan.md).
4. Commit per node, staging only paths you touched (other sessions share this
   checkout). Push is the user's call.

**No human present:** do everything; nothing left needs a person.

## Read these first, in order

1. `work/html-kit/handoff.md` — top block (session 9)
2. `work/html-kit/plans/04-adopt/plan.md`

## Do NOT reload

- Copilot/Codex/Gemini runs: done; results in `prototype/RESULTS.md` Sessions 8–9.
- The four rule fixes: done (node 02).
- Mac 500px crop on some 390 shots: known, harmless.

## Constraints already decided (do not re-litigate)

- HTML stays the source of truth for human-facing pages.
- Agent-agnostic: plain CSS/JS files plus docs, no runtime-specific skill.
- Diagram pages are reviewed by Claude Code (render check + viewing shots).
- Backlog HTML pages are NOT converted; `workspace-structure.html` converts at its next edit.

## State snapshot

- Branch `main`, ahead of origin (push is the user's call).
- Unrelated uncommitted files from other sessions (`.claude/settings.json`,
  `scripts/hooks/…`, backlog-sweep, runtime-session-identity) — not ours; leave them.
- Session 9 had to `register --takeover` after the Copilot child run took ownership; if you dispatch any runtime CLI, expect the same (ledger block 9 learning).
