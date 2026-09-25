# Live spike — 2026-09-24 (session 6)

**Why this exists.** The wave-1 research ran under R0.4 (no account), which left
four facts open in `synthesis.md` §5: sign-up (terms O29), enforced schema
limits (integration-paths O21), latency from this machine, calibration. On
2026-09-24 the user opened an account and stored the key in the macOS keychain
as `jev-api-key` (`security find-generic-password -s jev-api-key -w`), lifting
R0.4 for the orchestrator only. This file records the four probes run with it.
Script: `spike.py` (reads the key from the keychain; never prints it).
Raw research records (`*/record.md`, `pass/`, `fact-check.md`) untouched.

## Results

| # | Probe | Result |
|---|---|---|
| 0 | `GET /v1/models` with the key | 200 in 0.36s; aliases `jev-latest`, `jev-preview` (release_date 2026-09-10). **O29 closed: sign-up works, key authenticates.** |
| 1 | rlm-shaped batch: `state` = array of 5 records, 5 Choice questions each referencing `` `records[i]` ``, criteria {bug, enhancement, question, other} | 200 in **0.64s**; `model: jev-1.13.0`; usage 780 in / 230 out (≈ $0.00003). Labels: bug, enhancement, question, other, bug. `confidence` 1.0 / 1.0 / 0.98 / 0.89 / 0.99; `other` chosen for the newsletter record at 0.92 probability. Confirms what-jev-is C28 / integration-paths 6.2 (batch-as-state) end to end. |
| 2 | single-record Choice | 200 in 0.38s (bug, 1.0). Batch of 5 costs ~0.26s more than one — per-record cost amortises. |
| 3 | 256 options (docs cap 255) | **400** `{"detail":"Too many choices. Must have at most 255 choices."}` — the cap is server-enforced (note: 400, not the 422 the docs list for schema failures). **O21 partially closed** for the option cap. |
| 4 | `instructions` omitted (docs: required; spec: optional — 5.12-spec-spread) | **200** (enhancement, 1.0) — the server follows the OpenAPI spec, not the docs page. Resolves the 5.12 spread in the spec's favour at runtime. |

## Baseline: the current rlm runtime on the same five records

`claude -p --model haiku` (the `RLM_SUB_MODEL` default, `skills/rlm/scripts/rlm_repl.py:82`),
one prompt, five records, "index: label" output: **4.83s wall**, identical five
labels, no confidence, labels regex-parsed. Uncontended, single call, this machine.

| | Jev batch-of-5 | `claude -p haiku` |
|---|---|---|
| Wall time | 0.64s | 4.83s |
| Labels | same 5 | same 5 |
| Confidence | per record, thresholdable | none |
| `other` | explicit option, chosen once | prompt-instructed, chosen once |

Not measured: calibration beyond one batch (5 records is not an eval);
behaviour under the 16-way pool contention that C50 caveats; 429 behaviour.
