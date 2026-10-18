# T5 — 'Claude Changed Completely' video (Simon Scrapes)

Track T5 of `work/external-tools-review/`. Research only; no template files changed.

**Sources** (fetched 2026-10-18):
- [V] Video: https://www.youtube.com/watch?v=YAuWBqZ_gjs (Simon Scrapes, 2026-10-17). Full
  auto-caption transcript read. The video doubles as an ad for a paid course.
- [CMD] https://code.claude.com/docs/en/commands (the command reference)
- [ADV] https://code.claude.com/docs/en/advisor
- [GOAL] https://code.claude.com/docs/en/goal
- [HOOK] https://code.claude.com/docs/en/hooks (handler types)
- [SUB] https://code.claude.com/docs/en/sub-agents (fork, Explore/Plan)
- [WF] https://code.claude.com/docs/en/workflows (dynamic workflows, ultracode, size guideline)
- [RT] https://code.claude.com/docs/en/routines
- [IM] https://code.claude.com/docs/en/interactive-mode → "Wait for a usage limit to reset"
- [MC] https://code.claude.com/docs/en/model-config (effort, auto-compact window)
- [BP] https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- [SB] SkillsBench, arXiv 2602.12670 (v1 Feb 2026; NeurIPS 2026 poster), via search summaries
- [PL] https://dev.to/sjh9714/i-benchmarked-claude-code-skills-against-a-placebo-and-half-of-mine-failed-4okk
- [CX] https://learn.chatgpt.com/use-cases/follow-goals (Codex `/goal`); https://developers.openai.com/codex/skills
- [SC] Anthropic `skill-creator` plugin, local copy `~/.claude/plugins/cache/claude-plugins-official/skill-creator/*/skills/skill-creator/SKILL.md`
- [T3] `research/t3-projects.md` (Projects, already covered)

## Bottom line

Most of the 15 "concepts" are real Claude Code features. I confirmed each one against
the official docs. Most are Claude-only, so the template cannot build on them. Two
ideas carry across every runtime and are worth acting on. First, **a skill must beat
"no skill" and a dummy file of the same length, or it goes.** Second, **"done" must be
proved by command output the agent shows, not by its own say-so.** The headline
statistic, "7 of 9 skill packs were no better than a dummy file", **could not be
traced to any source** and is treated as unverified.

## The 15 concepts

Each entry has four parts: **Claim** (what the video says), **Check** (verification),
**Others** (Codex / Copilot / Gemini / Antigravity), and **Template** (what the template
already has, plus the gap).

### 1. Skill packs vs a dummy file
- **Claim.** Someone ran 9 popular Claude skill packs against a dummy file of the same
  length, and 7 of 9 did no better. Models now do most of it natively. A skill should list
  only the corrections the model needs. Run each job with and without the skill, and drop
  the skill if it doesn't win.
- **Check.** The study itself is **unverified**. Four searches found no study of 9 packs
  with a dummy control. Related evidence points in the same direction but is not the same
  claim. [PL] is one author's placebo design (no instruction / a style-only placebo /
  the skill), 496 runs on Opus 4.8, graded by hidden tests. Two of the author's four
  skills failed the gate. Its placebo was about half the skill's length, not equal.
  A blog reports 40 of 47 skills from one viral list made output worse. It is
  anecdotal and part-paywalled. [SB] **cuts the other way**: curated skills raised pass
  rates by about 16 points on average, self-written skills gave about 0 (−1.3 pp), and
  focused 2–3-module skills beat long documentation. So the honest summary is: *some*
  skills help a lot, many don't, and you only know by measuring.
  The "Anthropic says try without a skill first" claim is **verified**. [BP] "Build
  evaluations first": run Claude on the tasks without a skill, record its failures,
  measure a baseline, write minimal instructions. It also says "Claude is already very
  smart. Only add context Claude doesn't already have." The "skill eval plugin" is
  **verified** as Anthropic's `skill-creator` [SC]: it runs each test case with the skill
  and without it ("baseline") in parallel.
- **Others.** Codex reads `SKILL.md` natively under the open agent-skills standard
  ([CX] skills page). Copilot CLI and Gemini also load skills (template already wires
  them). The *method*, comparing against a baseline, needs only a headless run
  (`claude -p`, `codex exec`, `gemini -p`), so it is fully portable. `skill-creator` itself
  is a Claude plugin.
- **Template.** It ships 57 skill directories (three vendored sets plus its own). What
  exists today measures **cost and triggering, not benefit**:
  `scripts/check-skill-descriptions.sh` (7,500-byte ceiling on model-invoked
  descriptions), `work/template-maintenance/trigger-review.md`,
  `docs/stakes-to-ceremony.md` → "Adopting the skills" (roll out gradually, prune what
  you don't use), and "Floors" (log a skill that wastes a session). The idea is already
  written down at sentence level: `skills/writing-for-agents/SKILL.md:90` says to hunt
  "no-ops", meaning instructions the model already obeys by default, and to "settle it by
  running the document". **Gap:** nothing applies that test to a *whole skill*, and no
  skill has ever been shown to beat a baseline. → V1, V2.

### 2. The cheap-model trap
- **Claim.** Switching to a cheaper model mid-session re-reads the whole conversation
  uncached, and a small model can need more retries. Pick one model per job; turn effort
  down instead.
- **Check.** The cache part is **verified indirectly**. [ADV] says toggling the advisor
  keeps the cache "unlike switching models". The "Haiku 5.5 needed more requests / twice
  as long as Sonnet" test is **unverified** (no source named).
- **Others.** Prompt caching is per-model at every vendor I know of, so the same likely
  holds. **Not checked** for Codex, Gemini or Copilot.
- **Template.** `docs/context-budget.md` → "Cache the prefix, vary the tail" covers
  prefix stability, but not model switching. `fleet.sh dispatch-open` already takes
  `--model/--effort` for children, which start fresh anyway. → V4.

### 3. `/advisor`
- **Claim.** A cheap main model consults a stronger one before choosing an approach, on
  repeated errors, and before saying "done". Keeps the cache. Experimental.
- **Check.** **Verified** [ADV][CMD]: all of it, plus Anthropic-API-only and
  model-driven timing.
- **Others / Template.** No equivalent found elsewhere (**unknown**). The portable version
  is a reviewer subagent or `doubt-driven-development`. Skip.

### 4. Is plan mode dead?
- **Claim.** Claude Code staff (Boris Cherny, "Tarik") say plan mode is no longer
  needed. Planning still matters: interview, write the plan to a file, build in a fresh
  session. Skip planning for changes you can describe in a paragraph.
- **Check.** The staff quotes are **unverified** (social posts, not fetched). `/plan` still
  exists [CMD]. `/ultraplan` is "Removed. Use plan mode instead" [CMD].
- **Others.** Codex, Copilot and Gemini each have some plan or ask mode (not checked in
  detail). The *file-based* plan is runtime-neutral.
- **Template.** This is what it already does: `grill-with-docs` / `grill-me`, `to-spec`,
  `plans` (`docs/plans.md`), `wayfinder`, and launchers for a fresh session.
  `docs/stakes-to-ceremony.md` already scales planning to stakes, and the "one-paragraph
  change → skip" rule matches its lowest band. Nothing to do.

### 5. Why `/goal` stops early
- **Claim.** A small model checks the goal after each turn. It reads only the
  conversation, so "the report is finished" is taken on Claude's word. Put proof in
  the condition, e.g. "the check script passes and you show me the output; stop after
  15 turns".
- **Check.** **Verified** in detail [GOAL]: it is a session-scoped prompt-based Stop hook,
  evaluated by the small fast model. "It doesn't run commands or read files independently,
  so write the condition as something Claude's own output can demonstrate." The docs
  recommend "one measurable end state", "a stated check", constraints, and a turn clause.
- **Others.** **Codex has `/goal`** [CX] (behind `features.goals`). It "will stop running
  when it's confident it has reached the stopping condition". Its starter is "Complete
  [objective] without stopping until [verifiable end state]". So the same advice applies
  in both. Copilot / Gemini: **unknown**.
- **Template.** Plan nodes have `## Acceptance` (`docs/plans.md`), and the supervisor
  (`scripts/session-loop.sh`) chains sessions. Nothing says an acceptance line must
  name the command whose *output* proves it, and the docs' own example is
  "Done when the orchestrator says so" (`docs/plans.md:298`). The dispatch contract's
  status line (`DONE | …`) is likewise self-declared. → V3.

### 6. The million-token context trap
- **Claim.** Opus 4.6 scored 93% finding 8 hidden details at 256K tokens and 76% at 1M.
  So load context through pointers, on demand.
- **Check.** 76% at 1M (MRCR v2, 8-needle) is widely repeated. The 93% at 256K comes
  from one secondary source. **Partly verified**; Anthropic's launch post was not fetched.
- **Others.** Holds for every model in principle.
- **Template.** It is ahead here. `docs/context-budget.md` sets WARN at 120K and STOP at
  150K "regardless of advertised window size", and it measures rather than guesses.
  `CONTEXT.md` → "Demand-load, don't pre-load", plus pointer-style docs. The video
  reinforces this; nothing new.

### 7. Projects changed
- **Claim.** A coordinator chat with cloud threads. Only threads can use connectors.
  Threads default to Opus on high effort, so check project settings.
- **Check / Template.** Covered by [T3] (R1–R5, R14). **New in the video only:** threads
  default to Opus/high and burn limits, and the coordinator can't use connectors. Both
  are **unverified**. Neither changes R14; at most add "check the thread model/effort" to
  R14's paragraph.

### 8. Skills that write themselves
- **Claim.** The desktop app's "record a skill" watches you work and writes a small skill
  of your corrections.
- **Check.** **Unverified** (desktop docs not fetched). [SB] found *self-generated*
  skills gave no gain on average, so a recorded skill still needs item 1's test.
- **Others / Template.** Others **unknown**. `retro`, `decision-log` and R3 (`Remember:`)
  already route corrections. Nothing new; V1 tests whatever gets written.

### 9. Settings: leave the defaults alone
- **Claim.** Opus 5.5 is the default; at medium it matches Opus 5 at high and max. Higher
  effort can overthink. Auto mode is default since August. Compaction is tuned per model.
- **Check.** [MC] **verifies** "Opus 5.5 at `medium` matches or exceeds Opus 5 at `high`"
  (not "max"), that only `max` "is prone to overthinking", and that the auto-compact
  window is "tuned for your model". The auto-mode date and "start on Opus" are **unverified**.
- **Others / Template.** Runtime-neutral advice. The template pins no model or effort
  (`.claude/settings.json` is hooks + status line). Its 150K STOP sits below Claude's
  compaction point (`docs/context-budget.md` §Thresholds); revisit only if a model
  compacts earlier. Note only.

### 10. Forks vs subagents
- **Claim.** A subagent starts fresh, and the built-in Explore/Plan agents don't even read
  CLAUDE.md. A fork copies the conversation and shares the cache. Fork mode is on by
  default; manual trigger is `/subtask`.
- **Check.** **Verified** [SUB][CMD]. Explore and Plan "start without your CLAUDE.md
  files". Fork mode is on by default in interactive sessions. `/subtask` makes a forked
  subagent; `/fork` makes a background session copy. Cache sharing on the fork's first
  turn was not confirmed in the part of the page I read.
- **Others.** Codex, Copilot and Gemini have subagents or custom agents in some form
  (template wires `.claude/agents/`; others not checked). No fork equivalent found.
- **Template.** `docs/context-budget.md` → "Dispatching long-running children",
  `scripts/fleet.sh`, `.claude/agents/repo-navigator.md`. **This reinforces R2**:
  children may start without `CONTEXT.md`, so the dispatch brief must name the
  standing-context files. The Explore/Plan fact is a concrete reason, worth one clause
  in R2.

### 11. Claude builds its own team (dynamic workflows / ultracode)
- **Claim.** Claude writes a script that runs dozens of agents and cross-checks them.
  `/deep-research` is the bundled example. Set "dynamic workflow size" to small in
  `/config`.
- **Check.** **Verified** [WF]: a JavaScript script, `/deep-research`, the `ultracode`
  keyword, and a `workflowSizeGuideline` setting (`small` means fewer than 5 agents;
  default `medium`, or `small` on Pro). "Six predefined patterns" is **unverified**.
- **Others.** Claude-only.
- **Template.** `skills/research-wave/SKILL.md` is the runtime-neutral version: parallel
  research, each result fact-checked. Nothing to adopt. R10 already improves research-wave.

### 12. Hooks that check the work
- **Claim.** A hook can be a prompt or a subagent, not just a script. A Stop hook can have
  a second model judge the work and send the reason back. Agent hooks are experimental.
- **Check.** **Verified** [HOOK]: handler types `command`, `http`, `mcp_tool`, `prompt`,
  `agent` (agent is "Experimental"). A Stop block with a reason keeps Claude working.
- **Others.** Codex, Copilot CLI/VS Code, Gemini and Antigravity all have *command* hooks,
  and the template wires all of them (`docs/context-budget.md` → "Vendor hook
  deployments"). LLM-judged (`prompt`/`agent`) hook types were **not found** for them.
- **Template.** It uses Stop hooks only for budget exit (`scripts/hooks/`). There is
  no quality-gate hook, but `scripts/run-checks.sh` is the "Floors" rule. A portable gate
  is a *command* hook that runs a deterministic check. An LLM judge would be Claude-only.
  See "not recommended".

### 13. Routines
- **Claim.** Cloud runs on a schedule, an API call (URL + token) or GitHub events. All
  connectors are included by default, so strip them.
- **Check.** **Verified** [RT]: research preview; all three triggers; "all of your
  connected MCP connectors are included by default … Claude can use every tool …
  including writes, without asking". OpenAI "MCP events" is **unverified**.
- **Others / Template.** Claude-only. The portable equivalent is GitHub Actions or cron
  running a headless CLI. The template has no scheduling layer. Skip.

### 14. Run Claude on someone else's computer
- **Claim.** Cloud sessions via claude.ai/code, desktop or `claude --cloud`; pull back
  with teleport; no extra machine charge.
- **Check.** `/teleport` **verified** [CMD]; `--cloud` and "no extra charge" **unverified**.
- **Others / Template.** Codex cloud and Copilot coding agent are similar (not checked).
  [T3] already noted cloud-sandbox hooks are untested. Nothing new.

### 15. Limit continuation
- **Claim.** When a usage limit hits mid-task, Claude waits and resumes after the reset. On
  by default. Applies to the 5-hour window, not the weekly one.
- **Check.** **Verified** [IM]: "on by default in interactive sessions signed in with a
  claude.ai subscription". It re-arms at most twice, setting `autoContinueAtUsageLimit`.
  For workflows, it holds only when "the limit resets within 24 hours. A weekly limit can
  reset further out" [WF]. That matches the 5-hour/weekly claim. Permission prompts
  can still stall it.
- **Others.** **Unknown.**
- **Template.** `scripts/session-loop.sh` runs hands-off chains (the user runs them
  overnight). It has opt-in silence probes (`SESSION_LOOP_ALARM`,
  `SESSION_LOOP_KILL_AFTER`, both default 0). A session that is waiting quietly for a
  limit reset could trip a non-zero `KILL_AFTER`. Whether chain sessions are interactive
  (and so get auto-continue) was **not checked**. → V5.

## Verdict: **learn-from**

The video is a good survey of Claude Code as of October 2026, and most of its
feature claims check out against the docs. But 10 of 15 items are Claude-only
features (advisor, fork/subtask, workflows, prompt/agent hooks, routines, cloud
sessions, auto-continue, Projects). The template must not depend on them.
What carries across agents is method: measure a skill against a baseline, make
"done" provable, keep context lean, keep model choice stable. The template already
does the last two. The first two are the gaps.

### Candidate recommendations

- **V1. Write the "does this skill earn its place?" test.** (Item 1; reinforces the
  existing "prune" advice.) Add a short procedure to `docs/stakes-to-ceremony.md` →
  "Adopting the skills". Pick 3 representative tasks. Run each in three arms: no skill,
  a dummy file of the same length (plain, plausible, no method), and the skill. Use a
  fresh headless session per run (`claude -p`, `codex exec`, `gemini -p`). Grade with a
  deterministic check where possible, or a blind judge otherwise. Keep the skill only if
  it beats **both** controls. Otherwise trim it to the corrections that win, or remove
  it. Note that results depend on the model, so re-run after a model change. *Cost:* one
  section, about 15 lines. *Value:* high, because it gives the template a pruning rule
  for 57 skills. *Agent-agnostic:* yes.
- **V2. (Optional, after V1) Pilot the test on 3–5 "restates the default" suspects.**
  Choose skills whose bodies mostly describe good default behaviour (prose/style and
  general-quality skills). Record results in `work/template-maintenance/`. Act through
  the existing user-invoke / prune path. Vendored skills are pruned by not shipping them,
  never by editing. *Cost:* moderate, and it bills real tokens (like
  `scripts/context-experiment.sh`). *Value:* medium-high, the first evidence either
  way. *Agent-agnostic:* the method is; a pilot on one runtime is fine. A reusable
  `scripts/skill-baseline.sh` only if the pilot shows it pays.
- **V3. "Done" must be proved by output in the transcript.** (Item 5.) In `docs/plans.md`
  → Format, say each `## Acceptance` line names the command whose output proves it.
  Replace the example "Done when the orchestrator says so". Add one clause to the
  dispatch contract (`scripts/fleet.sh dispatch-contract`, `docs/context-budget.md`
  § Dispatching): a `DONE` return quotes the check command and its result. Same wording
  works for Claude and Codex `/goal`. *Cost:* small; the fleet change needs a test.
  *Value:* high. *Agent-agnostic:* yes.
- **V4. One line: don't switch models mid-session; lower effort instead.** (Item 2.)
  Put it in `docs/context-budget.md` → "Cache the prefix, vary the tail". Children get
  their model at dispatch, which is fine. *Cost:* trivial. *Value:* low-medium.
  *Agent-agnostic:* the advice is; the cache fact is verified for Claude only.
- **V5. Note the usage-limit wait vs the supervisor's silence probes.** (Item 15.) Put
  it in `docs/operational-knowledge.md` (or `docs/context-budget.md` → supervisor):
  Claude's auto-continue waits quietly, possibly for hours, so a non-zero
  `SESSION_LOOP_KILL_AFTER` can kill a session that would have resumed. First check
  whether chain sessions are interactive. *Cost:* a check plus a paragraph. *Value:*
  medium for overnight chains. *Agent-agnostic:* it documents per-runtime behaviour.
- **R2 addendum (not a new V).** In R2's "read these first" list, add the reason:
  Claude's built-in Explore/Plan subagents start without `CLAUDE.md` [SUB].
- **R14 addendum (not a new V).** If R14's Claude-only paragraph is written, add: check
  Projects thread model/effort, and trim routine connectors (all are included by default).

### Not recommended

- **Building on `/advisor`, `/goal`, `/subtask`/`/fork`, dynamic workflows, routines,
  cloud sessions or auto-continue.** All are Claude-only, and several are experimental or
  research preview ([ADV], [RT]). Most are also Anthropic-API-only. `research-wave`,
  `fleet.sh` and `session-loop.sh` already cover the portable needs.
- **A prompt- or agent-type Stop hook as a template quality gate.** These handler types
  are Claude-only, and `agent` is experimental. A deterministic `command` check
  (`scripts/run-checks.sh`) works everywhere and stays the gate.
- **Recommending `skill-creator` as *the* skill-eval tool.** It is a Claude plugin. V1
  states the method so every runtime can run it; Claude users can still use
  skill-creator to carry it out.
- **Mass-deleting vendored skills on the strength of the "7 of 9" claim.** It is
  unverified, and [SB] shows curated, focused skills do help. Measure first (V1/V2).
- **"Record a skill" (desktop).** Claude-desktop-only and unverified. [SB] found
  self-generated skills don't help on average.

## Unverified claims (collected)

"7 of 9 skill packs no better than a dummy" (no source found). Haiku 5.5 retry/latency
test. Boris Cherny / "Tarik" plan-mode quotes (23 Sep). Opus 4.6 93% at 256K (one
secondary source). Opus 5.5 medium vs Opus 5 **max**. Auto mode "default since
August". Fork first turn cheaper via shared cache. "Six predefined patterns" for
workflows. Projects threads default to Opus/high; coordinator can't use connectors.
"Record a skill". `claude --cloud` flag and "no extra charge". OpenAI "MCP events" at
Dev Day.
