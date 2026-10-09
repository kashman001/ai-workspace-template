<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 20 (2026-10-09): DeepSeek Harness cards M46, M47, L66–L69 fixed; L70 sent upstream

**What got done (on main, not pushed):**
- `fa7d5f4`: all six fixes in one commit.
  - M46: `test-agent-entrypoints.sh` E6 checks that a skill's
    `disable-model-invocation: true` and its Codex
    `allow_implicit_invocation: false` agree. Six skills gained `agents/openai.yaml`.
  - M47: under `CI`, a skip (exit 77) fails `run-checks.sh` unless the check
    carries `# run-checks: may-skip-in-ci`. No check exits 77 today.
  - L66: the "report what you ran" rule is now in `CONTEXT.md` rule 4 and in
    checkpoint, plans reconcile, and research-wave.
  - L67: the "Readable without the transcript" test is in
    `docs/work-directory-conventions.md` (Ledger), not `writing-for-agents`,
    because that skill's body is vendored and the sync script would wipe an edit.
  - L68: the repair order is in `check-drift.sh` (comment and message).
  - L69: root `.rgignore`.
- `4577d61`: `TEMPLATE_VERSION` set to 2026-10-09.
- L70 stays Open. Step 3 and the Standards brief in step 4 already cover part
  of what the card asked for, so the card's evidence was corrected. Filed
  upstream as mattpocock/skills#1242 (draft in `upstream-issue-code-review.md`).

**Verification:** `CI=true scripts/run-checks.sh` reported 40/0/0 before the
commits. E6b failed on exactly the six skills until their yaml existed.
`test-run-checks.sh` R3b failed until `run-checks.sh` was changed.
`test-template-version.sh` passes 9/9.

**State:** `main` is 4 ahead of `origin` and unpushed (push is the
maintainer's call). The backlog has 1 Open card (L70), waiting on upstream.

**After the stop door (user asked):** pushed `main` (`8d3c7dc..570096c`).
`checks` run 37987347172 passed 40/0/0, so no check skips on the runner.
#1242 is open and labelled `needs-triage`, with no replies yet.

**Rolled over at WARN (131K tokens) with two jobs for session 21.** The user
does not want to rely on #1242 being merged, and chose the "patched" vendored
class for L70 (`decisions.md`, 2026-10-09). The user also asked to update to
the latest `mattpocock/skills` and integrate any new skills. The local clone
`~/Developer/references/mattpocock-skills` is at `068b6e0`, the commit every
vendored skill is pinned to; it has not been pulled.

**Suggested skills for session 21:** `writing-for-agents` (before any edit under
`skills/`), `tdd` (sync-script change), `decision-log`.

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

**After the stop door (user asked):** pushed `main` (`40f4389..8d3c7dc`);
`checks` run 37886203906 green, 40/0/0. No `TEMPLATE_VERSION` change
(already 2026-10-08). No backlog card.
