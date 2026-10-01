# 12 — Ledger lint: catch corrupted `handoff.md` ledgers

**What to build:** `scripts/check-ledger.py` already exists (M41, session-management-followups) and checks headings buried in the purpose comment, ordering, and archive continuity; `session-rollover` step 4 already runs it. Ticket 12 is only the gap: (1) reproduce both s16 defects as test fixtures (a block spliced into the purpose comment; a duplicated session block plus two versions of one bridge block) and confirm the checker fails each — extend it if the duplicate is not caught; (2) `skills/checkpoint/SKILL.md` runs it after the ledger write, as rollover does. Source: dogfood findings 2026-09-27 (s16) in `decisions.md`.

**Blocked by:** 11

**Status:** done (2026-09-30, session 17)

**Spec:** findings only (no spec section)

- [x] Fixtures for both s16 shapes; `check-ledger.py` exits non-zero on each (extended if needed), clean ledger exits 0
- [x] `scripts/check-ledger.py` exits 0 over the whole repo
- [x] `skills/checkpoint/SKILL.md` names the check after the ledger write; doc-consistency stays green
