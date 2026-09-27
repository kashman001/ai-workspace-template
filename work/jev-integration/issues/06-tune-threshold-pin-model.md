# 06 — Tune the confidence threshold on real runs and pin the model id

**What to build:** The threshold constant in the `rlm` helper is a number chosen from real runs (the fallback rate the user accepts), the model id is pinned to the versioned id that the threshold was tuned on, and the `rlm` and `jev` skills state both. Requires a key, so it runs on the keyholder's machine after UAT.

**Blocked by:** 05 — UAT: the gated behaviour.

**Status:** ready-for-agent

**Spec:** S13, S21

- [ ] The versioned model id behind `jev-latest` is read from the API's model listing and pinned in the one constant; `jev-latest` remains selectable by env override
- [ ] The threshold constant is set from the distribution of confidences on at least two real `rlm` runs (recorded as a decision note with the observed fallback rate and the rejected values)
- [ ] `skills/rlm/SKILL.md` and `skills/jev/SKILL.md` state the pinned id, the threshold, and that thresholds are version-sensitive (re-tune when re-pinning)
- [ ] `scripts/tests/test-jev.sh` still passes (the fixtures name the pinned id)
