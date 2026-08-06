# 04 — In-place relaunch via /clear (third ROLLOVER_RELAUNCH mode)

Status: open — future consideration, not scheduled · raised 2026-08-06
(brainstorm with user; deliberately parked)

## Idea

Instead of launching a new process, the successor could be the *same* CLI
process after `/clear`: rollover write phase runs unchanged (handoff.md +
next-session.md + bootstrap prompt), then the user runs `/clear` and pastes
the bootstrap prompt into the cleared window. Context-hygiene-wise this is
equivalent to a fresh launch — everything the mechanism preserves lives on
disk, and `/clear` wipes the window just as thoroughly. Candidate spelling:
`ROLLOVER_RELAUNCH=in-place`.

## Why it's attractive

- No new terminal, no `--bg` confirmation poll, no MCP server reconnect.
- Launch flags (`--permission-mode`, `--model`, `--mcp-config`) carry over
  implicitly — the `.rollover-options` persist-and-replay step becomes
  unnecessary on this path.
- Arguably strictly better than today's `manual` mode for the common case.

## What it loses vs. a fresh launch (the analysis)

1. **Launch-config change point.** Rollover is the natural moment to shed a
   heavy MCP fragment, switch model, or change approval level — all
   launch-time flags. `/clear` locks the successor into the dying session's
   exact launch config.
2. **Lineage bookkeeping.** The launcher increments `.session-seq`, names the
   successor (`claude --name "proj #N"`), releases `.active-session`, stamps
   the dying registry record `superseded`, and confirms the successor's
   register. After `/clear` the process keeps its old `--name`, and — actual
   bug — the lock is still held by the *old* session ID while the register
   hook runs under the *new* one (Claude Code assigns a new session ID on
   `/clear`; SessionStart fires with `source: "clear"`). The register hook
   would need to recognize a clear-sourced session as heir to its own
   predecessor's lock.
3. **Hands-free auto mode.** The dying session cannot type after clearing
   itself, so a human must send the first message. A SessionStart(`clear`)
   hook could inject "read next-session.md" as additionalContext off a
   pending-rollover marker file, but a keystroke is still required.
4. **Runtime-agnosticism.** `/clear` is Claude-Code-specific; this can only
   be a claude-only fast path with per-runtime fallbacks (same caveat
   pattern as `--bg`).
5. **Process freshness.** A new process is the only thing that resets MCP
   server state / a wedged CLI. If rollover was triggered by weirdness
   rather than token count, `/clear` doesn't fix it.

## Sketch if picked up

Keep the write phase identical. Add a claude-only in-place path that:
(a) skips `.rollover-options` replay, (b) still advances `.session-seq` and
stamps the old record superseded *before* printing "now run /clear and paste
this", and (c) teaches the register hook that a `clear`-sourced session
inherits its own predecessor's `.active-session` lock.
