# Source notes — "Harness engineering for coding agent users"

Birgitta Böckeler (Thoughtworks), martinfowler.com, 2026-04-02.
<https://martinfowler.com/articles/harness-engineering.html>. Summarized
2026-10-08 so sessions don't refetch it.

## The model

- **Agent = model + harness.** The *user harness* is what a team builds
  around the agent for its own system (the agent vendor's system prompt and
  tooling are the builder harness, not ours).
- **Guides (feedforward)** steer before the agent acts. **Sensors
  (feedback)** observe after it acts so it can self-correct. Feedback alone:
  the agent repeats mistakes. Feedforward alone: rules are never checked.
- **Computational** controls are deterministic and cheap (tests, linters,
  type checks, structural tests). **Inferential** ones are LLM judgement
  (AI review, LLM-as-judge): slower, costlier, non-deterministic.
- Sensor output written for an LLM, such as a lint message with the fix in
  it, is "a positive kind of prompt injection".

## Practices

- **Steering loop:** when an issue recurs, improve a guide or add a sensor
  so it gets less likely or impossible. AI can write the checks.
- **Keep quality left:** run checks as early as their cost allows — fast
  ones before integration (pre-commit/agent hook), expensive ones after
  (CI), which reruns the fast ones too.
- **Drift sensors / "garbage collection":** run sensors over the whole
  codebase on a schedule, outside any change, to catch gradual drift
  (dead code, coverage, dependencies). OpenAI's practice, quoted.
- **Harnessability:** some codebases are easier to check (types, clear
  module boundaries).
- **Harness templates:** bundles of guides and sensors per service shape;
  they inherit template drift and versioning problems.
- **Humans:** the harness should direct human input where it matters most,
  not remove it.

## Open problems the article names

Behaviour harness (are AI-written tests trustworthy?) · **coherence**
(keeping guides and sensors from contradicting each other) · conflicting
signals · **silent sensors** (a check that never fires: healthy or broken?)
· harness coverage · tooling to see all controls as one system.

## How it maps to this template

| Idea | Template today | Ticket |
|---|---|---|
| Keep quality left | 28 suites + `check-*` scripts; no runner, no pre-commit, no CI | 01 (M44) |
| Drift sensors | Session-4 doc gap review done by hand; path checks for plans docs only | 02 (M45) |
| Steering loop | Gotchas classified ADD/UPDATE/SUPERSEDE/NOOP; no "promote to check" | 03 (L60) |
| Coherence / one view | Controls documented where they live; no combined map | 04 (L61) |
| Silent sensors | Most checks have a failing-input suite; not a rule | 05 (L62) |
| LLM-readable sensor output | ADR-0011 reason codes + remedies — already done | — |
| Behaviour harness, harness templates | Little code to test; `TEMPLATE_VERSION` covers versioning | not adopted |
