## [gen 1] plan written — 2026-09-18

- Plan file: work/template-improvement-review/plans/phase-4.md (6 tasks, interface with gate order + record write, 11 decisions, empty Evidence).
- Scoping: launcher reads the record once, twelve gates in a fixed order, one session_record_update write; `.session-seq` + bump/identity sidecars kept as a write-only mirror for the unchanged phase-5 supervisor.
- test-session-loop.sh needs a minimal fixture edit (reset() seeds a record; V4 seeds the owner + ledger and asserts session==null) — declared in the plan (task 5, decision 10).
- Dangling `.claude/settings.json` SessionStart entry for the deleted clear-seed hook: handoff item (decision 11).
- Next: rewrite test-launch-next-session.sh + test-emit-mode.sh (red), then the launcher.

## [gen 1] launcher rewritten; two suites green — 2026-09-18

- test-launch-next-session.sh rewritten (193 asserts: e2e slice with the real register, every gate except supervised_stage_only… all twelve codes pinned incl. supervised_stage_only, bootstrap exemption, --clear, worktree/freshness) and test-emit-mode.sh (54 asserts): both green against the new launcher.
- Launcher 1319 -> 512 lines: one record read, gates in order, one session_record_update write, then the write-only mirror for the phase-5 supervisor (.session-seq, bump record, command + sidecar).
- Deleted: --bg + poll, --unstage, .rollover-options/OPT_ARGS, lineage gate on the counter, .active-session/.agent-locks handling, successor-pending handshake, scripts/hooks/rollover-clear-seed.sh, scripts/tests/test-rollover-clear-seed.sh. No seq-sync remedy text left.
- test-session-loop.sh fixture patched (reset seeds the record, V4 owns it + ledger block, V4b asserts session==null); running now.
- Next: full suite run, Evidence, commit.

## [gen 1] full run green; committed — 2026-09-18

- All 20 suites rc=0 (launcher 193, emit 54, session-loop 222, registry/numbering unchanged) + python3 test-check-ledger.py rc=0. Evidence filled in plans/phase-4.md (rc lines, record after the slice, refusals with cmp, deleted list, handoff items).
- Commit 5330f86 on s4-phase-4 (7 files: launcher 1319->512, two suites rewritten, session-loop fixture +34/-, hook + its test deleted, plan). `git status --short` empty. Not merged, not pushed. No work/s4-scratch created.
- Concerns for the parent: (1) `.claude/settings.json` (stage4) still lists the SessionStart entry for the deleted scripts/hooks/rollover-clear-seed.sh — guarded by `[ -x ] || exit 0`, so a silent no-op; the line is the parent's/phase 6-8's to remove. (2) `--clear`'s prompt now sits in launch.pending.prompt with no injector until phase 6's dispatcher. (3) Prose naming --bg/--unstage/.rollover-options/the seed file remains in SKILL.md, docs, ADR-0009, CONTEXT.md (phase 8). (4) test-session-loop.sh got a minimal fixture edit (reset seeds the record; V4 owns it) — declared in the plan.
- Status: DONE_WITH_CONCERNS.
