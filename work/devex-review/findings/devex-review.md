# DevEx Review — Consolidated Findings (2026-08-11)

Synthesis of three cold-start persona reviews of the ai-workspace-template:
**developer** (lifecycle walkthrough + spec-workflow addendum), **product
manager** (non-engineer fit), and **QA engineer** (template self-QA + QA-role
fit + spec→test traceability). Raw reports: `dev-persona.md`, `pm-persona.md`,
`qa-persona.md` in this directory. All reviews were read-only.

## Overall verdict

The template's *machinery* is in excellent shape — QA verified every
cross-reference resolves, all ~40 scripts pass syntax checks, and live smoke
tests of `context-budget.sh` and `launch-next-session.sh` passed. Its
strongest conventions (launcher/ledger, check-script/runbook pairing, ADR
decision records, honest self-measurement) drew unprompted praise from all
three personas. The problems cluster in four cross-cutting themes, none of
which is a code defect: the template hasn't separated itself from the project
that built it; the spec workflow is the least-built lifecycle stage; the
skill chain that the conventions depend on lives outside the repo; and
non-developer roles (PM, QA) have no seat at the table.

**Severity tally:** 0 blockers · 17 majors · ~15 minors · ~7 papercuts.

## Cross-cutting themes

### Theme 1 — The template ships its maintainer's lab notebook (dev 8, 9, 10; QA A4, A8)

~1MB of the maintainer's research history under `work/`; core plumbing
(`context-budget.sh:40`) writes telemetry into `work/context-decay/` — a
research directory an adopter will delete, which then silently reappears;
shipped skills cite `work/context-decay/*-analysis*.md` as evidence; nothing
in `docs/template-usage.md` says what's prunable. The developer persona called
this "the single biggest trust repair."

### Theme 2 — The spec workflow is the least-built lifecycle stage (dev S1–S5; QA B2–B4; PM 4.1)

All three personas independently converged here, matching the user's premise
that specs are a PM+dev collaboration and QA's test-plan foundation:

- **No in-repo format**: `work/<effort>/spec.md` has a *path* convention but
  no template — the format lives only in the external `to-spec` skill. Name
  collision with root `SPEC.md` (product identity, different altitude).
- **No collaboration surface**: single author baked in everywhere — `to-spec`
  forbids interviewing, no draft/in-review/approved state, no sign-off field,
  and the docs warn a second *person* breaks session locks silently. The
  cheap fix is riding on git (spec on a branch, PM iterates in the PR) — but
  no doc says so.
- **No traceability**: tickets have no `Spec:`/`Covers:` field, spec items
  have no stable IDs, so "which tickets/tests cover requirement 3?" is
  unanswerable without reading everything. QA noted the template's own
  backlog HTML *does* have stable IDs — the discipline exists in-house.
- **No trigger**: `spec.md` is just "Optional"; a dev has no rule for when a
  major initiative requires one.
- **No test basis without a spec**: success criteria live in conversation and
  are structurally ephemeral (handoff blocks archive after two sessions).

### Theme 3 — The advertised skill chain isn't in the box (dev S2, 13; QA B1; PM 4.1)

`to-spec`, `to-tickets`, `triage`, `diagnosing-bugs`, `tdd` are the workflows
the conventions route to — and none ship with the template; they're the
maintainer's optional global toolchain. `docs/agents/issue-tracker.md` config
exists for skills adopters don't have. This violates the workspace's own
recorded principle (integrations must work for downloaders, agent-agnostically).
The template already has the right pattern — `wayfinder` is vendored with
provenance — it just wasn't applied to the rest of the chain.

### Theme 4 — PM and QA have no seat (PM 1.1, 2.2, 4.2, 5.1; QA B5, B6)

- **PM**: zero PM-facing entry points ("product manager" appears nowhere);
  yet the *content* is PM-capable — ADRs are highly readable, work READMEs
  are real status reports, `/create-work-item` and `/decision` are usable by
  non-engineers but unadvertised. A one-page `docs/for-non-engineers.md`
  (status / decisions / contributing + ~6-term glossary) converts the repo.
- **QA**: "test plan", "test result", and "QA" appear zero times across all
  docs and skills. Verification evidence has no durable home the way
  decisions (`decisions.md`) and sessions (`handoff.md`) do — "the template
  deeply believes 'capture the why behind decisions'; it has no equivalent
  for 'capture the evidence behind done'."

### Theme 5 — Setup and doc-drift papercuts (dev 1, 3, 4, 5, 12; QA A1, A2, A3, B7)

First documented command fails on a pristine clone (check-before-setup
order); required hooks check is Claude-Code-only despite the agent-agnostic
promise; a from-scratch "Agent Bootstrap" path in workspace-structure.md
scaffolds a degraded workspace; three self-describing counts already stale;
conflicting settings-copy targets; `graphifyy` typo in a copy-pastable fix
hint; promised `## Language` section missing from the CONTEXT.md template.

### Theme 6 — Conceptual overload of the context-budget system (dev 11; PM 5.1)

The daily loop is three commands, but trusting it requires absorbing session
roles, locks, dispatch generations, and a six-runtime hook matrix. Needs a
"Minimal mode" statement of the viable subset. The PM persona hit the same
wall as jargon (~6 terms needed vs. dozens presented, no glossary).

## What all personas agreed works well

- **Launcher/ledger convention** (`docs/work-directory-conventions.md`) —
  self-enforcing via purpose headers; "the strongest single convention."
- **Decision records** — ADRs with rejected alternatives; "better decision
  hygiene than most product orgs" (PM).
- **`scripts/setup.sh`** — real-world-hardened, idempotent, "scar tissue from
  actual failures, encoded."
- **Check-script/runbook pairing** — verify-only checks with exact fix text.
- **Honest self-measurement** — docs flag their own unverified claims;
  measured rollover costs instead of vibes.
- **Reference integrity** — every path/skill/hook named anywhere resolves
  (QA-verified).

## Prioritized fix list

1. **Ship a clean day-1 state** (Theme 1): move the ledger to
   `.context-budget/`, add a prune-`work/` step to `template-usage.md`,
   promote doc-worthy content to `docs/archive/`, strip maintainer evidence
   pointers from shipped skills.
2. **Make the spec workflow real** (Theme 2): commit a `spec.md` skeleton
   (numbered stories, `Status: draft|in-review|approved` + `Approved-by:`
   header), document the git-branch PM-review loop, add `Spec:`/`Covers:` to
   ticket conventions, add the "when a spec is required" rule to
   `create-work-item`, disambiguate from root `SPEC.md`.
3. **Give verification a durable home** (Theme 4/QA): `test-plan.md` /
   `verification.md` rows in the optional-files table; severity/repro fields
   in issue conventions; "no spec → success criteria in README.md" rule.
4. **Close the toolchain gap** (Theme 3): vendor `to-spec`/`to-tickets` (and
   ideally `triage`) beside `wayfinder` with provenance, or declare them
   prerequisites explicitly where the conventions depend on them.
5. **Add the PM entry point** (Theme 4/PM): `docs/for-non-engineers.md` +
   `work/README.md` status index + audience tags on skills.
6. **Setup correctness pass** (Theme 5): runtime-aware hooks check, swap
   check/setup order, align settings-copy targets, fix `graphifyy`, demote
   the bootstrap appendix, drop literal counts, add `## Language` placeholder.
7. **Minimal mode** (Theme 6): a top-of-doc statement of the 3-command solo
   subset in `docs/context-budget.md`; everything else labeled fleet-only.

## Ready-to-file backlog candidates

Findings that map cleanly to template-backlog cards: dev 1, 3, 4, 5, 6, 8, 9,
10, 12; dev S1–S5; QA A1–A7, B1–B3, B5, B7; PM 1.1, 2.2, 2.3, 4.1. (QA A8 is
session hygiene, not a template defect; several PM items fold into the
`for-non-engineers.md` card.)
