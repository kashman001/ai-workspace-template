# Postmortem: <short title of the incident>

- Date: YYYY-MM-DD <!-- day the incident started --> · Duration: <first symptom → resolved>
- Drafted by: <agent runtime> · Reviewed by: <human>

## Summary

Two or three sentences: what broke, how it was noticed, how it was resolved.

## Impact

What it cost — sessions of work lost, users reached, data or state affected.
Quantify where possible ("one session's handoff burned", "two downloaders hit it").

## Timeline

| Time (UTC) | Event | Source |
|---|---|---|
| YYYY-MM-DD HH:MM | <what happened or was observed> | <ledger / commit sha / log> |

## Contributing factors

Systems, sequences, and missing guardrails that let this happen — each one a
condition, not a person. "The check script had no test for X", never "Y forgot".


## What went well

Which existing guardrails, docs, or habits caught it or limited the damage.

## Actions

| Action | Owner role | Tracker link | Status |
|---|---|---|---|
| <fix, guardrail, or doc change> | <maintainer / adopter / agent> | <backlog card or issue> | open |

## Lessons → where they were recorded

- <durable gotcha> → `docs/operational-knowledge.md#<anchor>`
- <decision with a rejected alternative> → `work/<project>/decisions.md` or `docs/adr/`
