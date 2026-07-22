# Ledger Analysis — 2026-07-22 (6 entries, 2 sessions)

First periodic pass over `context-ledger.jsonl` (spec §12 follow-up). Small
sample; treat as directional. All entries `method=exact`, runtime=claude.

## Findings

1. **Session baseline is ~50K tokens — a third of the STOP budget.** The
   follow-up session registered at ~50.9K before any work (system prompt +
   global/project CLAUDE.md + skills listing). Effective working budget between
   register and WARN(120K) is therefore ~70K, not 120K.
2. **A work unit costs ~20–40K tokens.** Observed: M9 bug fix (diagnose, fix,
   backlog, commit) +22K; Gemini telemetry follow-up (docs lookup, config,
   adapter, fixtures, docs, commit) +39K. Rule of thumb: **2–3 work units per
   session**, then roll over.
3. **Wrap-up/bookkeeping is not cheap; the rollover itself is.** In the build
   session, the "implementation complete" bookkeeping phase cost ~27K
   (111.6K→138.5K), while the measured rollover (start→complete) cost only
   ~1.2K. Budget for the bookkeeping, not the handoff.
4. **The WARN threshold worked as designed twice.** Build session: hook WARN at
   124.8K, rollover completed at 144.4K — under STOP with ~6K to spare.
   Follow-up session: deliberate wrap at ~112K before WARN. No session has
   entered the dumb zone since the system went live.
5. **Estimate-accuracy analysis is not yet possible** — no `method=estimate`
   entries exist. Needs a Gemini/Copilot session to land estimate rows.

## Next analysis

Re-run after ~20 entries or the first non-claude rows. Worth adding then:
tokens-per-label clustering and estimate-vs-exact deltas (spec §12).
