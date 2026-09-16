# 10 — Cutover: import, attended rollover, two-session chain on this work item

**What to build:** `template-improvement-review` moves from the old scripts to the new ones. With phases 0–8 merged: run the phase 0 import on this item so the record's `seq` equals the old counter at that moment. The next rollover of this item is attended (no supervisor): the agent writes the two files and runs the new launcher, then confirms the successor registered against the open launch. Then start the new supervisor on this item with `--max-sessions 2`. Only then is the item supervised again. A follow-up commit retires the import script and the old counter's ignore entries once every live item has been imported.

**Blocked by:** 09 (Phase 8).

**Status:** ready-for-agent

- [ ] Import on this item: record `seq` equals the old counter; a second run is a no-op
- [ ] Attended rollover passes the phase 4 field assertions; the successor's `session` block names it and binds to the launch
- [ ] Supervised chain with `--max-sessions 2`: verdict `staged` once, then `quit_plain` or `cap`
- [ ] Import script and old counter ignore entries retired in a follow-up commit
- [ ] Tracker: every phase row `done` with commit; ledger records the cutover evidence
