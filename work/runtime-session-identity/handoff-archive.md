# Session Handoff — 2026-10-12 (session 3: Antigravity CLI probe)

Probed `agy` 1.3.3 in a scratch clone → `probes/antigravity-cli.md`. Hooks
live in `.agents/hooks.json` (spec found embedded in the binary), fire with no
trust step, and every payload carries `conversationId` + `transcriptPath`; hook
processes also get `ANTIGRAVITY_CONVERSATION_ID`. No SessionStart event: the
first `PreInvocation` (`invocationNum: 0`) stands in. Two concurrent runs each
got their own id on the hook side. `register` auto-detects Antigravity as
gemini and binds a stale `logs.json` while reporting OK. Q1 (agent's shell) is
blocked: headless `agy` auto-denies `run_command`, hook `permissionOverrides`
don't lift it, and the Claude Code classifier denied
`--dangerously-skip-permissions`. Rewrote draft node 6 as "Antigravity: add as
a runtime" and added the Antigravity column to `findings.md`. Then the user
ran the skip-permissions command: Q1 = YES (`ANTIGRAVITY_CONVERSATION_ID`,
`ANTIGRAVITY_APP_DATA_DIR` in the agent's shell). Because `agy` was launched
from Claude Code, `register` inside it bound the parent Claude session:
`detect_runtime` lets an inherited `CLAUDECODE` win. That is now part of node 6
and node 4's check. IDE probes still waiting on the user.

Suggested skills: `plans` (once IDE probes land), `diagnosing-bugs` for probes.
Committed: `46666f6`, `b32ecac`, `97e2f93` (main, 3 ahead of origin, unpushed).

Learnings:
- `agy` headless (`-p`) auto-denies `run_command` unless the global settings
  allow-list or `--dangerously-skip-permissions` permits it; hook
  `permissionOverrides` don't help. The Claude Code classifier blocks the skip
  flag, so the user has to run that command.
- Its hook spec is only in the binary (`strings agy` → "Lifecycle Hooks").

# Session Handoff — 2026-10-12 (session 2: scaffolded; CLI probes done; draft plan)

Scaffolded after a Q&A on how non-Claude runtimes identify sessions. Ran three
CLI probes in parallel in scratch clones: `probes/codex-cli.md` and
`probes/copilot-cli.md` (live), and `probes/gemini-cli.md` (static only; no
auth: needs `GEMINI_API_KEY`). Headline: Codex and Copilot set an id env var
in the agent's shell and bind correctly with it; without it, two concurrent
sessions swap transcripts (both seen live). All three runtimes' hooks carry
`session_id` + `transcript_path`, so hook-side registration (the Claude
model) is viable. Copilot CLI also fires our VS Code hook file and likely the
Claude hooks. Draft plan in `findings.md`. IDE probe kit built and
smoke-tested (`probes/make-ide-probe-clone.sh`, `probe-env.sh`,
`user-checklist.md`); waiting on the user. Nothing committed.
