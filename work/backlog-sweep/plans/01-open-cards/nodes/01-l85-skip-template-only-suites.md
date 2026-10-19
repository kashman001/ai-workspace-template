---
id: 01-l85-skip-template-only-suites
title: L85 — template-only suites exit 77 when their file is absent
status: done
kind: work
wave: 1
blocked_by: []
tier: cheap
loop: 2
check: for t in test-probe-twins test-template-version test-template-instantiation test-doc-consistency; do bash "$WORKSPACE_ROOT/scripts/tests/$t.sh" >/dev/null 2>&1 || exit 1; done
sessions: [3]
isolated: yes
---

## Goal
Card: `docs/template-workspace-backlog.html` → L85 (grep the ID; read only that card). Do not edit the backlog files — the reconcile node moves cards.
Each of `scripts/tests/test-probe-twins.sh`, `test-template-version.sh` (V2a/V3a/V3b), `test-template-instantiation.sh` (T1c) and `test-doc-consistency.sh` (only the template-`work/` path pins) exits 77 with one `SKIP: <reason>` line when the template-only file it reads is absent. Test-first: make an instance-like copy (e.g. `git worktree` or `cp -R` to the scratchpad, delete the template-only files) and see each suite red there before the change.

## Acceptance
- [x] each suite red in the instance copy before the change (output quoted in Log)
- [x] each suite exits 77 with a reason in the instance copy after
- [x] all four pass in the template (node check)

## Log
- s3 · started, tier cheap
- s3-a · red in instance copy /private/tmp/claude-501/-Users-kashif-Developer-experiments-ai-workspace-template/ad33dd8a-d2e7-4b29-9426-f73ae445b268/scratchpad/instance (template-only paths removed, backlog pair pruned): test-template-version rc=1 "FAIL: V2a: docs/template-usage.md does not name TEMPLATE_VERSION", "passed=6 failed=3"; test-doc-consistency rc=1 "FAIL: paths: named in docs/plans.md, not on disk: work/plans/concept.md work/plans/spec.md", "passed=16 failed=1"; test-template-instantiation rc=1 "FAIL: T1c: prune reminder while backlog pair present (L36) (no [template-usage.md §5] in ...)", "passed=27 failed=1"; test-probe-twins rc=1 "scripts/tests/test-probe-twins.sh: line 117: probe_assert_eq: command not found" (probes dir absent). Logs in the scratchpad red-*.log.
- s3-a · on disk: scripts/tests/test-probe-twins.sh (exit 77 SKIP guard on work/template-improvement-review/evaluation/probes), test-template-version.sh and test-template-instantiation.sh (exit 77 SKIP guard on docs/template-usage.md), test-doc-consistency.sh (work/plans/ pins skipped with a "skip:" line when work/plans/ absent). Instance copy after: probe-twins rc=77 "SKIP: template-only probes absent (...)"; template-version and instantiation rc=77 "SKIP: template-only docs/template-usage.md absent"; doc-consistency rc=1, the work/plans pins now skipped, but it still FAILs on CONTEXT.md naming docs/template-workspace-backlog*.html (not work/plans; not changed here).
- s3-a · template node check passes: rc=0 for all four (template-version passed=9, instantiation passed=28, probe-twins 37 passed, doc-consistency passed=17). Backlog HTML untouched.
- s3-a · final: on disk = the four suite edits (committed on this branch). Not on disk = acceptance line 2 for test-doc-consistency: it does not exit 77 (card says skip only the work/plans pins, so it runs on and exits 0 only if the CONTEXT.md backlog pins are also handled, which is out of this node's scope). Acceptance 2 left unticked for the orchestrator to decide.
- s3 · orchestrator re-ran in a git-archive instance copy (probes dir, docs/template-usage.md, work/plans removed; backlog pair kept, as real instances keep CONTEXT.md's pointer): probe-twins/template-version/instantiation rc=77 with SKIP reason; doc-consistency rc=0 (17/0) skipping only the work/plans pins — the card's stated fix for that suite (Acceptance box 2 over-read it as 77). Box 2 ticked on that reading.
- s3 · node check failed under plan.sh verify: test-probe-twins T3d/T3e red with WORKSPACE_ROOT exported (pre-existing leak; the hooks honour it). Fixed: scripts/tests/test-probe-twins.sh unsets WORKSPACE_ROOT; red→37/0 with it exported; plan.sh verify passes.
- s3 · check passed → done
