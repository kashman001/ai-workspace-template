# 04 — One map of the workspace's guides and checks (L61)

**What to build:** a section in `docs/workspace-structure.md` (not a new
doc unless it's long; if new, index it in `docs/README.md`): one table
of every control — guides (`CONTEXT.md`, skills, gotchas, ADRs,
`decisions.md`) and checks (each `check-*` script, suite group,
`plan.sh check`, the context-budget hooks, `check-ledger.py`, ticket
02's sweep, ticket 01's runner). Columns: what it guards · guide or check
· script or judgement · when it runs (hook / pre-commit / CI / checkpoint /
by hand). Plain words, not the article's jargon; one sentence linking the
framing to `work/harness-engineering/source-notes.md` is enough.

Then read the table for gaps (a guide with no check, a check nobody runs)
and file real ones as backlog cards; don't fix them here.

Last on purpose: it describes what 01–03 built.

**Blocked by:** 01, 02, 03.

**Status:** todo

- [ ] Table written from `ls scripts`, `ls skills`, the hook config files
      — not from memory
- [ ] Gaps it shows listed in the ticket; real ones filed as cards
- [ ] Backlog card resolved in the same commit: badge → Resolved, `Fixed:`
      line with the commit, card moved to the matching section of
      `docs/template-workspace-backlog-archive.html`, scorecard and "Last
      updated" changed, change-log row added
- [ ] All `scripts/tests/test-*` suites green (after ticket 01:
      `scripts/run-checks.sh` exits 0); `scripts/check-workspace-structure.sh` exit 0
- [ ] One commit, `Fix <ID>: …`, with a `Decision:` trailer
