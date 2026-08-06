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

## Update 2026-08-06 (session 26) — item 2 first live attempt: NEGATIVE result

First run of the item-2 verification in a live Copilot Chat agent-mode
session (Copilot Pro, Sonnet 5, this machine, relayed by the user):

- `check --runtime copilot-vscode` found **no session artifact** —
  `copilot_vscode_discover` came up empty in a live agent session. Not yet
  diagnosed: whether `VSCODE_TARGET_SESSION_LOG` was unset in the agent's
  terminal, or no `workspaceStorage/*/chatSessions/*.jsonl` matched the cwd
  (current builds may have moved/renamed the store, or the session hadn't
  flushed). Note the copilot agent itself mis-attributed the miss to "a
  usage-tracking hook not having written its file" — discovery reads
  VS Code's own chatSessions logs, no hook involved.
- Independent constraint confirmed by the agent: it cannot introspect its
  own token/context usage (no tool or readable UI surface) — so the
  UI-comparison leg needs the USER to read the number visually, as with
  the copilot-cli 73.0k match.
- Diagnostic ran (user relay + claude-side probe), and the story flipped:
  **the measure branch WORKS on current builds; only the in-copilot
  environment is broken.** From the copilot agent's terminal:
  `VSCODE_TARGET_SESSION_LOG` UNSET, and `ls` of
  `workspaceStorage/*/chatSessions/` returned NOTHING. From a normal shell
  (claude session, same user): the store exists exactly where
  `copilot_vscode_discover` expects — workspace `d939e947…` with
  `workspace.json` matching this workspace root, live session log
  `chatSessions/89e4a886-….jsonl` carrying `promptTokens`. So the copilot
  agent's shell either sandboxes `~/Library` reads or runs with a different
  HOME — the discovery failure is scoped to *checks run from inside the
  copilot session*, not to the adapter.
- **Item-2 measure verification (2026-08-06, VS Code 1.132.0, Copilot Chat
  agent mode, Sonnet 5):** `check --runtime copilot-vscode --transcript
  <live chatSessions jsonl>` → `method=exact tokens=38680` while the
  session was live and mid-conversation. Remaining leg: compare against a
  UI-visible number (the agent cannot introspect its own usage — the user
  must read the UI meter, if any). Consequence for the vendor-hook wiring:
  a copilot-vscode session CANNOT self-measure from its own terminal
  (env + `~/Library` visibility) — measurement must run from outside
  (another session/watcher), or the hook contract must deliver the
  artifact path in-band (item 1 territory).

## Update 2026-08-06 (session 27) — sandbox discovery fix implemented

The user-approved fix spec (`work/context-decay/
copilot-vscode-sandbox-discovery-fix.md`) is implemented in
`copilot_vscode_discover()`: the workspaceStorage hash is now derived from
`$VSCODE_TARGET_SESSION_LOG` by parameter expansion and the token file
probed directly (`workspaceStorage/<hash>/chatSessions/<sid>.jsonl`), no
`readdir` on `workspaceStorage/` — the glob-and-grep scan remains as the
fallback for older builds. Verified with a fake-HOME harness including a
`chmod 311` readdir-blocked parent (sandbox simulation, 7/7 checks) and
the full `scripts/tests/` suite (326 asserts green).

**In-copilot live verification (2026-08-06, same VS Code instance,
user-relayed): PASS.** The copilot agent exported
`VSCODE_TARGET_SESSION_LOG` (value taken from its session context —
confirmed visible there but not exported to its shell) and ran
`register`/`check --runtime copilot-vscode` from its sandboxed terminal:
discovery pinned the correct artifact
(`workspaceStorage/d939e947…/chatSessions/53e98f5e-….jsonl`, basename =
session id) with no `workspaceStorage/` listing. It reported
`method=estimate tokens=530` — not a defect: the check ran mid-first-turn
before copilot's usage flush (file was ~2.1 KB, size/4 fallback); after
the turn flushed, the same file carries `promptTokens:38152` and
`copilot_vscode_measure` returns `38152 exact`. Estimate-until-first-flush
is the designed degrade. Only optional leg left: comparing tokens against
a UI-visible meter (none reported so far).

## Done when

- All three checks pass on a Copilot-licensed machine (note VS Code +
  extension versions in this file), or findings recorded here and the
  adapter/docs/launcher amended to match reality.
