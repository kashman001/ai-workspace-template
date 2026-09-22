# ADR-0011: Every load-bearing session step is a script that refuses with a reason code

- Status: accepted
- Date: 2026-09-21
- Deciders: Kashif + Claude Code sessions 8–16 of `template-improvement-review`

## Context

The operator of the session machinery is the agent itself, which forgets and
hallucinates. Guarantees that lived in skill text ("write the sentinel", "run
seq-sync", "check the counter") failed three times in one month: the agent
believed it had rolled over when it had not. At the same time roughly half of
the 600-plus test assertions pinned prose — message wording, remedy sentences —
so rewording a halt message broke suites, and a reworded suite proved nothing
about behaviour.

## Decision

Every load-bearing step of the session lifecycle is a script verb with an exit
code that writes its evidence to the record, and the next verb refuses on
missing evidence: `register` binds, the launcher checks the ledger block and
the launcher file itself and then advances the number, `close` checks the
ledger for the stop door, the supervisor reaches one of three verdicts from
record fields alone. A refusal is exit 4 with `reason=<code>` on stderr and
`key=value` detail on the same line; a verdict is `verdict=<code>`; codes come
from one canonical list (`docs/context-budget.md` → "Verbs and reason codes"),
pinned to the scripts in both directions by
`scripts/tests/test-doc-consistency.sh`. Log and message text is free-form and
never a test contract. Probes are scripts with self-checked pass criteria, and
each probe that needs a vendor login has a stub-runtime twin in the suites.

## Alternatives considered

- **Skill-text-only guarantees** — rejected: the three incidents above; text is
  not read at the moment of need.
- **Golden-string tests** — rejected: they pin prose, not behaviour, and made
  every message edit a suite edit.
- **A `--json` output mode** — rejected as speculative: the `key=value` line
  after `reason=` is enough for every caller (the supervisor greps the code).
- **A separate prep step and a verification stamp** — rejected: a stamp goes
  stale; the launcher and `close` run the checks inline at the moment they act,
  and `--check` runs the same checks without writing.

## Consequences

- An agent needs to remember one thing: run the script and read the code. The
  skill carries the code table, not the rules behind it.
- Adding a code means adding it to the doc's list or the doc-consistency test
  goes red — deliberate friction against code sprawl.
- Message wording can change freely; tests pin exit codes, record fields and
  reason codes only.
- Ambiguity is still resolved by the agent in one place (`supervised` exit 2 →
  stage anyway); the launcher refuses only on positive evidence.

## Provenance

- Promoted from: `work/template-improvement-review/decisions.md` (Stage 2
  §1b.7, Stage 3 amendments); `plans/phase-5.md` decision 8 (verdict lines are
  stderr + log; the code is the contract); `plans/phase-7.md` (probes as
  self-checking scripts, stub twins).
- Commits: Stage 4 phases 3–8 on `stage4`; phase 8 `8c3d6d9` (the canonical
  list and its test).
- Refs: `work/template-improvement-review/evaluation/stage3-design-v2.md`
  ("The gates and their refusal codes", "Tests");
  `session-management-review-findings.md` §(j), §(k).
