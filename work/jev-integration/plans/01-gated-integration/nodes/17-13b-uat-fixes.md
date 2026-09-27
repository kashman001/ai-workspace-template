---
id: 17-13b-uat-fixes
title: UAT findings: jev.sh --help rewrite + rlm skill python3
status: todo
kind: work
wave: 6
blocked_by: [13-uat-gated]
tier: standard
check: bash "$WORKSPACE_ROOT/scripts/tests/test-jev.sh" >/dev/null && ! grep -q "^python skills" "$WORKSPACE_ROOT/skills/rlm/SKILL.md" && [ "$("$WORKSPACE_ROOT/scripts/jev.sh" --help | awk "length > 80" | wc -l)" -eq 0 ]
sessions: []
---

## Goal

Fix the two findings the user raised while running node 13's UAT (session 12).

1. `scripts/jev.sh --help` is not user-friendly. A CLI text-UX review (session
   12) ranked the issues: one-line JSON examples wrapping 3-4 times at 80
   columns; no actionable synopsis; exit codes and key resolution buried in a
   closing prose block; flags below the examples; "key" overloaded (question
   key vs API key). The reviewer's full replacement text is at
   `work/jev-integration/uat-help-proposal.txt` (100 lines, all <= 80 cols,
   examples byte-identical to the current ones through `jq -c`). Paste it into
   the quoted heredoc in `scripts/jev.sh` (`cat <<'USAGE'`), changing wording
   only where a fact is wrong. T19 (`--help`) may need its asserted substrings
   updated to the new text: update the assertion, never weaken it.
2. `skills/rlm/SKILL.md` says `python ...` in five places; a stock Mac has only
   `python3` (the script's shebang). Change the five to `python3`. Touch
   nothing else in the rlm skill.

Constraints: `--check`/`--help` remain the only flags; CLI contract unchanged;
`classify()` and `llm_query` untouched (T14 golden diff must still pass).

Ordering note (session 12): `plan.sh check` flags that reconcile 14 is no
longer last in wave 6 because this node's id sorts after it. Resolve per the
plans skill before running it (e.g. the wave-6 reconcile replans it into the
next wave, or the reconcile is re-added last); do not hand-edit ids.

## Acceptance

- [ ] `scripts/jev.sh --help` prints the reviewed text: every line <= 80
      columns; sections USAGE, REQUEST, ANSWER, QUESTION TYPES, EXAMPLES, KEY,
      ENVIRONMENT, LIMITS, EXIT STATUS, SEE ALSO in that order
- [ ] The three examples in `--help` still run as shown (`printf ... | scripts/jev.sh`)
      against the test stub (T15-T17 cover the shapes); no example wording changed
- [ ] `skills/rlm/SKILL.md` has no `python skills/rlm/...` invocation left
- [ ] `scripts/tests/test-jev.sh` passes in full

## Log
