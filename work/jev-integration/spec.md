<!--
Effort-level spec for work/jev-integration/ — distinct from root SPEC.md
(product-level Z0). Convention: docs/agents/issue-tracker.md → "Spec conventions".
Written by plan 01-gated-integration node 05 (session 8, 2026-09-27) from the
approved fit note (decisions.md, 2026-09-27) and the session-7 design input.
-->

# Spec — jev-integration: Jev at the `rlm` leaf seam, gated on access

Status: approved         <!-- draft | in-review | approved -->
Approved-by: Kashif Siddiqui (2026-09-27, session 16)
Date: 2026-09-27
Spec-of-record: —

## Problem Statement

The `rlm` skill classifies tens to hundreds of records per run by asking a
generative sub-model, one free-text prompt per 50-record batch, and parsing
`N: label` lines back out with a regex. The root declares the category list,
but the leaf gives no confidence, has no way to say "none of these", and takes
seconds per batch. Jev (TypeSafe's typed-decision API) answers exactly that
shape of question — a caller-declared closed set, one typed answer plus a
probability per item — in well under a second per batch (`research/spike.md`:
0.64s against 4.83s on the same five records, identical labels). But Jev needs
a paid key that template downloaders and the other runtimes do not have, has
no SLA, and may rate-limit or reprice. The template must gain the faster,
confidence-bearing leaf where a key exists without changing anything for
everyone else.

## Solution

One seam, gated on access. A small CLI (`scripts/jev.sh`) is the only thing
that talks to Jev: it reads the key from the OS keychain, POSTs a typed
request, prints typed answers with confidence, and exits with a reason code —
not an error — when there is no key. The `rlm` REPL gains a typed
classification helper beside `llm_query`: with a key it sends each batch of
records as one Jev request (one Choice per record, the root's categories plus
an explicit `other`) and falls back per record to the current sub-model
below a confidence threshold; without a key it takes the current path,
unchanged and silent. One always-on rule in the workspace context tells any
runtime when to reach for the CLI; a demand-loaded skill carries the detail.
Docs, the service-access check, and an offline test that proves both paths
without a live key make it a first-class template addition.

## User Stories (requirements — stable IDs, never renumber)

The gate:

- **S1** — As a person with `jev-api-key` in the OS keychain, I want `rlm`
  classification to run through Jev automatically, so that runs are faster
  and every label carries a confidence.
- **S2** — As a downloader or a user of any runtime without a key, I want
  `rlm` to behave byte-for-byte as it does today, with the absent key neither
  logged as an error nor mentioned, so that the template stays credential-free
  and nothing I see changes.

The CLI:

- **S3** — As an agent in any runtime (Claude Code, Codex, Gemini, OpenCode,
  Copilot), I want a CLI on the workspace path that reads the key from the
  keychain itself, so that I never handle the key and no runtime-specific
  plugin is needed.
- **S4** — As a caller, I want to pass a `state` and one or more questions and
  get back each answer's typed value and confidence in a machine-readable
  form, so that I can threshold and branch on them in code.
- **S5** — As an agent, I want `--help` to teach the three question types
  (Choice, Score, Noul) with one worked example each, so that I can use the
  CLI correctly without loading a skill.
- **S6** — As a caller without a key, I want a distinct exit code and a
  one-line reason on stderr, with nothing on stdout, so that "no key" is a
  branch, never a failure.
- **S7** — As a caller, I want the CLI to refuse a request that breaks Jev's
  published limits (more than 255 Choice options; state plus the longest
  question over 32k tokens) before sending it, and to report a 429 or other
  non-200 as its own exit code with the status and body head, so that limit
  and vendor failures are visible and distinguishable.
- **S8** — As an operator, I want the CLI never to print, log, or write the
  key anywhere, so that a transcript or audit package can never leak it.

The `rlm` seam:

- **S9** — As the `rlm` root, I want a typed classification helper that takes
  records and a category list and returns one label per record with a
  confidence and a source (`jev` or `leaf`), so that the semantics stay
  declared by me and the bookkeeping stays in Python.
- **S10** — As the `rlm` root with a key, I want each batch of up to 50
  records sent as one Jev request — `state` is the record array, one Choice
  question per record referencing `` `records[i]` ``, my categories plus an
  explicit `other` — so that a run costs one request per batch, not one per
  record, and a record that fits nothing is labelled `other` instead of
  forced into a category.
- **S11** — As the `rlm` root, I want any record whose Jev confidence is below
  a threshold re-asked through the current sub-model leaf, so that low
  confidence degrades to today's behaviour rather than to a wrong label.
- **S12** — As the `rlm` root, I want batches sized so that `state` plus the
  longest question stays under the 32k-token limit, splitting a 50-record
  batch when records are long, so that an oversize batch never fails a run.
- **S13** — As the `rlm` root, I want the model alias `jev-latest` by default
  with one place to pin a versioned id, so that thresholds tuned on one
  version are not silently invalidated by the next.
- **S14** — As an agent driving `rlm`, I want the skill's instructions to tell
  me to include `other`, how to pick a threshold, and how to read the
  `source` field, so that I write the root code correctly on the first try.

Credentials, checks, and docs:

- **S15** — As a person adding a key, I want the service-access doc to carry a
  Jev entry (key name, per-OS keychain read, verify command, cost and limits)
  and the authentication runbook a step for adding the key, so that setup is
  documented like every other service.
- **S16** — As an operator, I want the service-access preflight to report the
  Jev key as present or absent as an optional service, never its value and
  never failing the check when absent, so that a machine without Jev is
  still "ok".
- **S17** — As an agent in any runtime, I want one always-on rule (under 100
  tokens) in the workspace context saying when to use the CLI — closed
  options, many items, a safe fallback, correctness confirmed elsewhere;
  never for prose or extraction; no key means the current way — so that the
  capability is found without a standing cost.
- **S18** — As an agent that has decided to use Jev, I want a demand-loaded
  skill carrying the request shape, the `other` pattern, threshold guidance,
  and the limits, with TypeSafe's own agent skill vendored beside it with
  provenance, so that the detail is one load away and refreshable.

Proof and tuning:

- **S19** — As a maintainer, I want one test that proves both paths with no
  live key — no key: the `rlm` helper's output is identical to the current
  path; key present: the request the CLI sends to a stub endpoint has the
  documented shape and the answers are parsed back — so that the seam cannot
  regress unnoticed on any machine, including CI.
- **S20** — As the user, I want to confirm the gated behaviour on a machine
  with a key and on one without before the integration is called shipped, so
  that the "nothing changes without a key" promise is seen, not assumed.
- **S21** — As the user, I want the threshold tuned on real runs and the model
  id pinned once it is, so that the fallback rate is a number I chose.

## Implementation Decisions

- **One vendor surface: the CLI.** `scripts/jev.sh` (POSIX shell wrapping a
  Python `urllib` call, the same dependency set as the spike; no SDK) is the
  only code that knows the endpoint, the header, or the key. The `rlm` helper,
  the skill, and any future seam call the CLI. It follows the CLI-first rule
  in the workspace context: zero standing context, every runtime.
- **Key resolution.** In order: an environment override (`JEV_API_KEY`,
  for the offline test and for hosts with no keychain; documented as such,
  never a `.env` file), then the OS keychain — macOS
  `security find-generic-password -s jev-api-key -w`; Linux
  `secret-tool lookup service jev-api-key`; other hosts the env override.
  An endpoint override (`JEV_ENDPOINT`) exists for the stub; the default is
  the live URL from the spike. `JEV_DISABLED=1` short-circuits resolution:
  the CLI takes the no-key branch (exit 3, keychain not read) so a keyed
  machine can keep one corpus local (ticket 07, 2026-09-27).
- **Exit codes.** `0` answered; `2` usage or a client-side limit refusal
  (before any request); `3` no key (one stderr line, empty stdout); `4`
  non-200 from the server (status and the first 300 bytes of the body on
  stderr). The key never appears in any output.
- **Wire shape** (from the spike, which is the prototype here): request
  `{state, model, questions}`; a question is
  `{type: choice|score|noul, instructions, criteria}`; `criteria` for
  Choice is `{label: description}`; a Choice answer is
  `{choice, probabilities, confidence}`, Score `{score, legend,
  probabilities, confidence}`, Noul `{noul}` with no confidence. The CLI
  passes questions through as given and prints the `answers` map as JSON,
  one line per answer key with the typed value and confidence where present.
- **The `rlm` swap point is a new helper, not a change inside `llm_query`.**
  `classify(records, categories, threshold=None)` is added to the REPL
  helpers beside `llm_query` and `llm_query_map`. `llm_query` itself is
  untouched: Jev cannot generate text, so it can never stand in for a
  free-text leaf, and a prompt-sniffing swap would be fragile. Without a key
  the helper builds the same `N: label` prompt the skill teaches today and
  runs it through `llm_query_map`, so its no-key output is what a root would
  have produced by hand. Recorded as a Tier-2 note in `decisions.md`.
- **Batching.** 50 records per request, split further when the estimated
  tokens of `state` plus the longest question exceed the 32k limit (the CLI
  refuses independently; the helper sizes first). Each record's question
  references `` `records[i]` `` in its instructions. `other` is appended to
  the caller's categories with a fixed description and reported back as a
  label like any other.
- **Threshold and fallback.** Per record: `confidence < threshold` → re-ask
  that record through the current leaf, `source: leaf`. The default
  threshold is a worked value tuned in S21 (the spike saw 0.89–1.0 on a clean
  batch), stored in one module-level constant, env-overridable like the
  other `RLM_*` knobs.
- **Model id.** `jev-latest` by default in one constant; S21 pins it.
- **Scope of the key.** The R0.4 lift widens from orchestrator fact-finding
  to any agent running `rlm` on a machine whose keychain holds the key
  (fit note Q5, option b).
- **Always-on rule placement.** One bullet under the workspace context's
  "Service Access" section, since that is where a runtime already learns
  what credentials gate. Under 100 tokens; the detail is in the skill.
- **Vendored skill provenance.** TypeSafe's SKILL.md is copied from
  `typesafe-ai/skills` at commit `65a39f3` (v0.5.7, 2026-09-12; re-checked
  2026-09-27: no newer commit) into the `jev` skill directory with a
  provenance comment and its license, per the workspace's vendored-skill
  convention.
- **Cost and limits to cite** (research, verified): $42 per billion input
  tokens, output free, with a "we can serve it profitably" qualifier (terms
  1.1, 1.7); 250k tokens/s and 1,200 requests/min, 429 beyond (2.1); no SLA,
  "materially as described" only (7.3); liability cap the greater of 12
  months' fees or $50 (5.9).

## Testing Decisions

- A good test drives the seam from outside — the CLI's command line and the
  REPL helper's call — and asserts observable output: stdout, stderr, exit
  code, and the bytes the stub server received. Nothing asserts on internals.
- Prior art: the shell contract tests under `scripts/tests/` (`test-plan.sh`,
  `test-check-dependencies.sh`: throwaway `mktemp -d` workspace, `PASS/FAIL`
  counters, `assert_eq`/`assert_contains`) and `test-check-ledger.py`.
- The new test starts a local Python stub HTTP server that records the request
  and replies with fixture responses (recorded from the spike's shape, under
  the tests' fixtures directory), then runs the CLI and the helper against it
  with `JEV_ENDPOINT` and `JEV_API_KEY` set. The no-key path runs with both
  unset and a keychain lookup that cannot succeed (a fake `security` on
  `PATH` that exits non-zero), asserting exit 3, empty stdout, and that the
  helper's leaf calls are the ones the current path would make (the leaf is
  faked the same way: a fake `claude` on `PATH` that echoes canned labels).
- The test never reads or writes the real keychain and never needs a
  network. It is wired into whatever runs the other `scripts/tests/` files.
- Both paths of `check-service-access.sh` (key present/absent) are covered by
  the same fake-`security` technique.

## Testability

- **Working looks like:** with a key, `rlm` labels carry `confidence` and
  `source: jev`, and a batch returns in under a second; without a key, the
  helper's output and the sub-model invocations are identical to today and
  nothing mentions Jev. The CLI prints typed answers on `0`, one stderr line
  on `3`.
- **Cheapest proving check:** `scripts/tests/test-jev.sh` (seconds, no
  network, fake `security`/`claude` on `PATH`, stub server). Covers S2, S4,
  S6, S7, S8, S9, S10, S11, S16, S19.
- **Failure modes and what is observable:**
  - No key → exit 3, one stderr line; the helper takes the current path
    silently (handled; by design not logged — S2).
  - Key present but rejected (401) → exit 4 with status; the helper falls
    back to the leaf for the whole batch and prints one warning line
    (handled).
  - Rate limited (429) or vendor down → exit 4; helper falls back per batch
    with one warning line, run completes on the leaf (handled; slower, never
    stuck).
  - Oversize batch → CLI exit 2 before any request; helper prevents it by
    sizing (handled).
  - Malformed answer JSON → helper falls back for that batch, warning line
    (handled).
  - Partial completion mid-run → each batch is independent; a re-run repeats
    only the root's loop, no state to clean (accepted).
  - Concurrent runs → independent requests; the 1,200 req/min limit is shared
    and shows as 429 fallback (accepted).
  - Silent failure hunted: a wrong label at high confidence is not observable
    (accepted — S21 tunes the threshold; correctness is confirmed elsewhere
    by the always-on rule's own condition).
- **Design changes that make the checks cheap:** endpoint and key overrides
  in the CLI; the helper calling the CLI rather than the network; fake
  binaries on `PATH` instead of touching the keychain.
- **Deliberately not tested:** live latency and label quality against the
  real endpoint (that is S20/S21, a person with a key, not CI); the exact
  wording of TypeSafe's vendored skill (provenance-pinned, not ours).

## Non-goals / Out of Scope

- Any seam other than `rlm` (research-wave verdicts, triage, doc-review,
  decision-log, checkpoint routing) — a later plan; research-wave is the
  next candidate.
- **Tier routing at subagent dispatch** — resolving `tier: auto` in `plan.sh`
  with a Jev decision; the `plans` item owns that file; the baseline to beat
  is cheap-first, escalate on a failed check. A later plan.
- **A relevance filter** before loading files or tickets into context. A
  later plan.
- Score and Noul questions in `rlm` (the helper is Choice-only; the CLI
  supports all three for other callers).
- Anything ADR-0011 rules out: session-loop verdicts, budget gates, ledger
  checks on a model call.
- SDK adoption, an MCP server, or the TypeSafe Claude Code plugin as the
  integration path — the plugin's SKILL.md is vendored as agent knowledge
  only.
- Pushing `main`; editing `plan.sh`, `session-loop.sh`, or the plans skill.

## Further Notes

- The spike (`research/spike.md`, `research/spike.py`) is provenance and the
  prototype for the wire shape; it is not re-run.
- Tickets are under `issues/`; each carries `Spec: S<n>`. The wave-3 reconcile
  node turns them into implementation waves of plan `01-gated-integration`.
