<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 18 (2026-10-08): L63, L64, L65 fixed; L54 release bump done

**What got done (on main, one commit per card):**
- L63 `18c922f` — two removed scripts dropped from the `scripts/` tree in
  `docs/workspace-structure.md`; `check-workspace-structure.sh` now fails
  on a tree entry missing on disk (test case W5).
- L64 `e5af815` — new `scripts/check-plans.sh` runs `plan.sh check` on
  every committed plan; fast tier of `run-checks.sh`; suite
  `test-check-plans.sh`.
- L65 `ce44234` — case E5 in `test-agent-entrypoints.sh`: every
  `skills/*/SKILL.md` has `name`/`description` frontmatter (E5a fixture
  shows it fails).
- L54 `125fb37` — `TEMPLATE_VERSION` → `2026-10-08`.
- Backlog: no open cards; scorecard 0/114/5/0/6. Guide HTML regenerated.

**Verification:** `scripts/run-checks.sh` 40 passed, 0 failed, 0 skipped
(before the bump); `test-template-version.sh` passes after it;
`check-drift.sh` exit 0 (one old ADR-history WARN, not new).

**For the user:**
- Main is 25 commits ahead of origin; not pushed. Push, then check the
  first CI run; if CI fails, fix it without changing the date.

# Session Handoff — 17 (2026-10-08): doc-gap cards L53, L55–L59 resolved; L54 left for the maintainer

**What got done (on main, one commit per card):**
- L53 `48cef9f` — `docs/context-budget.md` output line gains `cache=`.
- L55 `18f2021` — `docs/workspace-structure.md` "What CONTEXT.md Should
  Contain" gains a Size-and-stability bullet (Z0 budget, no dates).
- L56 `08c330c` — stale `CONTEXT.md` → "Tool & Context Loading" pointers:
  repointed in workspace-structure; dropped in mcp-setup (self-pointer).
- L57 `e562940` — `**Retired:**` notes explained in
  work-directory-conventions and for-non-engineers.
- L58 `d557d56` — ledger-splice gotcha notes `rollover-prep.sh` removal;
  `Last confirmed` → 2026-10-08.
- L59 `f3445b5` — ADR-0009 amendment names the `relaunch_off` gate and
  test R5 instead of the never-committed `docs/session-chain-scenarios.md`.
- Each card archived; scorecard now 6/105/5/0/6.

**Verification:** all 27 `scripts/tests/test-*` suites pass;
`scripts/check-workspace-structure.sh` passes; no operational-knowledge
entries past the 6-month review age.

**For the user:**
- **L54 still open, your call:** when to cut a release and bump
  `TEMPLATE_VERSION` (still `2026-09-30`).
- Main is ahead of origin; not pushed.
- `work/harness-engineering/issues/01-run-checks.md` has an uncommitted
  edit from the other session; left untouched.
