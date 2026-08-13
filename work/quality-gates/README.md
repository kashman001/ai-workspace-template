# quality-gates — Man the quality-enablement lane (test infra, gate policy, AI failure-triage)

Governing skill(s): — (none yet; the effort will likely *produce* docs/skills).

**Start here:** `next-session.md` (catch-up launcher) → `handoff.md`
(session ledger, top block).

## What this is

Close gap **G2 (absorbing G3)** from the SDLC map
(`work/sdlc-ai-mapping/sdlc-map.md`, gap register + N4 entry + lane table):
the template's quality-enablement lane is unmanned. There is no guidance on
test infrastructure, AI test-tooling adoption, CI gate policy, AI-assisted
failure triage, or flaky-test policy — the template assumes CI gates exist
but says nothing about them. The map rates this High severity on measured
evidence: AI raises change volume, so gates matter *more* under agentic
coding, not less (DORA caveat, [measured] tier in
`work/sdlc-ai-mapping/research-modern-qa.md`).

The lane, as the map defines it: test infrastructure, coaching, risk
analysis — where modern dedicated-QA sits (Google SETI/TE, Atlassian QA)
and the natural anchor for AI test tooling.

## Success criteria

- CI quality-gate guidance exists (G3, the first deliverable): which gates a
  repo should run, how to triage AI-era failures, and a flaky-test policy.
- Quality-enablement guidance exists covering test-infrastructure choices
  and AI test-tooling adoption, with the map's evidence tiers respected
  (e.g. gated unit-test generation is [measured]; self-healing tests are
  [hype] — don't recommend hype-tier tooling).
- The SDLC map's G2/G3 rows can be marked closed: the lane row and N4's
  "GAP" note have named template capabilities to point to.
- Wired per template rules: agent-agnostic (Codex/Gemini/OpenCode via
  CONTEXT.md, not just Claude Code) and shipped/documented for downloaders.

## Files

- `next-session.md` — forward launcher (what to do next). REPLACED each rollover.
- `handoff.md` — session ledger (what happened). APPEND newest-on-top; archive
  to `handoff-archive.md` when it exceeds the two most recent sessions.
