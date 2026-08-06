# 01 — Verify VS Code agent-mode hooks + `copilot_vscode_measure` on a Copilot-licensed machine

Type: task
Status: open — **UNBLOCKED 2026-08-06** (see update below)

## Why spun out

Everything else in the detection scope was verified live on this machine
(smoke tests in `../smoke-test-opencode.md` and `../smoke-test-copilot.md`);
this piece can't be: it needs a VS Code install with a licensed Copilot
extension, which the origin machine doesn't have. VS Code agent-mode hooks
also shipped only in v1.109 as **Preview**, so the contract may shift before
verification. Decision provenance: `../decisions.md` → "Detection + runtime
scope after smoke tests (session 3)"; ADR-0004.

## What to verify

1. **Agent-mode hooks fire.** Wire a minimal hook per the v1.109 agent-mode
   hooks contract (see `../vendor-hooks-research.md` → VS Code section) and
   confirm a WARN/STOP push can reach an agent-mode session in-band —
   the equivalent of the copilot CLI `sessionStart` `additionalContext` /
   `agentStop` block-`reason` channels confirmed in `../smoke-test-copilot.md`.
2. **`copilot_vscode_measure` is exact.** The adapter branch in
   `scripts/context-budget.sh` (chatSessions `promptTokens` grep — see
   `docs/context-budget.md` per-runtime table, "Copilot VS Code" row) is
   plausible but unverified on current builds; compare its output against the
   live session UI the way copilot-cli was verified (73.0k exact match).

## Update 2026-08-06 — blocker lifted; scope grows one item

- **The origin machine now qualifies:** the user confirmed a **Copilot Pro
  license** active in their VS Code Copilot session on this machine
  (VS Code 1.132.0 installed). "Needs a Copilot-licensed machine" no longer
  defers this ticket — schedule it as normal work when wayfinder tickets
  06–08 are done.
- **New third item — copilot-vscode seeded relaunch via `code chat`.**
  VS Code 1.132's CLI ships a `code chat [options] [prompt]` subcommand
  (`-m ask|edit|agent|<custom>`, defaults to `agent`; `-r` reuse last
  window; `-a` add file context; stdin via trailing `-`). CLI presence +
  flag surface verified on this machine 2026-08-06 (`code chat --help`);
  end-to-end (does the seeded agent session actually start and run?) is
  unverified — same live-verification pass as items 1–2. If it works,
  `launch-next-session.sh`'s `copilot-vscode` branch upgrades from
  note-and-punt ("paste the prompt into VS Code agent mode") to seeded
  interactive: `CMD=(code chat -r -m agent "$PROMPT")` — same tier as
  codex/gemini/opencode/copilot-cli. Add a W-test + docs
  (`docs/context-budget.md` relaunch-knobs section, `relaunch-analysis.md`
  table row) with the verification.
- A live copilot-vscode agent-mode session on this work item doubles as the
  item-2 verification vehicle: its `register`/`check` output line is exactly
  the `copilot_vscode_measure` evidence needed (compare tokens against the
  session UI, like copilot-cli's 73.0k match).

## Done when

- All three checks pass on a Copilot-licensed machine (note VS Code +
  extension versions in this file), or findings recorded here and the
  adapter/docs/launcher amended to match reality.
