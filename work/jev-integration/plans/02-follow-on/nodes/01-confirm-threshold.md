---
id: 01-confirm-threshold
title: Ticket 08 — Confirm 0.5 on the crisp commit corpus
status: done
kind: work
wave: 1
blocked_by: []
check: grep -q 'S22' decisions.md
sessions: [18]
---

## Goal

Ticket: issues/08-confirm-threshold-crisp-corpus.md
Spec: S22, S30

No code. One paid batch: regenerate 100 commit subjects (`git log --format=%s -n 100`), run `classify()` keyed at `threshold=0.0` with the s13 categories, run the leaf leg with the s13 pass-through keychain stub (fails only `jev-api-key`), then tabulate leaf agreement by Jev confidence bucket `[0,0.25)`, `[0.25,0.5)`, `[0.5,1]`. Apply the rule fixed at the grill (2026-09-28, Q1a): **keep 0.5 if agreement in `[0.5,1]` ≥ 2× agreement in `[0.25,0.5)`, else move to the lowest bucket boundary where that holds.** Write the tenth decision note with the table, the verdict, and the cost (S30). If the verdict is "move", change `DEFAULT_JEV_THRESHOLD` and the fixture `choice-batch.json` r3 so T8i still exercises the fallback, and re-run `test-jev.sh`. Corpus and scripts live under the scratchpad, never checked in.

Read first: `decisions.md` (s13 UAT note for the recipe, eighth note for the run-2 table), `skills/rlm/SKILL.md`, `docs/service-access.md` (spend line), `docs/plans.md` (Log stamp for cost).

Paid batch: run by the agent on the keyed machine (spend pre-authorized 2026-09-28); cost goes in this Log (S30). Never a bare `scripts/jev.sh` run outside the batch intended; `JEV_DISABLED=1` for any dry run. Scratch under the session scratchpad, never checked in.

## Acceptance

- [x] Corpus regenerated (100 subjects), keyed run at `threshold=0.0` → 100 `source: jev` with confidences
- [x] Leaf leg with the pass-through stub → 100 `source: leaf`, nothing mentioning Jev
- [x] Agreement-by-bucket table (counts and rates per bucket) in the tenth decision note, with the pre-registered rule quoted and the verdict stated as keep/move
- [x] Cost of the batch recorded in the note and the node Log
- [x] If "move": constant + fixture + skills updated, `test-jev.sh` passes; if "keep": no code touched

## Log
- s18 · started, tier standard
- s18 · keyed leg: 100 subjects, 2 requests, 100/100 source: jev, confidence min 0.15 / median 0.54 / max 1.0; leaf leg via pass-through security stub 100/100 source: leaf, 78 s, 0 mentions of jev; scratch in session scratchpad jev-s18/n01/ (commits.txt, keyed.json, leaf.json, leg.py), not checked in
- s18 · bucket table [0,0.25) 8/15 · [0.25,0.5) 16/20 · [0.5,1] 49/65 · overall 73/100; pre-registered 2× rule fails at 0.5 AND at 0.25 → no destination → verdict keep (rule inconclusive), no code touched; S22 note appended to decisions.md (eleventh note by count; tickets call it the tenth). Cost ≈ $0.0007 (≈17.5k est. input tokens at $42/B). Finding for the goal-level close: 0.25 would type 85 vs 65 records at the same 0.75 agreement
- s18 · check passed → done
