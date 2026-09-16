# 09 — Phase 8: skill, docs, ADRs, ignore file, env defaults, doc-consistency test

**What to build:** the `session-rollover` skill is rewritten to the new verbs. The context-budget doc's sections on relaunch knobs, the supervisor, chain signals, the multi-session model, sweeps and dispatch (now fleet), adapters, registration and ledger are rewritten in the design's vocabulary. The ignore file adds the record and drops entries for files that no longer exist. The three change-log entries still saying "Open" in prose are closed. The design's settled points are promoted from decision notes to ADRs; the session-counter ADRs are superseded by the record; the `/clear` open item in the relaunch ADR closes on the Stage 2 probe evidence. The exact ADR set is decided in this phase's plan file. A doc-consistency test pins the doc to the scripts.

**Blocked by:** 02, 03, 04, 05, 06, 07, 08 (Phases 1–7; this phase is last).

**Status:** ready-for-agent

- [ ] Doc-consistency test: every verb and reason code named in the doc exists in the scripts, and every one in the scripts is named in the doc
- [ ] The `session-rollover` skill uses only verbs and codes that exist
- [ ] ADRs: settled points promoted; counter ADRs marked superseded; relaunch ADR's `/clear` item closed with the probe reference
- [ ] Ignore file lists the record and nothing that no longer exists
- [ ] Root env defaults match the design; all suites green
