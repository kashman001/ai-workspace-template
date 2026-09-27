# 05 — UAT: the gated behaviour on a machine with a key and one without

**What to build:** The user runs `rlm` on a real corpus on the machine holding the key and sees labels with `confidence` and `source: jev`, with `check-service-access.sh` reporting the key present; then runs the same on a machine or shell with no key (or with the keychain entry temporarily renamed) and sees today's behaviour with nothing mentioning Jev. The "nothing changes without a key" promise is seen, not assumed.

**Blocked by:** 02 — `rlm` classification helper; 03 — Credentials docs and preflight; 04 — CLI widened, `jev` skill, always-on rule.

**Status:** ready-for-human

**Spec:** S20

- [ ] With the key: an `rlm` run on a real file returns labels with confidence and `source: jev` for most records; the per-batch time is visibly shorter than the leaf path; `scripts/check-service-access.sh` shows the key present
- [ ] Without the key (entry absent or renamed): the same run produces today's output and the transcript, audit package, and preflight mention nothing about Jev beyond "absent (optional)"
- [ ] The user records the observed fallback rate and any surprise in `work/jev-integration/decisions.md` or as a `plan.sh note` for ticket 06 to use
