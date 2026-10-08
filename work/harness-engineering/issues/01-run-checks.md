# 01 — One command runs every check; pre-commit and CI call it (M44)

**What to build:** `scripts/run-checks.sh` runs every `scripts/tests/`
suite and every `scripts/check-*` script, invoking each the right way
(`bash` for `.sh`, `python3` for `.py` — some suites lack the exec
bit), and prints one pass/fail line per check plus a total. Exit 0 only
if all pass. Two tiers: `--fast` (checks that finish in seconds and need
no network; pick by timing them) and the default full run. Then:

- **Pre-commit:** a plain git hook script (no Husky/npm — the template is
  bash) that runs `run-checks.sh --fast`, plus an opt-in install step
  (e.g. `git config core.hooksPath`). Must not fire for adopters who
  haven't opted in.
- **CI:** `.github/workflows/checks.yml` running the full tier on push and
  pull request. Must pass on a runner without the user's keychain, `claude`
  or other agent CLIs — suites that need them must skip with a reason, not
  fail. `scripts/tests/test-jev.sh` once hit a live URL (session-2
  learning in `work/context-memory-hardening/handoff.md`): make it hermetic
  or skip it in CI.
- **Docs:** `docs/workspace-structure.md` (scripts list + layout tree),
  `docs/template-usage.md` (adopters: how to opt in, how to remove the
  workflow), `docs/README.md` index if a new doc appears.

Source: `source-notes.md` → "Keep quality left".

**Blocked by:** nothing.

**Status:** done

- [x] Failing test first: a suite for `run-checks.sh` with fixture checks
      (one passing, one failing, one `.py`, one without the exec bit) →
      the right per-check lines and exit code
- [x] `run-checks.sh` green on `main`, full and `--fast`; record both
      wall times in the ticket
- [x] Pre-commit hook + opt-in install, documented
- [x] CI workflow added (UNVERIFIED on GitHub — simulated locally only); can't be run from here, so note it as unverified
      until the user pushes, and say so in the ledger
- [x] Backlog card resolved in the same commit: badge → Resolved, `Fixed:`
      line with the commit, card moved to the matching section of
      `docs/template-workspace-backlog-archive.html`, scorecard and "Last
      updated" changed, change-log row added
- [x] All `scripts/tests/test-*` suites green (after ticket 01:
      `scripts/run-checks.sh` exits 0); `scripts/check-workspace-structure.sh` exit 0
- [x] One commit, `Fix <ID>: …`, with a `Decision:` trailer

**Done (2026-10-08, session 1).** Wall times on this Mac: full 120s (33
checks), `--fast` 13s (23 checks). Tier is a `# run-checks: slow` marker in
each slow script (>~3s or networked), not a list in `run-checks.sh`.
Simulated CI (no agent CLIs on PATH, empty HOME, no git identity, gh by
`GH_TOKEN`) passes 33/0/0 — but on macOS; Linux portability of the suites
is unverified until the first push. `test-jev.sh` made hermetic: a slow
stub start left the endpoint empty (→ live-URL fallback), and stub servers
leaked (~90 found running).
