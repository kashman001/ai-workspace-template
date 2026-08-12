# Catchup prompt — DevEx fix package (a): clean day-1 state (M19)

We're resuming devex-review — now the FIX PROGRAM, not the review. Works in
any runtime (Claude Code, Codex, Gemini, OpenCode).

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (append-only
> ledger). Convention: docs/work-directory-conventions.md.

## Mission

Execute fix package (a) — backlog card **M19**, "clean day-1 state": the
template must stop shipping its maintainer's lab notebook. Concretely:
1. Move the context-budget telemetry ledger out of `work/context-decay/` to
   `.context-budget/` (it's core plumbing writing into a deletable research
   dir that silently reappears — see `scripts/context-budget.sh:40` area).
2. Add a prune-`work/` step to `docs/template-usage.md`.
3. Promote doc-worthy `work/` research content to `docs/archive/`.
4. Strip `work/context-decay/*-analysis*.md` evidence pointers from shipped
   skills (cite conclusions inline or point at the archived copy).
Close by flipping M19 to Resolved (+ `Fixed:` line) and moving the card to
`docs/template-workspace-backlog-archive.html` per its maintenance rules.

## Read these, in order

1. `docs/template-workspace-backlog.html` — the M19 card only (grep "M19").
2. `work/devex-review/decisions.md` — top note: the agreed package sequence.
3. Raw evidence on demand: `work/devex-review/findings/dev-persona.md`
   items 8, 9, 10 and `qa-persona.md` A4 — targeted greps, not whole files.

## Do NOT reload

- `findings/devex-review.md` in full — its fix list is already carded
  (M19–M24, L34); the card is the work order.
- The persona review process — complete; never re-dispatch.
- Sequencing debate — settled with the user (see decisions.md): after this
  package comes (c) M24 setup correctness, then (b) M20–M22 spec workflow.

## Constraints already decided (do not re-litigate)

- One work item for the whole fix program; one package per session.
- Spec workflow (b) is a collaborative session with the user — don't pull it
  forward into this one.
- Template additions must stay agent-agnostic and downloader-ready (project
  memory); the ledger move must work for all six runtimes' hooks.
- `ROLLOVER_RELAUNCH=auto` — rollovers auto-launch successors now.

## State snapshot

- Branch `main`, ahead of origin (session-2 commits unpushed); clean except
  `work/kimi-k3-agent-integration/` (another effort — leave alone).
- No running processes, no open agents.

## First actions

1. `scripts/context-budget.sh register --project devex-review` (skip if the
   SessionStart hook already registered — then just add `--project` linkage).
2. Grep the M19 card; scope the ledger move (find every reader/writer of the
   `work/context-decay/` telemetry path — `grep -rn 'context-decay' scripts/
   docs/ skills/ .claude/`), then implement 1–4 above with tests where the
   plumbing changes.
3. Pre-flight before any second package: `record`, check headroom; roll over
   rather than start (c) past ~100K.
