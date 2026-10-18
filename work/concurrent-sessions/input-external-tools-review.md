# Input from external-tools-review — "workers own nothing" (R1)

Cross-link note, not research. Read it when writing `research.md` here.
Source: `work/external-tools-review/research/t3-projects.md` §3 item 2 and
`synthesis.md` R1 (accepted by the user 2026-10-18).

## The outside design

Claude Code's redesigned Projects answers this item's question one way: only
the coordinator owns the work. Each thread is a full session with its own
context window, but it keeps no ledger of its own. It does one piece of work
on its own branch and reports back; the coordinator "sees what threads report
back, not every step they take". Overlapping edits surface as ordinary merge
conflicts.

## What it suggests here

A cheap path that may make multi-owner machinery unnecessary: keep **one
owner** per work item, and promote long-running children to separate
worktree sessions that report through dispatch records
(`docs/context-budget.md` → "Dispatching long-running children") instead of
co-owning `seq` / the ledger. Weigh it in `research.md` as a candidate answer
alongside true multi-owner designs.

## Related accepted work

- Backlog **L95** — dispatch-contract hardening (read-first list,
  `Remember:` section, WIP commits, proved DONE). Makes "helpers report back"
  sturdier whichever way this item decides.
- Backlog **L97** — a single "needs me" view; worth building only if this
  item's answer brings more parallel workers.
