---
name: design-for-testability
description: >-
  Advisory design-time interrogation: how will we test this, how does it fail,
  what is observable when it does, and what is the cheapest check that proves it
  works. Use alongside any design work — while grilling a plan (grill-with-docs /
  grill-me), drafting a spec (to-spec) or an ADR, or before implement/tdd starts
  on a non-trivial feature. Six questions, answers written down where the design
  lives. Not a gate: it never blocks a design, it makes the testability bill
  visible before the code is written.
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
---

# design-for-testability — ask "how do we know it works?" before building

> **Vendor-neutral skill.** Plain markdown any agent can read and drive, in the shared
> `skills/` dir per `CONTEXT.md`. Claude Code also exposes it as
> `/design-for-testability` (`.claude/commands/design-for-testability.md`).

Decision capture here is strong (decision-log, ADRs, trailers); the question nobody is
assigned to ask at design time is *how will we test this, and how does it fail*.
Found after implementation, testability problems are the expensive kind. This skill is
a short interrogation — a **companion** to `grill-with-docs`, `to-spec`, and ADR
authoring, never a replacement or a gate.

## When to use

- A design is taking shape: mid-grill, while a spec or ADR is being drafted, or right
  before `implement` / `tdd` on a feature with more than one moving part.
- The user asks "how would we test this?" or "what happens when X breaks?".
- Skip it for trivial changes (a typo, an obvious one-liner).

## Read first (demand-load)

- The design under discussion: `work/<effort>/spec.md`, the ADR draft, or the plan in
  conversation — only what the six questions need.
- `docs/work-directory-conventions.md` → "Verification evidence" — only when the
  answers produce concrete checks to record (question 2).

## Procedure — six questions

Ask in order; the user answers, you sharpen. Each has a *write-down* — an answer too
vague to write down is not yet an answer.

1. **What does "working" look like?** The observable outcome — output, state change,
   exit code, message — a stranger could confirm without reading the code.
   *Write down:* one sentence per success outcome.
2. **What is the cheapest check that proves it?** The smallest test, command, or
   manual step demonstrating 1 end to end. "Run the whole system and look" is a
   design signal — see 5. *Write down:* the check and its cost (seconds, a fixture,
   a human).
3. **How does it fail?** Walk inputs and dependencies: bad/missing input, dependency
   down or slow, partial completion (crash mid-way), re-run after failure, concurrent
   runs, stale state. *Write down:* one line per failure mode; mark handled vs.
   accepted.
4. **What is observable when it fails?** Per failure mode in 3: what a caller or
   operator sees — error message, non-zero exit, log line, metric, half-written file.
   Silent failure is the finding to hunt for. *Write down:* the signal per failure
   mode, or "silent — fix in design".
5. **What must the design change to make 1–4 cheap?** The seams: a pure core with I/O
   at the edges, an injectable clock/filesystem/network, an idempotent re-run, a
   `--dry-run`. Smallest change that turns an expensive check cheap.
   *Write down:* the change, or "none needed".
6. **What will we deliberately not test, and why?** The accepted risk, stated so it is
   a decision, not an omission. A real fork with a rejected alternative is also a
   `decision-log` Tier-2 note. *Write down:* the untested surface and the reason.

## Where the answers land

Pick by where the design lives — one home, not three:

- **Effort spec** (`work/<effort>/spec.md`) — the default. A `## Testability` heading
  (optional in the skeleton, `docs/agents/issue-tracker.md` → "Spec conventions")
  holding 1, 3, 4, 5, 6 as short bullets.
- **ADR** — when the design is an ADR: failure modes, observability, and accepted risk
  (3, 4, 6) go in its **Consequences** section — the bill this decision sends to the
  future.
- **Verification plan** (`work/<effort>/verification.md` → `## Plan`) — the concrete
  checks from 2, as `V<n>` items with `covers S<n>` where a spec exists.

Answer in conversation first, then write; the write-down is the point.

## Verification

- The home file holds the six answers (grep `Testability` in the spec, or read the
  ADR's Consequences); none reads "TBD".
- Every failure mode from 3 has an observability line from 4.
- Checks from 2, if any, appear as `V<n>` items in `verification.md`.
