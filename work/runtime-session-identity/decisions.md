# Decisions — runtime-session-identity

Tier-2 decision notes (skills/decision-log/SKILL.md). Newest last.

## 2026-10-12 — remaining-surface probes are a wave-3 hitl node

Antigravity IDE/app and Codex desktop app probes went into plan 01 as hitl node 11 (wave 3),
not ahead of wave 1, so the refuse-instead-of-guess and adapter fixes run hands-off.
Rejected: gating the whole plan on them. The VS Code results already settled node 5
(no pid-walk), and those probes can only add follow-up nodes.

## 2026-10-12 — ambiguous discovery refuses on every command, not only register

When discovery has no id var and finds more than one live transcript for the cwd,
`check`, `record` and `register` all exit 4 with `reason=ambiguous_artifact`.
Rejected: refuse on `register` only and warn on reads (the old copilot-vscode rule). That
rule was dead code anyway: its flag was set inside a `$(...)` subshell and never reached
`resolve_session`. A read of a sibling's transcript still gives a false STOP. Node 10
(`record` without the env id) is how an agent shell gets a non-ambiguous read.
