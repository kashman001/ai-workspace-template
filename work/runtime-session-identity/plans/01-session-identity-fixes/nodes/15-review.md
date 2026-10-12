---
id: 15-review
title: Run code-review on the work since bc1cce4; fix the findings
status: done
kind: work
wave: 5
blocked_by: [14-reconcile-w4]
sessions: [8]
---

## Goal

Run `code-review` (`skills/code-review/SKILL.md`) on the work since `bc1cce4` against
`work/runtime-session-identity/findings.md` (the spec for this plan), then fix the findings.

## Acceptance

- [x] Review run
- [x] Every blocker fixed; each suggestion fixed or logged
- [x] The item's checks pass

## Log
- s8 · started, tier standard

- s8 · code-review on bc1cce4...HEAD (outside work/), two sub-agents. Standards: no hard
  violations. Spec: no blockers; every gap's proving check has a suite case.
- s8 · Fixed, each test-first (case seen failing, then passing):
  - 0b4dd7c: Claude SessionEnd ran `release` with no transcript_path, so a Copilot payload
    fell back to claude discovery and could end a sibling's block. Now guarded like
    SessionStart. Hooks K1g (K1h is the control).
  - 0d581ce: agent-shell copilot-cli/copilot-vscode discovery ignored COPILOT_STATE_DIR,
    which the hook honours (decisions.md). Registry U1.
  - 0964a23: copilot-cli discovery with no cwd match took newest-mtime across
    session-state/ (other projects' live sessions). Now only the legacy
    history-session-state/ keeps that. Registry U2.
- s8 · Logged, not changed:
  - The gap-3 Claude-hook claim is still fixture-only (no live re-probe). Waits on backlog L86.
  - prune_phantoms with an empty `.artifact` cannot happen: resolve_session stops on a
    missing artifact (context-budget.sh:566), so every record carries one.
  - pick_unambiguous's "newest first" contract is not met by the registry-record loop.
    That is harmless: its output goes to /dev/null.
  - `grep -qF "$(pwd)"` is a substring match (/x/ws also matches /x/ws2). This is
    pre-existing moved code, so it is a follow-up and not this plan's.
  - Smells, all judgement calls:
    - Repeated Switches: the per-runtime case cascades predate this plan.
    - The session-state path pattern appears three times.
    - copilot_vscode_measure is now a thin delegate.
    - The antigravity row in adapters.conf is misaligned (cosmetic).
    - Comments cite IDs (node 10, s5). This matches the script's existing M13/M16/D8 style.
- s8 · Launcher said test prefixes C, G and M were unused. All three are in use in the
  registry suite, so the new cases use U. Suites: registry 272/0, hooks 167/0,
  statusline 20/0, attach 27/0, doc-consistency 17/0.
- s8 · done
