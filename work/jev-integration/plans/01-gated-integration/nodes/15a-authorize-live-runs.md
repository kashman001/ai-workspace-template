---
id: 15a-authorize-live-runs
title: Authorize node 15's two live Jev calls (second corpus run + model listing)
status: todo
kind: hitl
wave: 7
blocked_by: [13-uat-gated]
sessions: []
---

## Goal

Node 15 (tune the threshold, pin the model id) needs two live calls against
the real Jev API with the key in this machine's keychain. Both cost money
(cents) and both are the user's to trigger — the standing constraint is that
`scripts/jev.sh` never runs live from a session without `JEV_ENDPOINT` on the
test stub unless the user asked. This node is that ask; a hands-off chain
pauses here (`--loop-mode interactive`).

**Request 1 — a second keyed `rlm` run, different corpus.** In a session
where you are present, say "run the second leg" and the agent runs `rlm` with
`classify(records, categories, question=..., threshold=0.0)` on ~100 records
that differ in kind from the first run's commit subjects — e.g. the issue
titles under `work/*/issues/*.md` or ledger bullets from `work/*/handoff.md` —
and prints the confidence distribution (min / median / max, share below 0.25,
0.5, 0.9). Recipe: `/tmp/jev-uat/leg-keyed.py` with a new `content` and
categories; regenerate `/tmp/jev-uat/` from the sixth note in `decisions.md`
if `/tmp` was cleared. One request of 50 records is ~2 batches; cost is cents.

**Request 2 — read the versioned id behind `jev-latest`.** One `GET` on the
model listing (`GET https://api.typesafe.ai/v1/models`, Bearer key —
`research/synthesis.md` line 16; the response shape is not in the research,
so read it as it comes). A one-off command, not a workspace script
(`scripts/jev.sh` stays the only code that knows the endpoint):

    curl -sS -H "Authorization: Bearer $(security find-generic-password -s jev-api-key -w)" \
      https://api.typesafe.ai/v1/models | jq .

The key goes straight into the header and is never printed or written.

Then mark this node done (`scripts/plan.sh done 15a-authorize-live-runs --by human --project jev-integration`); node 15 sets the constants from the two distributions and the listed id.

## Acceptance

- [ ] Second run's confidence distribution recorded (as a `plan.sh note` or a line in `decisions.md`), with the corpus kind and record count
- [ ] The versioned id behind `jev-latest` read from the listing and recorded the same way
- [ ] A person marks this node done (`--by human`)

## Log
