<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->


# Session Handoff — 2026-08-05 (session 6: implementation item #2 shipped — launch-next-session.sh; WARN rollover)

**What shipped (all committed + pushed, `b6d245a`, `d468f7c`, `ef42a12`):**

- **Item #2 complete.** `scripts/launch-next-session.sh` per ADR-0003/0004:
  verbatim bootstrap prompt (single source of truth in the script); runtime
  resolution --runtime flag > dying session's own registry record (D6,
  env-first identity mirroring `context-budget.sh session_id_for()`) > newest
  record for the project > `ROLLOVER_RUNTIME` > claude; 5 runtimes
  seeded-interactive (`claude` [+`--bg`], `codex` positional, `gemini -i`,
  `opencode --prompt`, `copilot -i` — all flags re-verified against live
  `--help` this session); modes off/manual/auto honored (auto+claude implies
  --bg); --bg claude-only (die otherwise); D8 successor confirmation poll
  after --bg (`ROLLOVER_CONFIRM_SECS`, default 120s, non-fatal); non-tty
  manual prints `run: <cmd>` instead of exec'ing a TUI; copilot-vscode
  degrades to prompt-only.
- **Tests:** `scripts/tests/test-launch-next-session.sh` — 13 cases /
  28 asserts, all green (dry-run flag assembly + stub-binary --bg/D8/timeout/
  non-tty paths). Registry suite still green (13/13).
- **Docs:** `docs/context-budget.md` §Rollover trigger policy status note
  flipped to implemented; backlog changelog row appended; four Tier-2 notes
  in `decisions.md` (tty guard, copilot-vscode degradation, --bg-only D8
  confirmation, always-print prompt); plan committed at
  `plans/2026-08-05-launch-next-session.md`; stale `workspace-structure.html`
  rebuilt.

**Where things stand:** items #1+#2 done; item #3 (four vendor hook
deployments) not started — next session's mission. Working tree clean apart
from the live `.active-session` lock (untracked by design).

**Suggested skills for next session:** superpowers:writing-plans →
executing-plans (the pattern items #1 and #2 both used successfully);
session-rollover at WARN/STOP.

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

