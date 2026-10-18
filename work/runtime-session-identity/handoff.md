<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 10 (2026-10-18) (session 10: Copilot VS Code re-probe; plan 02 opened)

**Summary.** Explained Copilot-in-VS-Code to the user, then re-read the s9 row-5 logs and ran
a fresh two-chat re-probe (labels `copilot-vscode-C`/`-D`). Binding PASS again. The s9
"hooks silent" finding was a misread: hooks fired in s9 and s10, four hook sets per Copilot
event (CLI config, VS Code config, Claude `Stop` and `PostToolUse`). Duplicate records
explained (CLI hook writes `copilot-cli-*`, agent `register` writes `copilot-vscode-*`). New
gap: VS Code transcripts carry `prompt_tokens`, not `inputTokens`, so measurement falls back
to a ~30%-low estimate. Write-up: `probes/copilot-vscode.md` → "Re-probe (s10)".

**Shipped.** 816a7d9 — probe write-up + plan `02-copilot-vscode-followups` (6 nodes, 0 done,
`replan: structural`). Not pushed (pushing main is the user's call).

**Decisions.** Fix the undercount directly; hook fan-out and duplicate records go through a
user decision (hitl node 05) before any build (commit trailer of 816a7d9).

**State.** User said "roll over, then start wave 1". Other sessions have uncommitted edits in
the shared checkout (docs/context-budget.md, launch-next-session.sh, session-loop.sh, their
tests, backlog html, work/html-kit, work/clear-session-loop): not ours, untouched.

**Suggested skills.** `tdd` for node 01; subagents (read-only) for nodes 02 and 03.

Learnings:
- Before writing "hooks did not fire", grep each hook log for the session id; s9 misread
  non-empty logs as empty.


# Session Handoff — 9 (2026-10-12) (session 9: CLI surfaces probed live; VS Code rows handed to the user)

**Summary.** New probe clone `~/Developer/experiments/ws-identity-probe-s9` at 191944f. The old
pre-fix clone was left untouched. The probe now wraps the claude and antigravity hooks, runs
`check`, and writes one log per label. Two concurrent sessions per CLI, from a clean env:
Claude CLI PASS; Codex CLI PASS (agent side, and hook side with user-approved trust bypass);
Copilot CLI agent side PASS, hooks not fired (clone not in `trustedFolders`); Antigravity hook
side PASS, agent shell not run. Details are in each `probes/<surface>.md` under "Post-fix (s9)".

**User rows (2026-10-13).** Rows 1–3 PASS (Copilot CLI hooks, agy agent shell, Claude VS Code;
no phantoms). Row 4 Codex VS Code: PASS once trusted; GAP: no hook-trust prompt in the
extension (workaround: a one-time CLI run). Row 5 Copilot VS Code: binding PASS; hooks silent and
2 records per chat (to investigate). Rolled over at 141K with ROLLOVER_RELAUNCH=manual.

**Blocked by the agent permission classifier (user said "you have my permission to trust", but
these were still denied):** editing `~/.copilot/config.json` `trustedFolders`, and
`agy --dangerously-skip-permissions`. Both moved to `probes/user-checklist.md` rows 1–2.

**State.** `probes/user-checklist.md` was rewritten as one post-fix checklist (rows 1–5) and is
waiting on the user. No gaps found yet, so no backlog card. L86 is not yet updated.
doc-consistency 17/0.

Learnings:
- Reusing a probe label across runtimes made `probe-env.sh`'s `tail` show the earlier runtime's
  lines. Use labels that are unique per runtime.
- `codex exec` reports `method=estimate` until the first `token_count` event, then `exact`.
