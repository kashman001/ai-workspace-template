---
id: 15-tune-and-pin
title: Ticket 06 — Tune the confidence threshold and pin the model id
status: todo
kind: work
wave: 7
blocked_by: [13-uat-gated, 15a-authorize-live-runs]
check: bash "$WORKSPACE_ROOT/scripts/tests/test-jev.sh"
sessions: []
---

## Goal

Ticket: issues/06-tune-threshold-pin-model.md
Spec: S13, S21

The threshold constant in the `rlm` helper is a number chosen from real runs (the fallback rate the user accepts), the model id is pinned to the versioned id that the threshold was tuned on, and the `rlm` and `jev` skills state both. Requires a key, so it runs on the keyholder's machine after UAT.

## Acceptance

- [ ] The versioned model id behind `jev-latest` is read from the API's model listing and pinned in the one constant; `jev-latest` remains selectable by env override
- [ ] The threshold constant is set from the distribution of confidences on at least two real `rlm` runs (recorded as a decision note with the observed fallback rate and the rejected values)
- [ ] `skills/rlm/SKILL.md` and `skills/jev/SKILL.md` state the pinned id, the threshold, and that thresholds are version-sensitive (re-tune when re-pinning)
- [ ] `scripts/tests/test-jev.sh` still passes (the fixtures name the pinned id)

## Log
- s14 · prep (keyless, at the wave 6 join): edit sites once 15a lands — `skills/rlm/scripts/rlm_repl.py` lines 92–96 (`DEFAULT_JEV_THRESHOLD` default "0.9", `DEFAULT_JEV_MODEL` default "jev-latest", and the two comment lines above them); `skills/rlm/SKILL.md` lines 176–182 (threshold guidance — the 0.9 default and the "leaf share well above a few percent" sentence are contradicted by the UAT: 90 % below 0.9 is the normal case on prose-like records) and 292–293 (knobs; add the pinned id + "re-tune when re-pinning"); `skills/jev/SKILL.md` line 81 (Model bullet: pinned id, threshold, version-sensitive); `scripts/jev.sh` keeps `jev-latest` as its own default (the CLI is untyped about threshold; S13 pins in the rlm constant — env override `RLM_JEV_MODEL=jev-latest` stays selectable). Tests: fixtures `scripts/tests/fixtures/jev/*.json` and T2b/T9e use the placeholder id `jev-1.13.0` → replace with the listed id; T1g/T8h assert the default and must follow the new constant. Candidates from run 1 (sixth note): 0.5 (≈ median, half typed) and 0.25 (≈ min, nearly all typed); decide after run 2's distribution, record both distributions + rejected values as a Tier-2 note. `llm_query` and the T14 golden stay untouched.
