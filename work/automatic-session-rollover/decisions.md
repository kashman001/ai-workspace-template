# Decisions — automatic-session-rollover

Tier-2 decision notes, newest last. Format: `skills/decision-log/SKILL.md`.

## 2026-08-05 — Automate the rollover→relaunch pipeline (the effort itself)
**Chose:** A workspace-owned script (`scripts/launch-next-session.sh`) that
bakes the canonical bootstrap prompt in verbatim and launches a fresh runtime
session seeded with it, governed by workspace parameters offering a
consent-gated mode (agent asks, then launches and continues) and a fully
automatic mode (WARN/STOP triggers rollover + relaunch unprompted).
Interactive seeded launch is the agent-agnostic core; detached background
launch is a claude-only tier.
**Because:** Stage 3 of the rollover pipeline (relaunch) is a manual
copy-paste today, and the prompt wording is load-bearing — hand-typed looser
phrasings make the new session summarize-and-wait instead of execute. Keeping
disk (launcher + ledger) as the source of truth means any runtime can pick the
work up; the script only accelerates the launch.
**Rejected:** upstream `claude-handoff` wholesale — its content rules already
landed via the inlined hand-off contract; its prompt-only background-handoff
mechanism — loses disk-as-source-of-truth and is Claude-only; nohup+yolo
background emulation for codex/gemini — trades permission safety for symmetry;
inlining vendor launch commands in the `session-rollover` skill — violates the
CLI-first rule (vendor specifics live only in scripts).
**Blast radius:** `scripts/launch-next-session.sh` (new),
`context-budget.env`, `skills/session-rollover/SKILL.md` (closing step),
`docs/context-budget.md`, `docs/workspace-structure.md`.
**Promote?:** done → ADR-0003
