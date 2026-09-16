# 04 — Phase 3: measurer verbs on the record (register, release, close, --check)

**What to build:** the measurer writes the per-item record instead of its old side files. `register` fills the `session` block and binds to an open launch (via the two environment variables or a matching `pending` pid). `release` merges into `ended` only if the record still names the caller. `close` is the stop door and runs the ledger checks inline. `--check` is the dry run. Reason codes: `not_owner`, `owner_live`, `adopted`, `jq_missing`, `ledger_seq_mismatch`, `ledger_shape`.

Deleted: `seq-sync`, `opts-sync`, `rollover-complete`, the rollover prep script, the options capture script, and their tests. The registry and session-numbering suites are rewritten against the record. The fate of `record`, `watch` and `supervised` as verbs is decided in this phase's plan file.

**Blocked by:** 02 (Phase 1), 03 (Phase 2).

**Status:** ready-for-agent

- [ ] `register` fills `session`; a stub successor registering against an open launch binds to it
- [ ] `release` by a non-owner changes nothing in the record
- [ ] `close` exits 4 with `reason=ledger_seq_mismatch` on a wrong ledger block; `ledger_shape` on a malformed one
- [ ] The listed verbs, scripts and tests are gone; nothing in the repo still calls them
- [ ] Rewritten registry and numbering suites green; all suites green
