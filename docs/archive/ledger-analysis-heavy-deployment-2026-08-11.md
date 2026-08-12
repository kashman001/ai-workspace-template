# Ledger Analysis — heavy deployment (Insight workspace), 2026-08-11

> Cross-deployment evidence imported from the Insight dev-ai workspace (this
> template's largest live deployment). Complements the local
> `ledger-analysis.md` (pass 2): that ledger's light sessions show 20–40K
> work units and 1–7K rollovers; this heavy-workflow ledger shows 50–130K
> units and ~20K rollovers — the rollover-skill trigger policy covers both.

Analysis of `work/context-decay/context-ledger.jsonl`: 181 records, 67
sessions, 2026-07-22 → 2026-08-11. Answers the README follow-up "analyze
accumulated ledger data" (growth per phase, hot workflows, estimate-mode
accuracy). Script used: session scratchpad `ledger_analysis.py` (throwaway;
stats reproducible with jq/python from the ledger).

## Coverage

- Runtimes: claude 60 records, copilot-vscode 121. **Zero** records from
  codex, gemini, copilot-cli, opencode — their adapters have never written a
  ledger entry on this machine.
- Method: 178 exact, 3 estimate (all early copilot-vscode, pre-exact-adapter).
  **The "is estimate-mode accuracy acceptable?" question is unanswerable from
  this ledger** — it needs a live gemini (or other estimate-mode) session.
- Status: 90 OK, 35 WARN, 56 STOP.

## Findings

### F1 — The WARN band is narrower than one work unit; WARN is usually skipped

Of 35 sessions that reached STOP, **22 (63%) never recorded a WARN** — they
jumped from OK straight past STOP. Cause: the WARN→STOP band is 30K
(120K→150K), but the largest observed single-checkpoint jumps are **58K–130K**
(R11 wave work units: implement+test+commit+bookkeeping). One work unit
routinely spans the whole band, so "WARN = finish the current unit, then roll
over" frequently means finishing at 160–230K.

### F2 — STOP overshoot is systematic

STOP records overshoot the 150K threshold by **median +17K, p75 +38K**;
working sessions regularly finish at 160–230K. (Max overshoot +443K is the
one-off 593K "context-window size query" session on copilot-vscode's much
larger window — outlier, excluded from interpretation.) On copilot-vscode's
~936K window this is tolerable; on claude's ~200K window a 180K+ finish is
inside compaction territory — and late-July claude sessions (s48–s60) show
exactly that: repeated finishes at 151K–183K.

### F3 — The rollover procedure itself costs ~20K tokens

Same-session `rollover start` → `rollover complete` deltas: 13 nonzero
measurements, **median 20K, range 4.5K–38K** (handoff + next-session +
launcher + ledger writes). A session that only *begins* rollover at STOP
(150K) therefore lands at ~170–190K. This quantifies why rollover must start
at WARN at the latest: WARN (120K) + one small closing unit + 20K rollover ≈
150–160K, which is the best the current thresholds can deliver.

(14 further deltas measured exactly 0 — all copilot-vscode, where
`promptTokens` flushes only when a turn's rounds complete, so back-to-back
records read the same value. Expected artifact, not an anomaly.)

### F4 — The ledger is rollover-skewed; mid-session cadence is not practiced

40 of 67 sessions have ≤2 records, and ~a third of all records are rollover
bookkeeping (`rollover start`/`rollover complete`). Most sessions record only
at the end, so per-phase growth curves are sparse: the "record at every
work-unit boundary" guidance is followed at session edges, not during the
working middle. This is also why F1 detection comes late — the first record
of the day is often already past WARN.

### F5 — Growth rate varies ~100×; time-based prediction is useless

Observed sustained rates span ~60 tokens/min (long sessions with idle gaps)
to ~12K tokens/min (dense claude bursts). Elapsed time predicts nothing;
work-unit count does: a hot R11 wave session gets **1–2 major units** between
fresh start and STOP. Checkpoint-per-unit remains the right trigger model.

### F6 — Flat-token sessions corroborate the frozen-pin signature

9 copilot-vscode sessions show identical token counts across every record
(3–5 records over hours). These are a mix of the (since-fixed) stale-pin bug
era (e.g. `5edc1b84`, `ca080066` from s76) and flush lag. The "frozen
`tokens=` across records = stale pin" detection heuristic in repo memory is
confirmed by the ledger; with the hook auto-registration fix (commit 27010c7)
new flat sessions should become rare — worth re-checking in a future pass.

## Recommendations

- **R1 (adopt): pre-flight check before starting a major unit.** The
  effective rule the data supports: at a work-unit boundary, if
  `tokens + typical-unit-cost (≥50K for wave-scale units) > threshold`, roll
  over **before** starting the unit, not after finishing it. Candidate edit:
  `skills/session-rollover/SKILL.md` trigger section + the orchestrator
  skills that launch wave-scale units.
- **R2 (adopt): treat WARN as "begin rollover", not "finish freely".** With a
  ~20K rollover cost (F3) and 50K+ units (F1), WARN leaves room for one
  *small* closing unit only. Wording change in the same skill.
- **R3 (keep open): estimate-mode accuracy** — blocked on a live gemini
  session (telemetry wiring is the standing follow-up).
- **R4 (optional): mid-session record cadence** — the hooks already measure
  every SessionStart/Stop; the gap is *ledger* records mid-session. Low cost:
  skills that own long phases could add a `record --label` step at phase
  boundaries.

**Applied (2026-08-11):** R1 and R2 are integrated into
`skills/session-rollover/SKILL.md` → "When to invoke" (pre-flight bullet +
WARN small-unit qualifier). R3 stays open (gemini follow-up); R4 left
optional — the per-skill phase-boundary `record` calls can be added
opportunistically as those skills are next touched.
