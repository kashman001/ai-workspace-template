# 03 — Phase 2: move the fleet verbs out of the measurer (pure move)

**What to build:** the sub-agent fleet verbs (`children`, `dispatch-contract`, `dispatch-open`, `dispatch-close`, `dispatch-list`) move from the measurer into their own script with no behaviour change. Their three test suites are renamed and re-pointed at the new script. This shrinks the measurer by roughly 400 lines before anyone edits it.

Hazard: the implementing session's own hooks call the measurer every turn, so a half-edited measurer silently loses that session its measurement. Commit only from green.

**Blocked by:** 01 (Phase 0).

**Status:** ready-for-agent

- [ ] The three fleet suites pass unchanged in substance against the new script path
- [ ] The measurer no longer contains the fleet verbs; calling one through the measurer fails clearly
- [ ] No behaviour change: same exit codes, same outputs, same files written
- [ ] All existing suites green
