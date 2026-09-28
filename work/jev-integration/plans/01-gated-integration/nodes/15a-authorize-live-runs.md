---
id: 15a-authorize-live-runs
title: Authorize node 15's two live Jev calls (second corpus run + model listing)
status: done
kind: hitl
wave: 7
blocked_by: [13-uat-gated]
sessions: [14]
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

- [x] Second run's confidence distribution recorded (as a `plan.sh note` or a line in `decisions.md`), with the corpus kind and record count
- [x] The versioned id behind `jev-latest` read from the listing and recorded the same way
- [x] A person marks this node done (`--by human`)

## Log
- s14 · the user authorized both in-session ("You have permission for both"); the agent ran them.
- s14 · run 2 (keyed, `threshold=0.0`, `jev-latest`): 100 ledger bullets from `work/*/handoff*.md` (`/tmp/jev-uat/ledger.txt`, recipe `leg2-keyed.py`), four categories built / verified / decided / blocked + `other`. 100/100 `source: jev`; confidence min 0.09 / median 0.26 / max 0.94; below 0.25: 41 %, below 0.5: 94 %, below 0.7: 98 %, below 0.9: 99 %; deciles 0.09 0.15 0.17 0.20 0.24 0.26 0.28 0.30 0.36 0.46 | 0.94. Jev counts: verified 52, blocked 23, decided 15, built 10. Two live requests, under a second.
- s14 · leaf leg on the same corpus (keyless stub, `claude -p haiku`, 31 s): leaf counts decided 31, built 29, other 17, verified 16, blocked 7. Agreement Jev vs leaf by Jev confidence: [0,0.25) 5/41 · [0.25,0.5) 14/53 · [0.5,0.7) 1/4 · [0.7,1] 2/2 · overall 22/100. Main confusion: Jev `verified` where the leaf said `built` (18) or `decided` (15). Confidence tracks agreement; these categories overlap (a bullet often records built + verified), which is what the low confidences report.
- s14 · model listing (`GET /v1/models`, HTTP 200): `{"models":[{"name":"jev-latest","description":"The latest iteration of TypeSafe's System One Model: Jev","release_date":"2026-09-10T18:38:01.391457+00:00"},{"name":"jev-preview","description":"A preview version of `jev-latest`: should be better in most ways","release_date":"2026-09-10T18:39:06.057655+00:00"}]}`. **There is no versioned id** — only the two aliases, each with a `release_date`. The pinnable identity is `jev-latest` + its release date.
- s14 · started, tier frontier
- human · done
