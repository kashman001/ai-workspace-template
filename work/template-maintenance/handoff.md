<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 19 (2026-10-08): CI Linux failures fixed in all three suites

**What got done (on main, one commit per suite):**
- `57bac67` test-plan.sh — `sed -i ''` (BSD-only; a silent no-op on GNU)
  replaced by a temp-file `sedi()` helper, 14 call sites.
- `e5a4e2f` test-session-loop.sh — `scripts/session-loop.sh` `mtime_of()`
  used spaced `stat -f %m`, which on GNU prints fs info *and* falls through,
  so transcript age was junk (A2a/b, A3b). Now `stat -f%m`. The suite's
  3 `sed -i ''` edits moved to `sedi()`.
- `8ef3510` test-context-budget-registry.sh — R6d/R6f passed only inside a
  Claude session (aaa got a live claude pid); `--takeover` makes the setup
  host-independent. Also a spaced `stat -f %m` fingerprint (latent flake).
- `5980d02` docs/operational-knowledge.md — new entry "Shell scripts and
  tests — BSD-only idioms pass on macOS and break on Linux CI" (with the
  runner-faithful docker repro: needs `USER` and `LANG=C.UTF-8`).

**Verification:** Ubuntu 24.04 container (USER=runner, LANG=C.UTF-8):
the three suites 252/144/198 pass; full `run-checks.sh` 38/2 — the two are
check-dependencies / check-service-access (no `gh`/token in the container;
they pass on the runner). macOS `run-checks.sh` 40/0/0 twice; one earlier
macOS run had 1 failure, not captured — an unidentified flake.

**Not done:** push (user's call); CI confirmation on GitHub. `main` is 11
ahead of origin (includes another work item's commits). No `TEMPLATE_VERSION`
change, per instruction. No backlog card.

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

**After the stop door (user asked):** pushed `main` (`c3f2e2b..40f4389`).
First-ever `checks` CI run (37884567606, ubuntu-24.04) FAILED 37/3/0 —
all three pass on macOS, none touched this session:
- `test-plan.sh` T20c–e: `tier_<label>: auto` in plan.md not refused.
- `test-session-loop.sh` A2a, A2b, A3b: killed child not `rc_nonzero`;
  writing child not paged.
- `test-context-budget-registry.sh`: 195/3; the failing ids are cut off
  (run-checks prints only the last 15 lines).
User chose to roll over and fix CI in a fresh session.

Learnings:
- `run-checks.sh` keeps only a failing suite's last 15 lines, so CI can hide
  which assertions failed; rerun the suite alone to see them.

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
