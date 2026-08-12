# Rollover Cost Analysis — 2026-08-11

Answers the cross-deployment question raised by the heavy deployment's F3
(`ledger-analysis-heavy-deployment-2026-08-11.md`): the rollover procedure
itself costs ~20K tokens median there — where does it go, and how do we cut
it? Sources: the local ledger (36 paired `rollover start`→`rollover complete`
deltas, 2026-07-22 → 2026-08-09; one 0-token flush artifact excluded), the
heavy deployment's F3 (median 20K, range 4.5K–38K), git history of
`skills/session-rollover/SKILL.md`, and on-disk artifact sizes.

## Findings

### F1 — Local rollover cost tripled between July and August

- July 22–23 (the pass-2 "rollover is consistently cheap" era): 1.2K / 6.3K /
  6.7K / 2.9K — median ~4.6K.
- Aug 5–9 (32 pairs): **median ~11K, p75 ~13.4K, max 23K**.

The heavy deployment's 20K median is not a different phenomenon — it is the
same cost curve further along (bigger work units, more repos, more deferred
bookkeeping inside the bracket). `ledger-analysis.md` finding 3 ("rollover is
consistently cheap: 1–7K") is **stale** and should not be relied on.

### F2 — Cost growth tracks procedure growth

`skills/session-rollover/SKILL.md` grew **4.6KB → 12.1KB (~1.2K → ~3.2K
tokens loaded per rollover)** across the same window:

| date | commit | size | added |
|---|---|---|---|
| 07-22 | 3c7b44a | 4.6KB | initial system |
| 08-05 | 91e3e32 | 5.7KB | promotion scan, verification, boundary arbitration |
| 08-06 | e0cb70d | 7.7KB | `.rollover-options` capture/inheritance |
| 08-06 | 1a3fa5b | 10.0KB | session-seq counter-sync canon (ADR-0007) |
| 08-10 | 3ffcf5a | ~11KB | block-marker hazard guardrail |
| 08-11 | 6a6f1fa | 12.1KB | ledger-evidence trigger policy |

The steps added in that window (options capture, counter sync, launcher
invocation, learnings sweep, archive discipline) each add tool calls: a
rollover now runs ~8–10 round-trips minimum vs ~4–5 in July. The procedure
got more correct and more expensive together.

### F3 — Cost anatomy: ~8–10K mechanical floor + 0–25K deferred bookkeeping

Estimated from artifact sizes and the step list (per-step, tokens):

| component | cost | notes |
|---|---|---|
| skill load | ~3.2K | 12.1KB SKILL.md, every rollover |
| handoff.md block | 1.5–3K | read top block + compose new block (+ archive rotation when triggered) |
| next-session.md replace | 0.8–1.5K | full rewrite by contract |
| flush: git status / commit | 1–3K | scales with repos touched |
| options capture + counter sync + launcher + 2 `record` calls | 1–1.5K | ~5 small round-trips |

Floor ≈ 8–10K — which is exactly the current local median. Everything above
it is the **reflect/flush variable part**: routing learnings, settling
decisions, committing, verifying sub-agent outputs. Pass-2's "budget for the
bookkeeping, not the handoff" still holds, but the bookkeeping has since been
*formalized into* the rollover steps (2–3), so it now lands inside the
start→complete bracket — that is most of the light-vs-heavy gap (11K vs 20K).

### F4 — Reference-graph trap: `docs/context-budget.md` is ~11K tokens

The skill points to `docs/context-budget.md` (44.6KB) twice. One follow of
that pointer costs more than the entire mechanical floor. Unverifiable from
ledger data whether heavy sessions do this, but it is the single largest
one-read cost reachable from the skill, and nothing in the skill says *don't*.

### F5 — The cost lands in the worst place, by design

The floor is paid past WARN (120K+), where every token is scarcest — that is
inherent to rollover. The successor's side is already cheap by design
(launcher + top handoff block ≈ 1K); the asymmetry is correct, the floor is
the optimizable part.

## Recommendations

- **R1 (adopt): one-shot mechanics script.** A `rollover-prep` mode (in
  `scripts/context-budget.sh` or a sibling script) that in ONE round-trip:
  records the start entry, emits a compact git-status summary + the current
  top handoff block + the session-seq value, runs
  `capture-rollover-options.sh`, and performs archive rotation with anchored
  matching. Collapses ~5 tool calls into 1 and deletes the block-marker
  hazard class entirely (the ~20-line guardrail prose in step 4 becomes a
  script invariant). Est. saving 1.5–3K/rollover + skill shrink (see R2).
- **R2 (adopt): slim the skill's always-loaded payload.** Move the
  counter-sync canon detail, block-marker hazard, and lock-release mechanics
  into the R1 script (comments/output) or a demand-loaded reference file;
  the skill keeps one-line pointers. Target ≤7KB (≈ −1.5K tokens every
  rollover, every deployment).
- **R3 (adopt): promote write-ahead from WARN-declined fallback to default
  discipline.** Route learnings/decisions at incident time and pre-draft the
  handoff block incrementally at work-unit boundaries; rollover's steps 2–3
  become a sweep. The July sessions that worked this way rolled at 1–7K.
  This is the biggest lever for heavy workflows — their 20K is mostly
  deferred bookkeeping, not handoff writing.
- **R4 (adopt): cap the handoff block.** Contract: pointers over prose,
  ≤ ~40 lines per block. A fat block is paid twice — composed by the dying
  session, read by the successor.
- **R5 (adopt, one line): "do NOT load `docs/context-budget.md` during
  rollover"** in the skill — it is self-sufficient; the doc is for setup and
  debugging.
- **R6 (declined-adjacent, note only):** the successor's register baseline
  (42–51K) dwarfs all rollover artifacts combined; per the 2026-08-07 user
  decision (`decisions.md`, `trim-estimates.md`) standing-context trims are
  declined — do not reopen from this analysis.

Expected effect of R1+R2+R5 on the mechanical floor: ~10K → ~5–6K. R3/R4
attack the variable part, which is what separates 11K local from 20K heavy.

**Applied (2026-08-11, user-approved):** R1 shipped as
`scripts/rollover-prep.sh` (+ `scripts/tests/test-rollover-prep.sh`, 28
green); R2–R5 integrated into `skills/session-rollover/SKILL.md` — 12,074 →
9,222 bytes (~−700 tokens/rollover; the ≤7KB target was not reached because
the heavy deployment's evidence-based trigger policy was preserved on top).
R3 landed as a standing write-ahead discipline paragraph; R4 as the ≤40-line
block contract in step 4; R5 as the self-sufficiency note in the intro.
Follow-up: compare predicted vs actual on the next real rollovers' ledger
deltas (see launcher open item).
