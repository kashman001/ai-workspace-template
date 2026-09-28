---
id: 13-uat-gated
title: Ticket 05 — UAT: gated behaviour with a key and without
status: done
kind: hitl
wave: 6
blocked_by: [09-rlm-classify, 10-credentials-docs, 11-cli-skill-rule]
sessions: [13]
---

## Goal

Ticket: issues/05-uat-gated-behaviour.md
Spec: S20

The user runs `rlm` on a real corpus on the machine holding the key and sees labels with `confidence` and `source: jev`, with `check-service-access.sh` reporting the key present; then runs the same on a machine or shell with no key (or with the keychain entry temporarily renamed) and sees today's behaviour with nothing mentioning Jev. The "nothing changes without a key" promise is seen, not assumed.

A person marks this done (`plan.sh done 13-uat-gated --by <name>`); the chain pauses here with `--loop-mode interactive`.

## Acceptance

- [ ] With the key: an `rlm` run on a real file returns labels with confidence and `source: jev` for most records; the per-batch time is visibly shorter than the leaf path; `scripts/check-service-access.sh` shows the key present
- [ ] Without the key (entry absent or renamed): the same run produces today's output and the transcript, audit package, and preflight mention nothing about Jev beyond "absent (optional)"
- [ ] The user records the observed fallback rate and any surprise in `work/jev-integration/decisions.md` or as a `plan.sh note` for ticket 06 to use

## Log
- s13 · started, tier frontier
- human · done
