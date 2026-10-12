---
id: 03-codex-hook-registration
title: Hook-side registration for Codex (node 1)
status: doing
kind: work
wave: 2
blocked_by: [02-reconcile-w1]
sessions: [6]
---

## Goal

Findings: `work/runtime-session-identity/findings.md` → "Gaps", node 1. Evidence: `probes/codex-cli.md`, `probes/codex-vscode.md`.

Add `[[hooks.SessionStart]]` to `.codex/config.toml` and set the codex adapter row to
`register=hook`. Hooks read the id and transcript only from the payload; hook processes get
no `CODEX_*` env (CLI and VS Code both).

## Acceptance

- [x] Suite case: a SessionStart payload with the env var unset writes `codex-<sid>.json` pointing at the payload's `transcript_path`
- [x] Suite case: a UserPromptSubmit payload heals a missing registration
- [x] Existing suites pass

## Log
- s6 · started, tier standard
- s6-a · red: added E1 (SessionStart registers, config wires it) + E2 (UserPromptSubmit heals) to scripts/tests/test-context-budget-registry.sh; E1a, E1e, E2a FAIL before the fix (passed=212 failed=3)
- s6-a · green: codex row register=hook + pin CODEX_THREAD_ID=sid (scripts/hooks/context-budget-adapters.conf), dispatcher registers-only on a register=hook row's other events (scripts/hooks/context-budget-hook.sh), codex shim takes the event (scripts/hooks/context-budget-codex-hook.sh), [[hooks.SessionStart]] in .codex/config.toml, docs/context-budget.md codex row; E3 (inherited CODEX_THREAD_ID must not win) seen FAIL with pin "-", passes with the pin; registry 218/0, hooks 150/0, all 18 context-budget-touching suites pass
