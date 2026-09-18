
## [gen 1] plan written (2026-09-18)

- Read: ticket 06, fleet-plan contract, phase-4 Interface/Decisions, phase-3 register binding, stage3-design-v2 record table + verdict flowchart + gate rows, findings Phase 5 paragraph, session-lib.sh, the old session-loop.sh (1002 lines), launcher, measurer `supervised`, the hook lib's turn-end predicate.
- Plan at `work/template-improvement-review/plans/phase-5.md` (worktree): tasks, interface (start gates, per-iteration verdict), 9 decisions with rejected alternatives, empty Evidence.
- Two conflicts found and recorded as decisions 1–2 (will return DONE_WITH_CONCERNS): `context-budget.sh supervised` reads only the `.session-loop` marker, and `scripts/hooks/context-budget-hook-lib.sh` `budget_hook_should_exit` reads `.next-command` + `.session-seq.bump.json` (both files I may not edit). So the marker, `.next-command` and the bump record keep being written; only `.session-seq` and the emit `.json` sidecar are deleted.
- Next: baseline suites (running), then the `main "$@"` wrapper commit.

## [gen 1] wrapper committed

- Baseline: test-session-loop.sh rc=0 (222/222), test-session-loop-notify.sh rc=0. After wrapping in `main "$@"` (3 inserted lines, nothing else): both rc=0 again.
- Commits on s4-phase-5: 1966929 (plan), then the wrapper commit.
- Next: the stub-child suite (red), then the supervisor body.

## [gen 1] suite written, body done

- `scripts/tests/test-session-loop.sh` rewritten (1747 -> ~330 lines): stub children on a throwaway git workspace; the stage-* stubs run the REAL launcher `--emit`; cases V1–V4 (staged/quit_plain/quit_stop/cap), B1–B7 (rc_nonzero, logout ×3, no_own_measurement ×2, staged_invalid legs seq/predecessor/by/staged/lifetime, record_unreadable, schema_mismatch, stall + interactive), R1–R8 (record_unreadable, schema_mismatch, chain_closed + --reopen, supervisor_live + stale block, relaunch_off + override, spent stage, no_supervisor from a TF_SESSION_LOOP child, relayed launcher refusal), C1–C2 (--reset-cap), F1 (fresh item bootstrap), A1–A4 (watchdog).
- `scripts/session-loop.sh` rewritten (1002 -> ~380 lines) on the record; bash 3.2 trap found and worked around: a literal `(` before `$(… "?" …)` inside double quotes fails to parse.
- Launcher: `.session-seq` counter mirror and the emit `.json` sidecar deleted with their pins; `.next-command` and the bump record stay (hook lib reads them).
- Next: run every suite.

## [gen 1] suites green, branch committed — DONE_WITH_CONCERNS

- All 20 `scripts/tests/*.sh` rc=0 with bash, `python3 scripts/tests/test-check-ledger.py` rc=0. test-session-loop.sh 105/105 (394 lines, was 1747; no flake in five runs); test-launch-next-session.sh 190/190; test-emit-mode.sh 53/53; test-session-lib.sh 55/55 (S8 did not flake).
- Commits on s4-phase-5 (clean tree): 1966929 plan; f771dd4 `main "$@"` wrapper (old suite 222/222 before and after); 4299159 supervisor body + stub-child suite; bbd31e6 launcher `.session-seq` mirror + emit sidecar deleted with pins; plan evidence/concerns (amended, HEAD).
- Concerns (plan decisions 1–2, "Concerns for the parent"): (1) `.session-loop` marker still written — `context-budget.sh supervised` and the launcher's bootstrap exemption read it; (2) `.next-command` + `.session-seq.bump.json` still written by the launcher — `scripts/hooks/context-budget-hook-lib.sh` `budget_hook_should_exit` reads them for the turn-end self-kill; phase 6/8 should move it to `staged.by`. (3) launcher's legacy `.chain-closed` read kept (old supervisor on main may still write it); stale `.gitignore` lines left.
- Decision on the `--clear` prompt: not the supervisor's (decision 4); phase 7/8 own any injector.
- Not merged, not pushed.
