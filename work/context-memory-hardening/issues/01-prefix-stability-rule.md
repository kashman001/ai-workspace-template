# 01 — Prefix-stability rule for always-loaded context (L49)

**What to build:** a short "Cache the prefix, vary the tail" section in
`docs/context-budget.md`, plus a one-line pointer from `CONTEXT.md` → "Tool
& Context Loading". The rule: always-loaded files (`CONTEXT.md`, the
`MEMORY.md` index) hold no dates, status, counters, or session-specific text.
Volatile state belongs only in launchers and ledgers, which are read as the
tail. Hooks that inject text print byte-stable output.

Then audit what each runtime's SessionStart-type hook prints into context.
Claude's `register` hook currently emits a status line that includes a
per-session `artifact=` path and `pct=`. Find out whether that text reaches
the model's context, and if it does, whether it sits in the cached prefix.
Make it stable or quiet where it does. Record the finding either way. As an
optional extra, add a `check-workspace-structure.sh` rule that flags
date-like lines (`20[0-9][0-9]-[01][0-9]-`) in `CONTEXT.md`. Leave it out if
legitimate content trips it; the "Last updated" strings in other docs are
not in scope.

Background: `work/context-memory-eval/eval.md` → C2, recommendation 1. Use
targeted reads only; don't load `docs/context-budget.md` whole.

**Blocked by:** nothing.

**Status:** todo

- [ ] Section added to `docs/context-budget.md`; pointer in `CONTEXT.md`
      (edit `CONTEXT.md`, never a symlink)
- [ ] Hook-output audit result written in this ticket under `## Answer`
      (per runtime: what is printed, whether it lands in context, what changed)
- [ ] If a structure-check rule is added: a failing test first, then green
- [ ] Backlog card resolved in the same commit: badge → Resolved, `Fixed:`
      line with the commit, card moved to the matching section of
      `docs/template-workspace-backlog-archive.html`, scorecard and "Last
      updated" changed, change-log row added
- [ ] All `scripts/tests/test-*` suites green; `scripts/check-workspace-structure.sh` exit 0
- [ ] One commit, `Fix <ID>: …`, with a `Decision:` trailer
