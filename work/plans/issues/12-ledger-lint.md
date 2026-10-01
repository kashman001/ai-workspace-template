# 12 — Ledger lint: catch corrupted `handoff.md` ledgers

**What to build:** `scripts/check-ledger.sh <work/item/handoff.md>` exits non-zero when the PURPOSE header comment is not intact, a `# Session Handoff` header line repeats, or the first block header does not follow the closing `-->`. The checkpoint and session-rollover skills run it after writing the ledger. Source: dogfood findings 2026-09-27 (s16) in `decisions.md`.

**Blocked by:** 11

**Status:** ready-for-agent

**Spec:** findings only (no spec section)

- [ ] Script plus tests (a suite under `scripts/tests/`), covering the three failure shapes and a clean ledger
- [ ] Every `work/*/handoff.md` in the repo passes, or the failures are fixed
- [ ] `skills/checkpoint/SKILL.md` and `skills/session-rollover/SKILL.md` name the check after the ledger write; doc-consistency stays green
