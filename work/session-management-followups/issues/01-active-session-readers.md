# 01 — Move the two `.active-session` readers onto the session record

**What to build:** `scripts/attach-session.sh` (line 73) and
`scripts/statusline-context-budget.sh` (line 42) still resolve a work item's
owner through `work/<p>/.active-session`. Nothing has written that file since
the Stage 4 cutover (37d4100); `scripts/import-session-seq.sh` lists it under
`OLD_FILES` and deletes it. Both scripts therefore see every item as unowned.
Rewrite each to read the record (`work/<p>/session-state.json`) through
`scripts/lib/session-lib.sh`: the owner is the record's `session` block, alive
while its pid is (the liveness rule of ADR-0010). Keep each script's
user-facing output shape; change only where the answer comes from. Correct
the stale example in the comment at `scripts/link-local-work.sh:33`. Update
the prose that describes the two scripts in `docs/context-budget.md`
(grep the script names; do not read the doc whole).

**Blocked by:** nothing.

**Status:** todo

- [ ] Failing test first in `scripts/tests/test-attach-session.sh` and
      `scripts/tests/test-statusline-context-budget.sh`: an item whose record
      names a live pid is owned; a dead pid or no record is not; a stray
      `.active-session` file changes nothing
- [ ] Both scripts green on the new tests; `grep -rn '\.active-session' scripts/`
      hits only `import-session-seq.sh` and its test
- [ ] Doc prose updated; backlog card opened and resolved in the same commit
      (next free ID from the backlog header; archive the card)
- [ ] All suites green; `Decision:` trailer on the commit
