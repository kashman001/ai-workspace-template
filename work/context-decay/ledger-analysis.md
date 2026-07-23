# Ledger Analysis — 2026-07-23 (19 entries, 4 sessions) — pass 2

Second periodic pass over `context-ledger.jsonl`. All entries still
`method=exact`, runtime=claude. Pass 1 (2026-07-22, 6 entries) conclusions
are re-confirmed below with 3× the data; new findings start at #4.

## Findings

1. **Baseline confirmed: sessions register at ~42–51K** (S3/S4: 41.6K;
   S2: ~50.9K) — 28–34% of the 150K STOP. Effective working budget between
   register and WARN(120K) is ~70–78K. Unchanged from pass 1.
2. **Work-unit cost confirmed at ~20–40K** across 7 measured units: M9 +22K,
   gemini follow-up +39K, M10 +26K, M11+planning +28K, M12/L11/L12 batch
   +21K, L13 +35K, L11-remainder +40K. The 2–3-units-per-session rule of
   thumb holds; no unit has exceeded 40K.
3. **Rollover is consistently cheap: 1.2K / 6.3K / 6.7K / 2.9K** measured
   start→complete across all four sessions. Wrap-up bookkeeping before it
   (checkpoint, backlog, docs) costs more (4–27K observed). Budget for the
   bookkeeping, not the handoff.
4. **NEW — subagent fan-out decouples unit size from orchestrator growth.**
   The L11-remainder unit ran 2 research + 1 implementation subagents
   (~208K tokens in their own windows) yet grew the orchestrator only +40K —
   a unit that would have blown the session budget done inline. For big
   units, delegation is the budget lever.
5. **NEW — post-rollover continuation is the emerging leak.** S2 resumed
   across a day boundary (+13K before new work landed) and S4 kept working
   in the same session after `rollover complete` (user-driven). Rollover
   docs assume a fresh session; continuing re-burns the already-WARNed
   window. If continuation happens anyway, the SessionStart hook now
   re-registers on `/clear`-style boundaries, but the discipline remains:
   after rollover-complete, switch sessions.
6. **Threshold system: 4/4 sessions rolled over between WARN and STOP**
   (peaks 144.4K / 136.9K / 139.8K / 128.4K — trending earlier each
   session). No session has entered the dumb zone since go-live.
7. **Estimate-accuracy analysis still not possible** — zero
   `method=estimate` rows. Gated on a live Gemini (needs `GEMINI_API_KEY`)
   or Copilot session.

## Next analysis

Re-run after ~40 entries, the first non-claude/`method=estimate` rows, or
the first multi-runtime session — whichever comes first. Worth adding then:
estimate-vs-exact deltas and per-runtime baselines (spec §12).
