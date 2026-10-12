# Trigger review — every model-invoked skill (plan 01-skill-ceremony, node 02)

Session 24, worker b. Byte counts are what `scripts/check-skill-descriptions.sh`
measures: the `description:` value in bytes (folded blocks joined with single
spaces, surrounding quotes counted). Baseline before this node: **10,174 bytes
over 32 model-invoked skills**. Applied here (vendored files): `unslop`,
`technical-writing` (adapted frontmatter), `constraint-driven-development`,
`doubt-driven-development` (patch). Node 06 applies the workspace-skill rows
from the blocks below.

## Criteria

- **Keep** — the skill should fire from context without being asked, and the
  description already names concrete situations.
- **Tighten** — the description is long (over roughly 300 bytes), lists
  synonyms, or says "always"/"any"/"whenever" without a real trigger. The
  replacement says what the skill does in one clause, then the situations that
  trigger it. No "/command" as a trigger: Codex reads the same text through
  `agents/openai.yaml`.
- **User-invoke** — a procedure a person (or a hook / launcher that names the
  skill) starts deliberately: session mechanics, setup, advisory
  interrogations; or an accidental fire would cost real tokens or a user
  interruption. Gets `disable-model-invocation: true`, an `agents/openai.yaml`
  with `allow_implicit_invocation: false`, and a `.claude/commands/<name>.md`.
- **Vendored pristine** (Matt Pocock, Addy): a description change costs a
  patch re-applied at every refresh; keep unless the fire risk is real. Where
  a patch already exists, a one-line frontmatter hunk is cheap, so the two
  longest Addy descriptions are tightened there.

## Verdicts

| Skill | Class | Verdict | Bytes before → after | Reason |
| --- | --- | --- | --- | --- |
| decision-log | workspace | tighten | 910 → 305 | "WHENEVER" plus a list of phrase signals; the three tiers are explained in CONTEXT.md already |
| security-and-hardening | addy-pristine | keep | 581 → 581 | long, but every clause is a situation that should fire unasked (untrusted input, auth, deps, PII); a brevity-only patch is not worth the refresh cost |
| design-for-testability | workspace | user-invoke | 506 → 0 | advisory interrogation "alongside any design work"; an accidental fire is six questions to the user mid-design; companion of user-invoked grill skills; shortcut exists |
| jev | workspace | tighten | 482 → 303 | tight trigger but carries the no-key fallback that CONTEXT.md already states |
| session-rollover | workspace | user-invoke | 477 → 0 | started by a signal that names it (hook WARN/STOP text, `context-budget.sh` exit 1/2, CONTEXT.md, the launcher), never by description matching; shortcut exists |
| checkpoint | workspace | user-invoke | 438 → 0 | the stop door: the user says "checkpoint" or a launcher names it; "finishing a work chunk" would fire at every natural pause; shortcut exists |
| code-review | mattpocock patched | keep | 421 → 421 | length is explanation, triggers are explicit asks ("review a branch / PR / since X"); fire risk low |
| constraint-driven-development | addy patched | tighten | 886 → 335 | largest vendored description; ended in "when an agent writes more code than anyone will read"; patch already exists, one hunk added |
| deprecation-and-migration | addy-pristine | keep | 334 → 334 | each clause is a concrete migration situation |
| doubt-driven-development | addy patched | tighten | 487 → 320 | "any time a confident output would be cheaper to verify" fires on everything; now the high-stakes tier plus an explicit ask; patch already exists, one hunk added |
| why | pstack-adapted | keep | 318 → 318 | concrete question shapes; the last sentence routes to `research` / `decision-log` and prevents mis-fires |
| wizard | mattpocock-pristine | keep | 313 → 313 | concrete human-only situations and a stated non-trigger |
| observability-and-instrumentation | addy-pristine | keep | 307 → 307 | "any feature that runs in production" is the intended trigger; unpatched, not worth a patch |
| performance-optimization | addy-pristine | keep | 295 → 295 | concrete triggers (regression, Web Vitals, N+1, profiling) |
| shipping-and-launch | addy-pristine | keep | 271 → 271 | concrete (deploy to production, rollout, rollback) |
| blast-radius | pstack-adapted | keep | 269 → 269 | quoted phrases plus one situation |
| codebase-design | mattpocock-pristine | keep | 265 → 265 | vocabulary skill other skills lean on; triggers concrete |
| technical-writing | pstack-adapted | tighten | 252 → 197 | "Use for /technical-writing" is a slash as trigger; "commit messages" fired it on every commit (`pr` covers PR bodies) |
| code-simplification | addy-pristine | keep | 244 → 244 | triggers are refactor-for-clarity asks; unpatched |
| git-guardrails-claude-code | mattpocock-pristine | keep | 243 → 243 | setup skill, but the trigger already needs an explicit ask; user-invoking a pristine skill needs the adapted class (sync script), not worth it |
| research | mattpocock-pristine | keep | 238 → 238 | explicit asks |
| setup-pre-commit | mattpocock-pristine | keep | 238 → 238 | same as git-guardrails |
| benchmark-checklist | pstack-adapted | keep | 224 → 224 | fires when a number is measured or reported; the right unasked trigger |
| ci-cd-and-automation | addy-pristine | keep | 207 → 207 | concrete |
| prototype | mattpocock-pristine | keep | 179 → 179 | concrete |
| diagnosing-bugs | mattpocock-pristine | keep | 156 → 156 | tight |
| unslop | pstack-adapted | tighten | 49 → 156 | "Must always apply" fired on every piece of text, code and skill files included; now a final pass on human-facing prose (grows, by design) |
| grilling | mattpocock-pristine | keep | 152 → 152 | tight |
| domain-modeling | mattpocock-pristine | keep | 151 → 151 | tight |
| tdd | mattpocock-pristine | keep | 149 → 149 | tight |
| writing-for-agents | mattpocock-adapted | keep | 103 → 103 | tight; should fire when editing skills |
| pr | mattpocock-pristine | keep | 29 → 29 | tight |

Counts: keep 23 · tighten 6 · user-invoke 3. Not reviewed (already
user-invoked, bytes not counted): ask-matt, create-verification-skill,
create-work-item, doc-review, grill-me, grill-with-docs, handoff, implement,
implement-spec, improve-codebase-architecture, maintain-verification-skill,
onboard-repo, plans, research-wave, retro, rlm, setup-matt-pocock-skills,
teach, to-questionnaire, to-spec, to-tickets, triage, wait-what, wayfinder.

## New description text

### Applied in this node (vendored)

**unslop** (`skills/unslop/SKILL.md`, adapted frontmatter — on disk):

```yaml
description: Final editing pass that cuts AI-prose tells from human-facing text (docs, READMEs, PR text, reports); not code, commit messages, or agent-facing skill text.
```

**technical-writing** (`skills/technical-writing/SKILL.md`, adapted frontmatter — on disk):

```yaml
description: "Standard for human-facing technical prose: Diátaxis structure, Google developer style, STE instruction rules, Global English. Use when writing or reviewing a doc, README, RFC, or PR description."
```

**constraint-driven-development** (`skills/constraint-driven-development/workspace.patch`, new first hunk — on disk):

```yaml
description: Write a project's quality bar into CONSTRAINTS.md and flag changes that quietly lower it (new suppressions, skipped tests, stripped assertions, thresholds edited down). Use when the user asks to set up constraints or define standards, when a threshold is needed and no number exists, or when checks keep being silenced to get to green.
```

**doubt-driven-development** (`skills/doubt-driven-development/workspace.patch`, new first hunk — on disk):

```yaml
description: Subject each non-trivial decision to a fresh-context adversarial review before it stands. Use when stakes are high (production auth, security-sensitive logic, a risky migration, irreversible operations), when working in unfamiliar code, or when the user asks for assumptions to be cross-examined or a plan stress-tested.
```

### For node 06 (workspace skills) — tighten

**decision-log** (`skills/decision-log/SKILL.md`; keep the folded `>-` form and the `allowed-tools` block; `.claude/commands/decision.md` unchanged):

```yaml
description: >-
  Capture the why behind a decision (choice, rejected alternative, constraint)
  as a commit trailer, a Tier-2 note in work/<project>/decisions.md, or a
  promoted ADR. Use when you pick one approach over a real alternative or make
  a non-obvious tradeoff, and when the user asks why something was done this
  way.
```

**jev** (`skills/jev/SKILL.md`; keep the folded `>-` form):

```yaml
description: >-
  Ask Jev (TypeSafe's typed-question model) a Choice, Score, or Noul question
  through scripts/jev.sh and get a typed answer with a confidence. Use when a
  decision has closed options, many items to judge, and a safe fallback
  (routing, classification, ranking, yes/no checks); never for prose or
  extraction.
```

### For node 06 (workspace skills) — user-invoke

Each gets `disable-model-invocation: true` in the frontmatter (after
`description:`, as `doc-review` does), a new `agents/openai.yaml` in the shape
of `skills/doc-review/agents/openai.yaml`, and keeps its existing
`.claude/commands/<name>.md` (description lines below are the current ones;
no change needed). The body's own "When to use" / trigger-policy sections stay
the authority on timing; the shortened description only has to identify the
skill in a listing.

**checkpoint** (`skills/checkpoint/SKILL.md`):

```yaml
description: Wrap up a finished chunk of work: reconcile the backlog, memory and docs, write the hand-off, confirm a clean branch, and emit a catch-up prompt for the next session.
disable-model-invocation: true
```

`skills/checkpoint/agents/openai.yaml` (new):

```yaml
interface:
  display_name: "Checkpoint"
  short_description: "Wrap up a work chunk and hand off cleanly"
policy:
  allow_implicit_invocation: false
```

`.claude/commands/checkpoint.md` description (unchanged): `Wrap up the current chunk of work and emit a post-/compact catch-up prompt`

**session-rollover** (`skills/session-rollover/SKILL.md`):

```yaml
description: Roll work over to a fresh session through a pruned handoff when the context budget hits WARN/STOP: reflect, flush, handoff.md, next-session.md, then stage or launch the successor.
disable-model-invocation: true
```

`skills/session-rollover/agents/openai.yaml` (new):

```yaml
interface:
  display_name: "Session Rollover"
  short_description: "Roll over to a fresh session at context WARN/STOP"
policy:
  allow_implicit_invocation: false
```

`.claude/commands/session-rollover.md` description (unchanged): `Roll work over to a fresh session via a deliberate, pruned handoff (context-budget WARN/STOP)`

**design-for-testability** (`skills/design-for-testability/SKILL.md`; keep the `allowed-tools` block):

```yaml
description: >-
  Advisory six-question interrogation of a design: how will we test it, how
  does it fail, what is observable, and what is the cheapest check that proves
  it works. Answers land where the design lives; never a gate.
disable-model-invocation: true
```

`skills/design-for-testability/agents/openai.yaml` (new):

```yaml
interface:
  display_name: "Design for Testability"
  short_description: "Six testability questions before the code is written"
policy:
  allow_implicit_invocation: false
```

`.claude/commands/design-for-testability.md` description (unchanged): `Advisory design-time interrogation — how will we test this, how does it fail, what is observable, what is the cheapest proving check`

Docs that name these three as model-invoked (for the docs nodes): CONTEXT.md
"Workspace Skills" one-liners are unchanged in wording; `docs/context-budget.md`
and `skills/checkpoint/SKILL.md` already say "run `skills/session-rollover/SKILL.md`"
by path, which is how a user-invoked skill is reached from a hook or launcher
(the precedent is `plans`, user-invoked and run from `plan.sh` prompts).

## Tier-2 notes

Orchestrator copies these to `work/template-maintenance/decisions.md`.

### 2026-10-11 — Skill ceremony: `unslop` is a final pass on human-facing prose
**Chose:** `description: Final editing pass that cuts AI-prose tells from human-facing text (docs, READMEs, PR text, reports); not code, commit messages, or agent-facing skill text.` (156 bytes, in the adapted frontmatter).
**Because:** "Must always apply" made it fire on every token of output, including code and skill files, where its catalog of tells (no em dashes, no triads) conflicts with `writing-for-agents`; an editing pass is the shape upstream's body describes ("Edit text to remove AI patterns").
**Rejected:** user-invoking it (then nobody runs it: the whole point is a pass the author forgets); keeping "always" with a shorter list (still fires on code).
**Blast radius:** skills/unslop/SKILL.md frontmatter; the catalog line in skills/vendored-skills.md ("Model-invoked so it applies whenever prose is produced" needs rewording).
**Promote?:** no.

### 2026-10-11 — Skill ceremony: `checkpoint`, `session-rollover`, `design-for-testability` become user-invoked
**Chose:** `disable-model-invocation: true` + a workspace `agents/openai.yaml` with `allow_implicit_invocation: false` for the three; their `.claude/commands/` shortcuts already exist. Short identifying descriptions; the trigger policy stays in each body.
**Because:** none is reached by description matching. `session-rollover` is named by the hook WARN/STOP text, by `context-budget.sh` exit codes 1/2 and by CONTEXT.md, all by file path; `checkpoint` is the user's word or a launcher instruction; `design-for-testability` is an advisory interrogation beside the already user-invoked grill skills, and an accidental fire costs the user six questions. Together they are 1,421 bytes weighed every turn for zero description-driven invocations. `plans` is the precedent: user-invoked, still followed from `plan.sh` prompts by reading the file.
**Rejected:** keeping `session-rollover` model-invoked as a safety net (the net is the hook/exit-code path, which names the file; a description cannot fire on a token count the model cannot see); tightening the three instead (still a per-turn tax for a skill that is never triggered by text).
**Blast radius:** the three SKILL.md frontmatters, three new openai.yaml files, skills/vendored-skills.md footnote, docs/workspace-structure.md and CONTEXT.md where "model-invoked" is claimed; the `(slash)` markers are already right.
**Promote?:** no.

### 2026-10-11 — Skill ceremony: vendored descriptions are patched only where a patch already exists
**Chose:** tighten `constraint-driven-development` and `doubt-driven-development` by adding a frontmatter hunk to their existing `workspace.patch`; leave every other pristine vendored description as upstream wrote it (`security-and-hardening` at 581 bytes and `code-review` at 421 included); pstack adapted frontmatters (`unslop`, `technical-writing`) are edited directly.
**Because:** a patch is re-applied at every refresh and breaks whenever upstream touches the hunk (Addy's repo: 322 commits in 90 days); for a skill that already carries a patch the marginal cost is one hunk on a line upstream rarely edits, and those two were the only vendored descriptions that over-trigger ("any time a confident output…", "when an agent writes more code than anyone will read"). The long keepers are long because they list real situations, not synonyms.
**Rejected:** new patches for brevity alone; user-invoking `git-guardrails-claude-code` / `setup-pre-commit` (needs the adapted class in the sync script to own their openai.yaml, for 480 bytes whose trigger already requires an explicit ask).
**Blast radius:** the two patches and SKILL.md files; the sync round trip must still produce an empty diff (patches verified with `patch -p1 -R -F0 --dry-run` and a forward apply onto the reconstructed upstream file).
**Promote?:** no.

### 2026-10-11 — Skill ceremony: `technical-writing` drops the slash and commit messages from its trigger
**Chose:** `description: "Standard for human-facing technical prose: … Use when writing or reviewing a doc, README, RFC, or PR description."` (197 bytes).
**Because:** "Use for /technical-writing" names a Claude Code command as a trigger, which means nothing to Codex or Gemini; "commit messages" made it fire on every commit, where the four-layer standard is overkill and `pr` already owns PR bodies.
**Rejected:** user-invoking it (it should catch a README being written without being asked).
**Blast radius:** skills/technical-writing/SKILL.md frontmatter; vendored-skills.md catalog line mentions commit text.
**Promote?:** no.

### 2026-10-11 — Skill ceremony: `SKILL_DESC_MAX_BYTES` = 7500
**Chose:** set the budget in `scripts/check-skill-descriptions.sh` to 7500: the projected total after all verdicts (7,303 bytes) rounded up to the next 500.
**Because:** the budget is a ratchet, not a ceiling with slack; ~200 bytes of headroom means adding a model-invoked skill forces a trim or a user-invoke swap, with the reason in the commit, which is the discipline the video argued for.
**Rejected:** 9000 (the initial value; leaves room for four more untrimmed skills); 8000 (room for one long one, which is how the pack grew to 10 KB).
**Blast radius:** scripts/check-skill-descriptions.sh constant and its comment; the test's fixture budget is set per case and is unaffected.
**Promote?:** no.

## Projected total

Baseline 10,174 bytes over 32 skills. After this node's on-disk edits: 9,508
(check output). After node 06 applies the five workspace rows (decision-log
910 → 305, jev 482 → 303, checkpoint 438 → 0, session-rollover 477 → 0,
design-for-testability 506 → 0): **7,303 bytes over 29 model-invoked
skills**. Recommended `SKILL_DESC_MAX_BYTES`: **7500**.
