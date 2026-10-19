<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 7 (2026-10-18)

**Summary.** Fixed L101 (`1d6866f`): with `ANTIGRAVITY_APP_DATA_DIR` unset, `antigravity_discover`
in `scripts/context-budget.sh` tries `antigravity-cli/`, `antigravity-ide/`, `antigravity/` for
`brain/<id>/`, first hit wins. Registry suite L2d seen red first; suites 285/0 and 177/0,
run-checks 45/0. Card archived; scorecard 2/156/5/0/6. Item closed again.

**Decisions.** None new (the card prescribed the fix; commit carries the `Decision:` trailer).

**State.** Main 2 ahead of origin plus this checkpoint commit; push is the user's call. Open
cards: L97, L103 (not this item's).

**Learnings:** none new.

**Suggested skills:** none — item closed.

# Session Handoff — 6 (2026-10-18)

**Summary.** Node 13 reconciled wave 5 and closed plan `01-open-cards` (13/13): L86 archived,
L101 filed (Antigravity IDE shell `register`), allowlist documented in `docs/context-budget.md`,
"amended by" pointer in runtime-session-identity decisions (`87bd803`). L99: pruned
`code-simplification` from the vendored set (`1b2c7ce`). L100: re-tested `unslop` on six harder
tasks, two samples each; 37/37/52 of 60, so kept (`8a4e7eb`, ~$1.24). Item closed.

**Decisions.** `decisions.md`: L100 keep `unslop`. User, s6: unslop's tasks should be coding-work
prose (PR, README, code comment, design doc), plus the email and announcement.

**State.** Plan closed; pushed to origin (`6832cce`, user asked). Then the user asked to roll
over and fix L101 in this item — next session does it (launcher). L97, L103 stay open.

**Learnings:**
- A concurrent session (html-kit) wrote the backlog between my read and my commit; its edits
  merged cleanly but a changelog row's "Scorecard now" went stale. Re-read the scorecard after
  committing when another session is active.
- Skill pilots on short, obvious inputs hit a ceiling (every arm passes); use longer inputs with
  the structural tells the skill targets.

**Suggested skills:** `tdd` (L101: fixture test red first).

# Session Handoff — 5 (2026-10-18)

**Summary.** Node 12 done: wrote `work/runtime-session-identity/probes/antigravity-ide.md`
and `probes/codex-app.md` (both PASS). Found that Codex Desktop runs `.claude/settings.json`
hooks and, under the session loop, the claude Stop shim would SIGTERM a Codex session as
claude. On the user's ask, replaced the per-runtime guards with one allowlist
(`budget_hook_is_claude_transcript` in `scripts/hooks/context-budget-hook-lib.sh`; new
`scripts/hooks/context-budget-claude-session-hook.sh`; settings.json holds no logic) —
`cc1173e`, tests K3a–f, run-checks 45/45. Node 12 `524f27b`. User decided L99/L100.
Rolled over at WARN (149K).

**Decisions.** `decisions.md`: hook allowlist over denylist; L99 prune
`code-simplification`; L100 re-test `unslop` on harder prose before deciding.

**State.** Plan open, frontier `13-reconcile-w5`. Main ahead of origin (push is the user's
call). Staged `work/html-kit/…` → `docs/kit/` renames belong to another session — don't
commit them.

**Learnings:**
- BSD `sed` has no `\|` alternation in BRE; one silent no-op cost a test round. Use
  separate `-e` expressions.
- The Antigravity IDE shell has no `ANTIGRAVITY_APP_DATA_DIR`, so `antigravity_discover`
  (`scripts/context-budget.sh:358`) misses `~/.gemini/antigravity-ide/` — card to file at 13.

**Suggested skills:** `plans` (reconcile 13), `checkpoint`.

