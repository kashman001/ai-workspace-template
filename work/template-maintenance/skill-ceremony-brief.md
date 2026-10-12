# Brief — stakes-matched ceremony, trigger trimming, anti-rationalization tables

Session 24 dispatch brief, second task. Report file:
`work/template-maintenance/skill-ceremony-report.md`. The user is away and
asked for this to be finished end to end.

## Background

The user shared Rob Shocks' video "Pocock vs Pstack vs Osmani"
(youtube.com/watch?v=sU9MW8Ycq2M) after we vendored 16 skills from Addy
Osmani's agent-skills and pstack (see `skill-packs-analysis.md` and
`skill-packs-report.md` in this directory). The video's points:

- Match ceremony to stakes. Not every change needs every skill.
- More skills is not a smarter agent. Every model-invoked description is
  something the agent weighs, and accidental auto-triggering is a real
  cost.
- Addy's anti-rationalization tables (the excuses an agent gives to skip
  a step, with a rebuttal for each) are worth stealing.

The template now has 56 skills, and the always-visible model-invoked
descriptions total about 8.7 KB. `skills/unslop/SKILL.md` says "Must
always apply.", so it auto-fires on almost any writing. The only
ceremony guidance is one line in `CONTEXT.md`, under Agent Coding
Principles #1: "use judgement rather than full ceremony".

## The user's request: three items, then docs

1. **Stakes → ceremony guide.** Write a short, runtime-neutral table that
   maps change size and risk to the skills to use. For example: tweak →
   just do it and check it; small feature → `grill-me` + `tdd`; big or
   fuzzy → `to-spec` + `plans`, verifying each phase; production,
   security or irreversible → `doubt-driven-development` +
   `security-and-hardening` + review. Decide where it lives. A pointer
   from `CONTEXT.md` must stay lean, under the 16K budget its check
   enforces. Wire it into `ask-matt` if that's sensible. Note that
   `ask-matt` is vendored; change it only through the patch mechanism, or
   leave it alone and point at the guide.
2. **Trigger trimming.**
   - Narrow `unslop`'s description through a `workspace.patch`, following
     the patched-class rules in `skills/vendored-skills.md`.
   - Review every model-invoked skill, both the 16 new ones and the
     existing ones. Decide which should become user-invoked
     (`disable-model-invocation: true` + `agents/openai.yaml`
     `allow_implicit_invocation: false` + a `.claude/commands/` shortcut,
     matching the existing user-invoked set) or get tighter descriptions.
     Vendored skills change only via patch or the adapted class.
   - Add a check that warns when the total model-invoked description size
     exceeds a budget. Put it in `scripts/`, wired into
     `scripts/run-checks.sh`, with a test under `scripts/tests/` that is
     seen to fail on a bad case first.
   - Record each call as a Tier-2 note.
3. **Anti-rationalization tables** for the workspace's own skills, where
   agents most often cut corners. Candidates are `checkpoint`,
   `session-rollover`, `decision-log`, `create-work-item`, `plans`, and
   the verification steps. Use Addy's format; the vendored Addy skills
   show it. Keep each table short and specific to real failure modes,
   which `handoff.md` and the backlog archive record. Don't add tables to
   vendored skills.
4. **Then documentation.** Update every doc the changes affect:
   - `skills/vendored-skills.md` (patched and user-invoked status)
   - `docs/workspace-structure.md`
   - `CONTEXT.md` Workspace Skills (keep it lean)
   - `docs/recommended-tooling.md`, `README.md` and
     `docs/for-non-engineers.md` where they list skills
   - `skill-packs-analysis.md`: add a short "after the video" addendum
   - a short adoption note for downloaders, after Addy's own advice:
     roll out gradually, verification first, prune what you don't use

   Also fold in two optional one-liners if they fit cheaply: `retro`
   should say "update the skill when the agent repeats a mistake" (only
   if it is not vendored-pristine; otherwise skip it), and a note that
   Addy's `/build auto` maps to `implement-spec`.

## How to run it

- **Plan first, with the planning framework.** Read `docs/plans.md` and
  `skills/plans/SKILL.md`, then create a plan for work item
  `template-maintenance` under `work/template-maintenance/plans/` with
  `scripts/plan.sh`. One node per unit of work, grouped into waves, each
  wave closed by a reconcile node. Maximize parallelism: independent nodes
  share a wave. The docs update comes last. Let `scripts/plan.sh` own
  every state write, and lint the plan.
- **Backlog.** Open one card per item (three), following the "Maintaining
  this backlog" rules in `docs/template-workspace-backlog.html`: next free
  IDs, scorecard, "Last updated", and a log row. Grep the file; never load
  it whole. Resolve them with `Fixed:` notes, which move them to the
  archive, when done.
- **Execute** wave by wave. Dispatch the independent nodes of a wave to
  parallel subagents in one message. Pick the model by task: fable or opus
  for judgement (the ceremony guide, trigger review), sonnet for
  mechanical edits, tests and docs, haiku for trivial lookups.

## Hard rules

These are the same as `skill-packs-brief.md`:

- **Agent-agnostic** (the user stressed this): Codex, Gemini, Copilot and
  OpenCode as well as Claude Code.
- **Shared files** are edited only by the orchestrator: the backlog HTML,
  `CONTEXT.md`, `skills/vendored-skills.md`, `docs/workspace-structure.md`,
  `decisions.md`, and plan state via `plan.sh`. Workers return the wiring
  edits they need.
- **Vendored skills** change only via patch or the adapted class. A sync
  round trip must leave an empty diff.
- **Simplicity first.** Keep the changes surgical.
- **Verification:**
  - `scripts/run-checks.sh` passes in full.
  - The relevant `scripts/tests/` suites pass.
  - Every new check is seen to fail on a bad case.
  - Report only the commands you actually ran.
- **Git:**
  - Commit locally on `main`, referencing card IDs.
  - Add a `Decision:` trailer where a choice was made.
  - End each commit with
    `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
  - **Never push.**
  - Re-check HEAD before writing shared files.
- **Never stop for an answer.** The user is away. Pick the sensible
  default and record it as a Tier-2 note. Report BLOCKED only if
  something truly can't proceed.
