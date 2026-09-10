# Rollover-Cost Savings Validation — 2026-09-10

Closes the watch-mode mission in `next-session.md`: did R1–R5 (applied 2026-08-11,
`docs/archive/rollover-cost-analysis-2026-08-11.md`) move the rollover floor from
~10K to ~6–7K tokens? Ledger: `.context-budget/context-ledger.jsonl` (258 entries,
64 `rollover start`, 68 `rollover complete`, gate ≥45 passed at 68).

## Method

Replicates the archive doc's pairing. Rule (the doc left it implicit): entries sorted by
`ts`; each `rollover complete` is paired with the latest unconsumed `rollover start` in
the **same session id**; delta = complete.tokens − start.tokens. Pre/post cut = start
ts ≥ 2026-08-11T17:27Z (session `a9399f8d`, the first rollover after the R1–R5 commit).
Excluded: 1 zero-token flush artifact (`90710a32`, complete recorded as `tokens: 0` —
the same exclusion the archive made), 5 unpaired completes (no start in that session:
`7f7f9f78`, `e64a50f3`, `3608e2ab`, `071a7e63`, `7bf47eb7`) and 1 orphan start
(`96197d3b`, whose complete was recorded from the successor session `7bf47eb7`).
Result: 62 pairs, 35 pre / 27 post. Pre replication vs the archive: Aug 5–9 median
11.7K / p75 13.8K / max 23K here vs ~11K / 13.4K / 23K there (35 vs 36 pairs).

The ledger has no heavy/local field (all `runtime: claude`, `method: exact`); the archive's
"heavy" 20K figure came from a different deployment's ledger and is not re-measured here.
Work item is taken from the `rollover complete: <project>` label as the spread proxy.

## Results (tokens per rollover)

| slice | n | median | p25 | p75 | min | max |
|---|---|---|---|---|---|---|
| PRE (all, Jul 22 – Aug 9) | 35 | 10,814 | 8,031 | 13,316 | 1,224 | 22,962 |
| PRE Jul 22–30 | 5 | 6,275 | 2,923 | 6,475 | 1,224 | 6,739 |
| PRE Aug 5–9 | 30 | 11,668 | 9,120 | 13,830 | 2,724 | 22,962 |
| **POST (all, Aug 11 – Aug 31)** | **27** | **12,272** | **8,739** | **17,836** | 2,752 | 26,964 |
| POST Aug 11–13 | 20 | 11,424 | 8,516 | 14,900 | 2,752 | 24,316 |
| POST Aug 29–31 | 7 | 17,473 | 14,562 | 20,738 | 5,371 | 26,964 |

By work item (post): sdlc-ai-mapping n=10 median 9.7K; devex-review n=7 median 16.7K;
template-maintenance n=8 median 16.2K; context-decay n=2 (4.2K, 12.0K).
Share of rollovers ≤7K: pre 8/35 (23%), post 4/27 (15%).

## Outliers (post-change)

- Heaviest: `5be1c99f` 27.0K (Aug 29, start 160K), `49e1708f` 24.3K (Aug 12, start
  86K — user-requested, not at WARN), `14c2409d` 24.0K, `711e7a2d` 23.6K, `328ac939`
  23.3K (Aug 29, start 184K). All 3–5 min brackets; the cost is bookkeeping volume, not
  wall time.
- Lightest: `a5fb3cd9` 2.8K, `a9399f8d` 4.2K, `d53322a6` 5.4K, `87446e0c` 6.9K — the
  predicted floor is *reachable*, but only 4 of 27 rollovers landed there.
- Pre-change for comparison: top was `341dc811` 23.0K; the July sessions (1.2K–6.7K)
  remain the cheapest run in the ledger.

## Verdict

**The predicted ~10K → ~6–7K floor did not materialize.** Post-change median is
12.3K (n=27) vs 10.8K pre (n=35) / 11.7K in the directly comparable Aug 5–9 window —
flat to slightly worse, and the late-August template-maintenance rollovers are heavier
still (17.5K median). p25 moved 8.0K → 8.7K, so even the cheap quartile did not drop.
R1/R2/R5 could at most remove ~1.5–3K of mechanics; the data says the variable
reflect/flush part (R3/R4's target) dominates and was not tamed by prose discipline.

## Caveats

- Confounded by project mix: post-change sessions were review/fix-package sessions
  (devex-review, template-maintenance M-series) with more repos/PR traffic inside the
  bracket; sdlc-ai-mapping — the most homogeneous post set — is 9.7K median, below pre.
- Small n per slice; a 2K shift in medians is within the spread (p25–p75 ≈ 9K wide).
- The skill only shrank 12.1 → 9.2KB (~700 tokens), not to the ≤7KB target, so the
  mechanical saving applied was smaller than modelled.
- Delta counts everything between the two `record` calls, including commits, PR work and
  user exchanges — it measures the bracket, not the procedure in isolation.
- Script: scratch `rollover_cost.py` (not committed); re-run against the ledger to refresh.
