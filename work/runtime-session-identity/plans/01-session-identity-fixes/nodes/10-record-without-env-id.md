---
id: 10-record-without-env-id
title: Agent-run record finds its own session without the env var (node 5)
status: doing
kind: work
wave: 3
blocked_by: [08-reconcile-w2]
sessions: [7]
---

## Goal

Findings: `work/runtime-session-identity/findings.md` → "Gaps", node 5.

`record` from an agent shell with no id var must find its own registry record. A pid walk
is out (Copilot's `copilot-runtime` serves every chat; Codex's sandbox blocks `ps`). Use the
env id where the runtime sets one; otherwise have the hook's context message carry the id
for `--session-id`.

## Acceptance

- [x] Suite case: `record` with the runtime's env id set and no `--session-id` updates that session's record, with a sibling record present
- [x] Suite case: with no id var and two live records, `record` refuses (no guess) and names `--session-id`
- [x] Existing suites pass

## Log
- s7 · started, tier standard
- s7-b · B1a–B1f added to `scripts/tests/test-context-budget-registry.sh`: codex, copilot-cli and antigravity, each with an env id and a sibling record. Own record refreshed, own ledger row written, sibling untouched. They PASSED before any change: resolve-self already reads `<rt>-<env id>.json`. No fix is claimed for them.
- s7-b · B2a–B2h added: claude with CLAUDECODE only, two live registered transcripts in the cwd. Seen failing first with 9 FAIL: `record` and `check` exited 0, and the guess touched `claude-b2-two.json`.
- s7-b · fix in `scripts/context-budget.sh`. With no id var, `resolve_session` runs the runtime's non-child registry artifacts through `pick_unambiguous` before discovery. More than one live in the cwd refuses `reason=ambiguous_artifact` (every command), and the message names `--session-id <own id>`. The `--session-id` pin now admits `record`; register/release/close still refuse. N1i/N1j changed from "record refuses the pin" to "release refuses it". The pin paragraph in `docs/context-budget.md` is corrected to match.
- s7-b · hook-message half of the Goal NOT done. Making the hook's context message carry the id changed 14 byte-for-byte fixtures in `test-vendor-budget-hooks.sh` (a payload-contract change), so it was reverted. Every probed runtime exports an env id. Left for the orchestrator to decide.
- s7-b · verified: registry 258/0, statusline 20/0, vendor-budget-hooks 165/0, attach-session 27/0, doc-consistency 17/0.
- s7-b · merged main (with nodes 09 and 11). Registry conflict resolved by keeping both, with Q/A first and then B. After the merge: registry 269/0, statusline 20/0, vendor-budget-hooks 165/0, attach-session 27/0, doc-consistency 17/0. On disk and committed on the branch, not pushed: the fix in `scripts/context-budget.sh`, the B1/B2 cases in `scripts/tests/test-context-budget-registry.sh`, and the doc fix in `docs/context-budget.md`. Not on disk: the hook message carrying the session id.
