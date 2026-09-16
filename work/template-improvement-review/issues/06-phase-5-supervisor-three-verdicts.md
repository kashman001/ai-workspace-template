# 06 — Phase 5: supervisor with three verdicts, stub-child suite

**What to build:** first, one commit that wraps the existing supervisor in `main "$@"` with no other change, so later edits are safe while an old copy runs. Then the body: check the chain budget, stage through the launcher if nothing is staged, export the session number, record the child in `chain`, run it, and reach a verdict: `staged`, `quit_stop`, `quit_plain` or `cap`; otherwise broken with `rc_nonzero`, `logout`, `staged_invalid leg=<which>`, `no_own_measurement`, `record_unreadable`, `schema_mismatch` or `stall`. Start refusals: `record_unreadable`, `schema_mismatch`, `chain_closed`, `supervisor_live`, `relaunch_off`. The stall guard watches the three markdown files, not the record.

Deleted: the sentinel, the flush-hash check, the `.session-loop` state files.

**Blocked by:** 05 (Phase 4).

**Status:** ready-for-agent

- [ ] The `main "$@"` wrapper lands as its own commit with the suite green and no behaviour change
- [ ] Stub child that rolls over: verdict `staged`; stub child that exits 0 unstaged: `quit_plain`
- [ ] Restart with an already-spent stage refuses; a hand stage without a supervisor refuses
- [ ] Every verdict and refusal above has a stub-child test pinning exit code and reason code only
- [ ] The sentinel, flush-hash check and state files are gone; all suites green
