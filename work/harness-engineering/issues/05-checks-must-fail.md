# 05 — Every new check ships with a test that makes it fail (L62)

**What to build:** the rule against "silent sensors" — a check that has
never failed may be broken. Edits:

- `docs/workspace-structure.md` → "Authoring a Team Capability": a new
  check (script, hook, lint) ships with a suite under `scripts/tests/`
  that feeds it bad input and asserts it fails, with the reason line.
- Ticket 01's `run-checks.sh` docs say the same.
- Audit: for each `scripts/check-*` and `plan.sh check`, name the suite
  that makes it fail. Any without one → write the missing failing case
  (small) or file a card (large).

**Blocked by:** 01.

**Status:** done

- [x] Rule written in both places
- [x] Audit table in the ticket: check → suite that makes it fail
- [x] Missing cases written or carded
- [x] Backlog card resolved in the same commit: badge → Resolved, `Fixed:`
      line with the commit, card moved to the matching section of
      `docs/template-workspace-backlog-archive.html`, scorecard and "Last
      updated" changed, change-log row added
- [x] All `scripts/tests/test-*` suites green (after ticket 01:
      `scripts/run-checks.sh` exits 0); `scripts/check-workspace-structure.sh` exit 0
- [x] One commit, `Fix <ID>: …`, with a `Decision:` trailer

**Done (2026-10-08, session 3).** Rule in `docs/workspace-structure.md` →
"Authoring a Team Capability"; the `run-checks.sh` entry there and the
script header point to it.

| Check | Suite that makes it fail |
|---|---|
| `scripts/check-dependencies.sh` | `scripts/tests/test-check-dependencies.sh` |
| `scripts/check-drift.sh` | `scripts/tests/test-check-drift.sh` |
| `scripts/check-ledger.py` | `scripts/tests/test-check-ledger.py` |
| `scripts/check-repo-context.sh` | `scripts/tests/test-check-repo-context.sh` (new: warn-only, so asserts `Status: repo-context=degraded`) |
| `scripts/check-service-access.sh` | `scripts/tests/test-check-service-access.sh` (new: stub `gh` not authenticated → exit 1) |
| `scripts/check-workspace-structure.sh` | `scripts/tests/test-check-workspace-structure.sh` (new: missing dir, broken symlink, non-executable script → exit 1). `test-context-prefix-stability.sh` covered only its date-line *warning* |
| `plan.sh check` | `scripts/tests/test-plan.sh` T11 |

All three gaps were small, so no card was filed.
