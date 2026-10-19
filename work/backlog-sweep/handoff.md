<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

# Session Handoff — 4 (2026-10-18)

**Summary.** Node 08 code-review (Standards + Spec, two opus children) over
`4b65f8c...HEAD` scoped to this plan's paths — 0 blockers; fixed the L96 "(default 4h)"
wording in `docs/context-budget.md` and promoted the `plan.sh verify` / `WORKSPACE_ROOT`
gotcha to `docs/operational-knowledge.md`; rest logged in `nodes/08-review.md`. Reconciled
wave 3 (`40634a6`). Then guided the user through the L86 probes in the clone
`~/Developer/experiments/ws-identity-probe-s9`: Antigravity IDE and Codex inside
ChatGPT.app both **pass** (own transcript per chat, one record each, hooks per chat).
Node 10 done `--by human`, wave 4 reconciled (11). Rolled over at WARN (122K).

**Decisions.** `decisions.md`: Codex desktop probe ran on Codex in ChatGPT.app — the
standalone `codex-app` cask is discontinued upstream.

**State.** Plan open, wave 5; frontier `12-l86-probe-writeup`, then `13-reconcile-w5`.
Raw evidence for node 12 is in `nodes/10-l86-user-probes.md` Log (IDs, timestamps, log
paths in the clone). New gap to file at 13: Codex Desktop also runs the
`.claude/settings.json` Stop hook (`context-budget-stop-hook.sh claude` with a Codex
payload). Main ahead of origin (push is the user's call).

**Learnings:**
- Scope a review's diff to the plan's own paths when other sessions committed on shared
  files in the range; name the foreign commits for the reviewers.
- The checklist's "steps 3–4" label in L86/node 10 was wrong (rows 3–4 are the VS Code
  extensions); the L86 surfaces are the checklist's "Optional" line.

**Suggested skills:** `plans` (reconcile 13), `decision-log`.

