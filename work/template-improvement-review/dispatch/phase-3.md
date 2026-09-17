
## [gen 1] plan written — 

- Plan file: work/template-improvement-review/plans/phase-3.md (tasks, interface, 10 decisions, empty Evidence).
- Key scoping: registry record stays (findings concept 1); `.active-session`, roles, superseded stamps, child locks, successor-pending handshake go; `record`/`watch`/`supervised` kept.
- Callers of deleted verbs found: launch-next-session.sh:315 (`--unstage` seq-sync), test-session-loop.sh V4/V5 (real seq-sync + rollover-complete). Docs/skills prose left for phase 8.
- Next: rewrite the two suites (red), then implement.

## [gen 1] suites red then green; deletions done — 2026-09-17T20:03:03Z

- Registry suite rewritten (187 asserts) and numbering suite rewritten (18 asserts): red against stage4 measurer (100/87, 4/14), green after the splice.
- Measurer: 1265 -> 1017 lines; register/release/close on the record via session_record_update; jq_missing exit 4; retired verbs refuse with a pointer.
- Deleted: rollover-prep.sh, capture-rollover-options.sh, test-seq-sync.sh, test-rollover-prep.sh, test-rollover-sentinel.sh. Launcher --unstage rewinds the counter directly; test-session-loop V4 dropped its verb steps, V5 deleted.
- Next: full suite run (background), Evidence, commit.

## [gen 1] full run green; committed — 2026-09-17T20:19:52Z

- All 21 suites rc=0 (registry 187, numbering 18, session-loop 221, launcher 329 asserts). Evidence filled in plans/phase-3.md with the record contents for register-on-open-launch, non-owner release (cmp), close refusals, --check, jq_missing.
- Commit d4fb3b6 on s4-phase-3 (11 files: measurer 1265->1017, launcher --unstage, 3 suites rewritten/edited, 5 files deleted, plan file). `git status --short` empty; `git log stage4..s4-phase-3` = that one commit. Not merged, not pushed.
- Open items for other phases (prose only, no invocations): launcher remedy messages naming seq-sync (lines 323/582/1217, pinned by T23i4/E8d, phase 4); session-rollover SKILL.md and mcp-fragments/README.md prose, .gitignore entries (phase 8); child locks no longer written by register (fleet, phase 7).
- Status: DONE.
