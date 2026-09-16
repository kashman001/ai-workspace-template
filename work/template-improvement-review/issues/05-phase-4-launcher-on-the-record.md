# 05 — Phase 4: launcher on the record, and the first end-to-end slice

**What to build:** the launcher checks both files (launcher and ledger) itself, then in one atomic write advances `seq`, copies the outgoing owner into `launch.predecessor`, empties `session`, and writes `staged` (or `launch.pending` for an in-place restart). Every gate is implemented, with codes `not_owner`, `owner_live`, `chain_closed`, `supervised_stage_only`, `ledger_seq_mismatch`, `ledger_shape`, `launcher_unchanged`, `launcher_stale`, `worktree_unsynced`, `runtime_path_unsupported`, `no_supervisor`, `schema_mismatch`.

Deleted: `--bg` and its confirmation poll, `--unstage`, the options replay file, the snapshot files, the clear-seed hook with its seed file (the prompt now travels in `launch.pending.prompt`), and the tests that pin them.

This is the first end-to-end slice: an attended rollover on a stub runtime with no supervisor.

**Blocked by:** 04 (Phase 3).

**Status:** ready-for-agent

- [ ] End-to-end on a stub runtime: register, write the two files, `--check`, launch with `--emit`; then `seq` is +1, `launch.predecessor.disposition=rolled_over`, `staged.by` is the caller's session id, `session` is null
- [ ] A stub successor registers with the two environment variables and fills `session`
- [ ] Every launcher gate except `supervised_stage_only` has a test that pins exit code and reason code only
- [ ] The listed flags, files, hook and tests are gone; the ignore file no longer lists the seed file
- [ ] Rewritten launcher suite green; all suites green
