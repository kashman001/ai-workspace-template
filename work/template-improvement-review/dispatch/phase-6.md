
## [gen 1] plan written — 2026-09-18T06:59:44Z

- Plan file: work/template-improvement-review/plans/phase-6.md (5 tasks, interface = adapter table with 10 columns + dispatcher CLI + shim map, 9 decisions, empty Evidence).
- Key calls: table is a data file (context-budget-adapters.conf); copilot-vscode and opencode keep rows + shims (shipped wiring names the paths); stop-hook folds in, hook lib stays (test-link-local-work.sh sources it); jq_missing to stderr + silent envelope + exit 0; fixtures are committed outputs captured from the 0a117c6 wrappers.
- Constraint found: every vendor config (.claude/settings.json, .codex/config.toml, .gemini/settings.json, .github/hooks/*.json, .opencode/plugins/context-budget.js) names a wrapper path; all seven become exec shims, no config edit required.
- Next: capture fixtures from the 0a117c6 wrappers, add F/J cases (red), build the table + dispatcher.

## [gen 1] dispatcher green; full run — 2026-09-18T07:07:18Z

- 47 fixtures captured from the 0a117c6 wrappers (git show into a scratch tree, run through the suite's own F harness), committed under scripts/tests/fixtures/vendor-hooks/. J (jq_missing before parsing) red against the old wrappers, as intended.
- Built scripts/hooks/context-budget-adapters.conf (6 rows, 10 columns) + scripts/hooks/context-budget-hook.sh; the six wrappers + stop-hook are exec shims; lib unchanged bar its header. Vendor suite 150/150 (was 108 asserts): F byte-identical for every runtime/event/status, J green. One deliberate match: an unknown event stays silent like the wrappers.
- Every suite rc=0 except test-session-lib.sh S8a/S8c (concurrent writers, rc=4 at 0 / seq 59 vs 60): reproduces on a clean 0a117c6 extract, so pre-existing / load-sensitive, not this phase's. Rerunning once. test-check-ledger.py rc=0.
- Next: Evidence, commit.

## [gen 1] committed — 2026-09-18T07:08:04Z

- test-session-lib.sh rerun rc=0 (S8 lock-timeout flake under fleet load; identical failure on a clean 0a117c6 extract).
- Evidence filled in plans/phase-6.md. Commit 67dc8a9 on s4-phase-6 (59 files: 2 added scripts, 7 shims, lib header, suite +120 lines, 47 fixtures, plan). Tree clean. Not merged, not pushed. No scratch item used.
- Open items for other phases: vendor configs may later point at context-budget-hook.sh directly and the shims go (optional, decision 8); docs prose on per-vendor wrappers (phase 8).
- Status: DONE.
