<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 5 (2026-10-12) (session 5: wave 1 closed)

Wave 1 of plan `plans/01-session-identity-fixes` is done (2/16 nodes). Rolled over before
wave 2: five parallel nodes on shared files don't fit in the headroom left.

- **Node 01 (refuse-instead-of-guess):** commit `3828bf2`. `scripts/context-budget.sh`:
  `pick_unambiguous` (codex and copilot-cli fallbacks), copilot-vscode rc 2, and
  `resolve_session` refuses `reason=ambiguous_artifact` (exit 4) on every command;
  `detect_runtime` checks id vars before `CLAUDECODE`. Suite sections D1/D2 in
  `scripts/tests/test-context-budget-registry.sh` (211/0); doc row in
  `docs/context-budget.md` → Reason codes.
- **Found:** the old copilot-vscode register guard was dead code (flag set in a `$(...)`
  subshell). Decision note in `decisions.md`.
- **Node 02 (reconcile w1):** commit `95ddf21`. No replan; two `plan.sh note` lines in
  `plan.md` for nodes 05–07.
- All other context-budget suites pass.

Suggested skills: `plans` (dispatch template, reconcile), `tdd`.

Learnings:
- A discover function's globals never reach the caller (`ARTIFACT=$(discover_for …)` is a
  subshell); signal through the exit code.

# Session Handoff — 2026-10-12 (session 4: VS Code probes; plan 01 created)

The user ran the Codex and Copilot VS Code probes in `~/Developer/experiments/ws-identity-probe`.
Written up in `probes/codex-vscode.md` and `probes/copilot-vscode.md`, folded into
`findings.md` (summary + nodes 5, 8a–8d). Then created plan
`plans/01-session-identity-fixes` (16 nodes, 5 waves); `check` is silent. Commit `1d51030`.

- **Codex VS Code:** like the CLI. Trust prompt comes after the turn, then applies to
  open chats; sandbox blocks `ps` (`pid: null`).
- **Copilot VS Code:** runs on the Copilot CLI runtime now; the copilot-vscode adapter
  registers a nonexistent `~/.copilot/chatSessions/<sid>.jsonl` and never measures; three
  hook configs fire per event (VS Code, CLI, Claude Stop).
- **Claude Code extension:** pre-spawns two idle sessions → phantom records.
- `make-ide-probe-clone.sh` now also wraps the Stop hook (it was missing).
- Decision (`decisions.md`): the remaining-probes hitl node sits in wave 3.
- Not run: Antigravity IDE/app and Codex desktop app probes (now node 11).

Suggested skills: `plan` (reconcile nodes), `tdd` (each node's suite cases).
