---
id: 03-codex-hook-registration
title: Hook-side registration for Codex (node 1)
status: todo
kind: work
wave: 2
blocked_by: [02-reconcile-w1]
sessions: []
---

## Goal

Findings: `work/runtime-session-identity/findings.md` → "Gaps", node 1. Evidence: `probes/codex-cli.md`, `probes/codex-vscode.md`.

Add `[[hooks.SessionStart]]` to `.codex/config.toml` and set the codex adapter row to
`register=hook`. Hooks read the id and transcript only from the payload; hook processes get
no `CODEX_*` env (CLI and VS Code both).

## Acceptance

- [ ] Suite case: a SessionStart payload with the env var unset writes `codex-<sid>.json` pointing at the payload's `transcript_path`
- [ ] Suite case: a UserPromptSubmit payload heals a missing registration
- [ ] Existing suites pass

## Log
