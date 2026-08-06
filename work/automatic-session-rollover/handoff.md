<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-05 (session 5: implementation item #1 shipped — session-keyed registry, lock, release, gemini guard; WARN rollover)

**What shipped (all committed + pushed, `15ec961`…`187f926` + rollover commit):**

- **Item #1 complete, M13 closed.** `scripts/context-budget.sh` migrated to the
  session-keyed registry per ADR-0004: `session_id_for()` (env-first identity,
  artifact-derived fallback, gemini fixed id `workspace`); resolve-self in
  `check`/`record` (own session file only, never another's);
  `.context-budget/sessions/<runtime>-<session-id>.json`; `register --project`
  acquires `work/<proj>/.active-session` (advisory: live holder warned never
  stolen; stale >`CONTEXT_LOCK_STALE_SECS` [new knob, 3h] reclaimed); new
  `release` subcommand (self-only, project defaults from own session record);
  gemini concurrent-session guard (fresh non-empty telemetry log → skip reset,
  degrade to chat-log estimate).
- **Tests:** `scripts/tests/test-context-budget-registry.sh` — 13 asserts, all
  green; T1 is the live M13 clobber repro (was red against the old scalar
  registry). Self-contained throwaway workspace in mktemp; fake $HOME.
- **Docs:** `docs/context-budget.md` (§Multi-session status → implemented;
  §Session registration rewritten for sessions/ + lock + release; gemini-only
  limitation para), `skills/session-rollover/SKILL.md` (release call after
  verification gate), backlog M13 → Resolved, new L16 (phantom test suite in
  workspace-structure.md, fixed same session), summary line → all 31 resolved.
- **Plan + decisions:** implementation plan at
  `plans/2026-08-05-session-keyed-registry.md` (all tasks checked off in
  execution, file committed with this rollover); three Tier-2 notes appended to
  `decisions.md` (identity derivation, advisory-not-blocking lock, gemini
  freshness guard).

**Verification state:** `bash scripts/tests/test-context-budget-registry.sh`
exits 0; live register/record in this session used the new registry and
correctly tracked this session's own transcript (dogfood: the WARN that
triggered this rollover came from it).

**Suggested skills for next session:** `superpowers:writing-plans` then
`superpowers:executing-plans` (same pattern as this session) for item #2;
`docs/context-budget.md` §Relaunch knobs is the spec.

# Session Handoff — 2026-08-05 (session 4: documentation phase shipped in one commit; WARN rollover into implementation phase)

Executed the session-3 launcher's documentation plan verbatim; no design was
reopened. Substance is in the committed docs themselves; this block is
provenance only.

- One commit, `9c6a097`, pushed to main: `docs/context-budget.md` gained
  "Rollover trigger policy" / "Relaunch knobs" / "Multi-session model"
  sections (each with an explicit design-accepted-implementation-pending
  status note) and corrected stale copilot-cli "unverified" claims (smoke
  test verified 73.0k exact); knob block landed in `context-budget.env`
  (`ROLLOVER_RELAUNCH=manual`, `ROLLOVER_RUNTIME=claude`);
  `skills/session-rollover/SKILL.md` gained hybrid trigger semantics, the
  hook-less cadence fallback (~10 exchanges), and the relaunch closing step
  (graceful when the script is absent); pointer lines in `CONTEXT.md` +
  `docs/workspace-structure.md`; ADR-0004 companion promoted from the three
  session-3 notes (Promote? fields flipped; ADR-0003 got a Refined-by link);
  `issues/01-vscode-agent-mode-hooks.md` ticket created; backlog card M13
  (registry-clobber bug, Open with approved fix) + scorecard updated.
- Doc-phase decision recorded in `decisions.md` (newest note): one companion
  ADR-0004, not an amended 0003 or four ADRs.
- Ops note: `workspace-structure.md`'s scripts tree already lists planned
  entries (`scripts/tests/` doesn't exist on disk), so the
  `launch-next-session.sh` tree line landing pre-implementation is consistent;
  `check-workspace-structure.sh` iterates existing scripts only.
- WARN (122.7K) fired at commit time; user approved rollover. Docs summary was
  presented; user raised no objections before approving — treat the doc set as
  baseline unless they say otherwise.

Suggested skills for the next session: `superpowers:writing-plans` or `tdd`
(implementation of the registry migration), `decision-log`,
`session-rollover` at the boundary.

---

