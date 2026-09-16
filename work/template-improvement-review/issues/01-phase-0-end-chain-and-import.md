# 01 — Phase 0: end the live chain, flip relaunch default, script the counter import

**What to build:** the preconditions for touching any session script. The live supervisor chain on this work item is ended at its interactive pause (session 10 quits with nothing staged). The root relaunch default becomes `manual`, while a committed per-item env keeps this work item on `auto`. `jq` is pinned as a hard requirement by a test. The supervisor notify path in the root env no longer depends on a `ROOT` variable that differs per caller. A one-time import script copies the old `.session-seq` counter into the new record's `seq` block, and is tested against a throwaway work item.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] No supervisor process is running `session-loop.sh` for any work item; the tracker and ledger record when and how the chain ended
- [ ] Root `ROLLOVER_RELAUNCH` is `manual`; `work/template-improvement-review/context-budget.env` overrides it to `auto`; both committed together
- [ ] A test in the existing suites fails if the dependency check stops requiring `jq`
- [ ] `SESSION_LOOP_NOTIFY` resolves to the same path from every caller (no `ROOT` dependency)
- [ ] Import script: record `seq` equals the old counter's value; running it twice changes nothing; no old counter present is a clean exit with a reason
- [ ] `plans/phase-0.md` written; all `scripts/tests/*.sh` green at every commit
