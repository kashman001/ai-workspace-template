---
name: jev
description: >-
  Ask Jev (TypeSafe's typed-question model) a Choice, Score, or Noul question
  about some state through `scripts/jev.sh`, and get a typed answer with a
  confidence instead of generated text. Use when a decision has closed
  options, many items to judge, a safe fallback for uncertain answers, and
  correctness confirmed elsewhere (routing, classification, ranking,
  yes/no checks). Never for prose or extraction. Without a key
  (`scripts/jev.sh --check` exits 3) do the work the current way.
---

# jev — typed questions through the one CLI

`scripts/jev.sh` is the only code in the workspace that knows Jev's endpoint
or key. Everything here is about using it well; `scripts/jev.sh --help` is
the contract (three worked examples, exit codes, key order, limits) and is
enough on its own for a simple call. Classifying records inside an `rlm` run
does not need this skill: the REPL's `classify()` helper already asks Jev
where a key is present (`skills/rlm/SKILL.md`).

## Steps

1. **Gate.** `scripts/jev.sh --check` — exit 0 means a key is present, exit 3
   means none. On 3, stop here and do the task the way you would without
   Jev; do not ask the user for a key.
2. **Shape the request.** One JSON object on stdin:

   ```json
   {"state": <any JSON>, "questions": {"<your key>": {"type": "choice|score|noul", "instructions": "...", "criteria": ...}}}
   ```

   - `state` is what every question is about: a string, or an array/object
     of records. Refer to parts of it in instructions with backticked paths
     (`` `records[3]` ``, `` `ticket.text` ``). Give enough context to answer.
   - Ask every independent question about the same state in **one** request;
     they run in parallel and cannot see each other's answers. A second
     request is warranted only when the next question depends on an answer.
   - Question keys are for your code; they are not sent to the model, so put
     the whole meaning in `instructions`.
   - **The state leaves the machine.** With a key, everything in `state` is
     sent to TypeSafe's servers; the vendor's compliance posture is
     unverified (one report of no SOC 2 attestation). Do not route personal
     or confidential records. To keep a corpus local on a keyed machine, run
     with `JEV_DISABLED=1`: the CLI takes the no-key branch (exit 3) and the
     caller does the task the current way.
3. **Pick the type** by what the answer means:

   | Need | Type | `criteria` | Answer `value` |
   | --- | --- | --- | --- |
   | one of a closed set | `choice` | `{label: description}`, ≤255 options | the chosen label, plus `confidence` |
   | degree on an ordered scale | `score` | array of 2–10 level descriptions, low → high | probability-weighted level (0 = first), plus `confidence` |
   | does a condition hold | `noul` | optional `{"true": ..., "false": ...}` | probability of yes; `confidence` is `null` |

   Several labels may apply at once → one `noul` per label, not a `choice`.
   Scale answers are the least reliable of the three in the one report we
   have (good agreement with a frontier model on Choice and yes/no, poor on
   1–5 scales, ungraded); when a level matters, prefer a `choice` over the
   levels or one `noul` per level.
   For batches of records, the rlm REPL's `classify` / `score` / `check`
   helpers build these requests for you (`skills/rlm/SKILL.md`).
4. **The `other` pattern.** A Choice can only pick from the options given, so
   when nothing may fit, add an explicit no-match option (`"other": "None of
   the above"`) and treat it as a real label in your code. Never let the
   model pick a wrong option because the right one was missing.
5. **Run it.** `printf '%s' "$REQ" | scripts/jev.sh` → one JSON line per
   answer, `{"key", "value", "confidence"}`. Branch on the exit code: `0`
   answered; `2` your request is malformed or breaks a limit (fix it,
   nothing was sent); `3` no key (the gate above); `4` the server refused
   (status and body head on stderr; `429` is rate limiting — back off, or
   fall back). Never print or store the key; the CLI never does.
6. **Threshold, then fall back.** Decide before reading answers what
   confidence you act on. Confidence measures how concentrated the answer
   distribution is, not whether the workflow is right. Below your threshold,
   send that item to the current way (a reasoning model, a person), never
   guess. The `rlm` helper uses `0.5` by default, tuned on two real runs
   (median confidence 0.52 on crisp categories, 0.26 on overlapping ones); a
   clean batch in the spike scored 0.89–1.0, so tune on your own data. A Noul near `0.5` means the
   model is undecided, not "medium".

Done when every answer either met the threshold and was acted on, or was
handed to the fallback, and no key string appears anywhere in your output.

## Limits and cost

- Per request: at most 255 options in one Choice; `state` plus the longest
  question under 32k tokens. The CLI refuses both before sending (exit 2);
  split the state into batches instead (the `rlm` helper uses 50 records per
  request).
- Rate: 250k tokens/s and 1,200 requests/min, `429` beyond. No SLA.
- Price: $42 per billion input tokens, output free (vendor terms, verified
  2026-09; the terms carry a "we can serve it profitably" qualifier). Each
  question re-sends the state it shares, so measure real request budgets.
- Model: `jev-latest` unless the request carries `"model"`. The listing
  (`GET /v1/models`) offers only `jev-latest` and `jev-preview`, no versioned
  ids — each carries a `release_date` (`jev-latest`: 2026-09-10). A threshold
  is tuned against one release; re-tune when that date changes.

## No-key contract

A missing key is a branch, never a failure. The CLI exits 3 with one stderr
line and nothing on stdout; every caller does the task the current way and
says nothing about Jev in its result. Key setup (personal, keychain only):
`docs/service-access.md` → "Jev (TypeSafe)".

## Further reading

- `scripts/jev.sh --help` — the CLI contract with a worked example per type.
- `typesafe-ai/SKILL.md` (beside this file) — the vendor's own agent skill:
  design patterns beyond classification, how to shape state and criteria,
  and pointers into the live docs at `docs.typesafe.ai`. Vendored, MIT, with
  provenance; listed in `skills/vendored-skills.md`.
- Test that proves the CLI without a live key: `scripts/tests/test-jev.sh`.
