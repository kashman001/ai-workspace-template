---
id: 01-l85-skip-template-only-suites
title: L85 — template-only suites exit 77 when their file is absent
status: todo
kind: work
wave: 1
blocked_by: []
tier: cheap
loop: 2
check: for t in test-probe-twins test-template-version test-template-instantiation test-doc-consistency; do bash "$WORKSPACE_ROOT/scripts/tests/$t.sh" >/dev/null 2>&1 || exit 1; done
sessions: []
isolated: yes
---

## Goal
Card: `docs/template-workspace-backlog.html` → L85 (grep the ID; read only that card). Do not edit the backlog files — the reconcile node moves cards.
Each of `scripts/tests/test-probe-twins.sh`, `test-template-version.sh` (V2a/V3a/V3b), `test-template-instantiation.sh` (T1c) and `test-doc-consistency.sh` (only the template-`work/` path pins) exits 77 with one `SKIP: <reason>` line when the template-only file it reads is absent. Test-first: make an instance-like copy (e.g. `git worktree` or `cp -R` to the scratchpad, delete the template-only files) and see each suite red there before the change.

## Acceptance
- [ ] each suite red in the instance copy before the change (output quoted in Log)
- [ ] each suite exits 77 with a reason in the instance copy after
- [ ] all four pass in the template (node check)

## Log
