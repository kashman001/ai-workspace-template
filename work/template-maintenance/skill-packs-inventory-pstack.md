# Skill pack inventory: pstack (Lauren Tan / "poteto")

Inventory only. It compares pstack with the skills this template already ships
(`skills/vendored-skills.md`, the "Workspace Skills" list in `CONTEXT.md`, the
`skills/` directories). The fit column holds first guesses; the orchestrator makes the call.
Everything below was read from the two local clones. Nothing from them was executed.

## 1. Pack at a glance

- **What it is.** One engineer's working style written as 52 agent skills: 28 workflow skills and 24 one-rule `principle-*` skills. It also has 2 subagent definitions, one automation pack (`automations/benny`), a 10-page user guide, and a Cursor plugin manifest (`.cursor-plugin/plugin.json`, version 0.15.17).
- **Canonical upstream.** `github.com/cursor/plugins`, directory `pstack/`. It is canonical because poteto is Lauren Tan, the author, and the `pstack/` directory carries its own `LICENSE`: MIT, "Copyright (c) 2026 Lauren Tan". The manifest also names her as author.
- **Version checked.** Repo HEAD `11713c6` (2026-10-11). Last commit touching `pstack/`: `978ca6e` (2026-10-10). 51 commits touched `pstack/` since 2026-07-13 (`git log --since=2026-07-13 -- pstack | wc -l`). Very active.
- **How you use it.** Two steps. First run `/setup-pstack`, which writes `~/.cursor/rules/pstack-models.mdc`, a Cursor "always-applied rule" that maps each role to a model. Then start real work with `/poteto-mode`, which picks one of 23 playbooks and calls the other skills as its steps need them.
- **How much it leans on Cursor.** Heavily. Most workflow skills start subagents through Cursor's `Task` tool with named models. The defaults are `claude-opus-5-5-xhigh` for judgment and prose and `grok-4.7-xhigh-fast` for code, and setup-pstack can change them. It also relies on Cursor's `AskQuestion` tool, built-in `create-skill`, Custom Modes (`mode: true` frontmatter), `/loop`, cloud workers (`environment: "cloud"`), `~/.cursor/projects/*/agent-transcripts`, the `mcps/` directory, and the separate `cursor-team-kit` plugin (`deslop`, `control-ui`, `control-cli`).
- **What the multi-runtime port changed** (`michael-denyer/pstack-claude`, `5f07f5e`, 2026-10-10, MIT, copyright Lauren Tan and Michael Denyer; synced from upstream `df58112`, 2026-10-05):
  - `tools/forks.json` lists 47 deviations. 7 are "port-feature" rewrites that were needed to run outside Cursor: setup-pstack, reflect, poteto-help, create-verification-skill, and the multi-phase-plan and orchestrate playbooks plus `check-plan.mjs`. The other 40 are "policy" changes, where the port simply prefers different rules.
  - `tools/substitutions.json` has 74 mechanical rewrites: `Task` becomes `Agent`, Cursor transcript paths become `~/.claude/projects/...`, plugin agents get a namespace, and so on. Model names now come from `models.json`, which defaults to Claude families: opus, fable, sonnet, haiku.
  - Cursor's always-applied rule is replaced by a "model sheet" file per runtime. Claude Code loads it with an `@` include, Codex gets it pasted into AGENTS.md, and Copilot reads it through a SessionStart hook. Codex, Copilot, and Pi get tool-name mapping docs. Pi gets an extension that supplies subagents, a question tool, wakeups, and `/loop`.
  - For OpenCode and Gemini CLI, `docs/reference.md` offers a "shared skills installation": symlink the skills into `~/.agents/skills/`. Only discovery was checked, and only on OpenCode. Subagent and multi-model workflows are unverified there.
  - The port excluded `make-bot-ui`, `automations/`, `docs/`, the README, sticky-mode metadata, and `worktree-audit.sh`. `ketchup` is missing only because it landed upstream after the port's last sync. The port added 7 cursor-team-kit skills and its own `babysit`.

## 2. Workflow skills (28 non-principle)

Size = SKILL.md lines / number of supporting files. Invocation: every skill except setup-pstack has `disable-model-invocation: true`, so the user types it as a slash command or poteto-mode calls it. "PM" means poteto-mode routes to it.

| skill | purpose (one line) | invocation | size | runtime / tool dependencies | depends on pstack skills | closest existing skill | first-guess fit |
|---|---|---|---|---|---|---|---|
| architect | Write types and signatures with stub bodies first, compare designs from several models, then implement against the chosen one | slash; PM (code that crosses a function boundary) | 79 / 3 | model sheet "architect runners"; named models (opus, grok); spawns subagents through arena | how, why, arena, interrogate, 6 principles | codebase-design, prototype, design-for-testability | overlapping: adds a multi-model "design it twice" step before coding |
| arena | Run N attempts at one task in parallel, pick the best as a base, graft in the good parts of the others | slash; PM; called by architect, blast-radius, eval | 48 / 0 | Task subagents in background; model sheet; named models; git worktrees or `/tmp` | 3 principles | none (research-wave is parallel research, not rival attempts) | new capability: best-of-N with a cross-judge and grafting |
| automate-me | Turn the user's habits into a personal `<name>-mode` skill by mining transcripts and asking questions | slash | 104 / 0 | Cursor `AskQuestion`, built-in `create-skill`, `.cursor/skills` paths, Cursor transcript directory, parallel subagents, worktree + PR | unslop, poteto-mode (as the model to copy) | retro, writing-for-agents | overlapping: retro already improves the environment; this one is tied to Cursor |
| benchmark-checklist | Seven questions that vet a performance number before you report or act on it | slash; PM; principle explain-the-number | 39 / 0 | shell tools only (`uptime`, `nproc`, profilers) | Opening-a-PR, Perf, and Hillclimb playbooks (mentions only) | diagnosing-bugs (covers perf partly) | new capability: no existing benchmark-vetting checklist; plain text |
| blast-radius | Find what a change breaks outside the diff, and prove by running code the one fact that makes it safe | slash | 50 / 0 | git, `gh` (via why step 2); arena optional | how, why, arena, unslop | code-review, design-for-testability | new capability: proof-by-execution of safety; code-review reviews the diff only |
| bro | Restate the last message in plain words | slash | 7 / 0 | none | none | wait-what | duplicate: same job as wait-what |
| correct | Find mistakes agents repeat in this repo and make each impossible: architecture, then types, then lint, then test, then docs | slash | 32 / 0 | git history and review comments; CI | none | retro, decision-log | overlapping: like retro, but sets a fix order and requires proof each check fails |
| create-verification-skill | Generate a project-local skill that launches, drives, and captures evidence from the real app | slash; offered by setup-pstack | 44 / 3 | writes to `.cursor/skills/verify-<app>/` (the port renames it `verify`); browser/CDP, tmux/PTY, HTTP as needed | maintain-verification-skill | none (Claude Code's built-in `run` is not a workspace skill) | new capability: a reusable "drive the real app" harness per repo |
| figure-it-out | Design a custom, auditable playbook for big work that fits no playbook, then run it as hypothesis loops | slash; PM (large or cross-cutting work) | 52 / 0 | none directly | poteto-mode, architect, arena, show-me-your-work, 7 principles | plans, wayfinder | overlapping: plans and wayfinder already cover big multi-step work |
| how | Explain how a subsystem works, using explorer and explainer subagents | slash; PM; called by architect, teach, no-comments | 36 / 2 | Task subagents (readonly); model sheet; named models (grok explorers, opus explainer) | none | repo-navigator agent, graphify, onboard-repo | overlapping: same question; this one adds a fixed explanation format |
| interrogate | Several models review a diff adversarially; the lead sorts findings into act / consider / noted / dismissed | slash; PM (contested design) | 74 / 4 | Task subagents, one per configured model; model sheet; named models; git diff | none | code-review, doc-review | overlapping: code-review exists; this one gets its diversity from different models |
| ketchup | Catch the user up on everything since their last message, with an executive summary per action item | slash | 23 / 0 | reads PR, CI, and agent status (`gh`) | bro | wait-what, handoff, checkpoint | new capability (small): "what did I miss" in chat; handoff is for another agent |
| maintain-verification-skill | Keep a verification skill and its feature map honest: source check per feature, one live pass, at most one PR | slash | 39 / 0 | parallel read-only subagents; drives the app; `.cursor/skills/verify-*` path | create-verification-skill | none | new capability, but useless without create-verification-skill |
| make-bot-ui | Build a local web page whose buttons wake a Cursor "Grok Bot" routine over a webhook, reachable on Tailscale | slash | 115 / 0 | Cursor routines (`update_state`), `SendToUser` secret request, `api2.cursor.sh`, Tailscale, sudo install | none | none | drop: only works inside Cursor's bot product |
| no-comments | Spawn the "Comment Sicko" reviewer to delete comments, then fix or encode what they hid | slash; PM (before review) | 24 / 0 | the `Comment Sicko` agent (agents/comment-sicko.md); Task | architect, how, why, 2 principles | code-review | new capability (narrow): a comment-deletion pass; needs the agent file |
| poteto-help | Router: answers "which pstack skill or playbook fits?" and gives a prompt to type | slash | 154 / 2 | Cursor install steps, Custom Modes, `/loop`, model rule path, links to the public GitHub copy | all of pstack | ask-matt | duplicate pattern: ask-matt routes the vendored set; this routes pstack only |
| poteto-mode | Always-on working style: non-negotiables, principle index, autonomy rules, subagent rules, 23 playbooks | slash; Cursor Custom Mode (`mode: true`); `poteto-agent` reads it | 147 / 44 (23 playbooks, 1 reference, 20 script files) | Task subagents with per-role models; `AskQuestion`; `/loop`; cloud workers; `cursor-team-kit` (deslop, control-ui/cli); Bugbot; `gh`; Bun/TypeScript scripts (watch-pr, orch, check-plan) | nearly every pstack skill and all 24 principles | plans, implement, checkpoint, session-rollover | overlapping as a whole; useful parts are the playbook texts (section 4) |
| recall | Rebuild the user's recent context on a topic from past chat transcripts plus the shared record | slash | 35 / 0 | Cursor transcript path `~/.cursor/projects/<slug>/agent-transcripts`; parallel subagents; `git`, `gh`; MCPs via why | why, unslop, session-pickup playbook, automate-me | handoff, session-rollover, checkpoint (launcher + ledger) | overlapping: the workspace keeps state on disk in `work/` instead of mining transcripts |
| reflect | Three reviewer subagents mine the transcript for lessons and route each to a skill edit | slash | 67 / 4 | Cursor transcript path; Task with write access (for MCPs); model sheet; named models; Cursor `create-skill` | 1 principle | retro | duplicate-ish: retro does the same job without multi-model reviewers |
| setup-pstack | Pick a reasoning budget and a model per role; write the Cursor rule file | slash; model-triggered (the only one without `disable-model-invocation`) | 74 / 0 | writes `~/.cursor/rules/pstack-models.mdc` (`alwaysApply`); `AskQuestion`; detects Task model slugs | create-verification-skill | none (jev is unrelated) | drop as written: pure Cursor config; the port had to rewrite it per runtime |
| show-me-your-work | Append-only TSV decision log, one row per decision, audited against the transcript and checked by a second model | slash; PM (long or unattended work); principle prove-it-works | 82 / 2 (`scripts/log.sh`, a template TSV) | bash script; Cursor transcript path for the audit; a subagent on a different model family | unslop, 1 principle | decision-log (Tier 2 `decisions.md`), handoff.md ledger | overlapping: decision-log records why; this is a per-step audit trail |
| swarm | Fan out N cloud workers over slices or races; collect one report | slash; PM | 46 / 0 | Task with `environment: "cloud"` (Cursor cloud agents), `cloud_base_branch`; model sheet; named models | none | research-wave, implement-spec (parallel subagents) | overlapping: parallel fan-out exists; the cloud-worker part is Cursor-only |
| tdd | Fix a bug test-first, only when a cheap local test exists | slash; PM | 42 / 0 | none | none | tdd (Matt Pocock) | duplicate, and the name collides; narrower than the existing tdd |
| teach | Explain a body of work plainly, built on `how` and `why`, with step-by-step diagrams | slash | 21 / 0 | mermaid; an image-generation tool | how, why, unslop | teach (Matt Pocock) | overlapping, and the name collides: existing teach teaches a concept; this one explains code |
| technical-writing | Layered writing standard for docs, RFCs, PRs, and commits: Diátaxis, Google style, STE, Global English | slash; PM (any doc, PR, or commit) | 106 / 0 | none | unslop | writing-for-agents (agent-facing), doc-review | overlapping, but adds human-facing doc rules the workspace lacks |
| typescript-best-practices | Rule table for TypeScript types: unions, brands, no `as`, exhaustiveness | slash (the `paths:` glob frontmatter is a Cursor feature) | 31 / 1 | none | 2 principles | none | new capability, but language-specific; may be out of template scope |
| unslop | Numbered catalog of AI-prose tells to remove | slash; PM (every prose surface) | 62 / 0 | none | none | writing-for-agents (style for agent readers) | new capability: no prose-tell catalog today; plain text |
| why | Find why code is shaped as it is: git, PRs, and one investigator subagent per available MCP category, plus a confidence-graded synthesis | slash; PM; called by architect, teach, recall, blast-radius, no-comments | 98 / 12 (prompts, epistemics, 8 source playbooks) | Task with write access (MCPs); Cursor `mcps/` directory discovery; model sheet; named models; `git`, `gh` | none | research, decision-log | new capability: recovers rationale from history; nothing does this today |

## 3. Principle skills (24)

All 24 are short: 15 to 34 lines each, 495 lines in total, with no supporting files. None mentions Cursor, model names, or poteto-mode (checked with grep). Each reads on its own as a rule plus examples. Some link to sibling principles by relative path. Two link outside the principle set: explain-the-number to benchmark-checklist, and prove-it-works to show-me-your-work. They all have `disable-model-invocation: true`. In practice they act only when poteto-mode's principle index tells the agent to read one, or when the user types `/principle-<name>`. Brought in on their own, they would be inert reference docs unless something points at them.

| principle | the rule in one sentence | lines | echoes in the workspace |
|---|---|---|---|
| attack-the-premise | After two failed fixes that share an assumption, question the assumption, not the fix. | 23 | — (diagnosing-bugs skill is near) |
| boundary-discipline | Validate and handle errors at system edges; trust internal types; keep logic pure. | 34 | — |
| build-the-lever | For non-trivial work, build the script or tool that does or proves it instead of working by hand. | 23 | — |
| encode-lessons-in-structure | Turn a repeated instruction into a lint, check, or script, not more text. | 28 | partial: Goal-driven ("a new check counts only once seen to fail") |
| exhaust-the-design-space | With no precedent, build 2 or 3 competing prototypes before committing. | 21 | Think before coding ("surface tradeoffs"); prototype skill |
| experience-first | When convenience and user delight conflict, choose delight. | 19 | — |
| explain-the-number | Before trusting a measured number, find its limiter and rule out measuring the wrong thing. | 17 | partial: Goal-driven ("report only commands you ran") |
| fix-root-causes | Trace each symptom to its root cause; no guards that hide crashes. | 23 | — (diagnosing-bugs skill) |
| foundational-thinking | Get the core types and data structures right before writing logic. | 21 | partial: Think before coding |
| guard-the-context-window | Send bulky work to subagents; keep only summaries in the main thread. | 16 | strong: Agent Context Discipline (demand-load, targeted reads) |
| laziness-protocol | Smallest change that solves the problem; bias toward deleting. | 18 | strong: Simplicity first |
| make-operations-idempotent | Commands and loops reach the same end state after crashes and retries. | 24 | — |
| migrate-callers-then-delete-legacy-apis | Move all callers and delete the old API in the same wave; no compatibility layers. | 22 | tension with Surgical changes |
| minimize-reader-load | Count the layers and hidden state a reader must track; collapse one-caller wrappers. | 18 | partial: Simplicity first |
| model-the-domain | Encode the domain in one structure (state machine, table, typed model) instead of scattered ifs. | 24 | — (domain-modeling skill is about words, not code shape) |
| never-block-on-the-human | Do reversible work without asking; let the human correct afterwards. | 15 | tension with Think before coding ("ask when uncertain") |
| outcome-oriented-execution | In planned rewrites, aim at the end state; don't keep throwaway in-between states. | 21 | — |
| prove-it-works | Check the real artifact before saying done, not a proxy or "it compiles". | 22 | strong: Goal-driven execution |
| redesign-from-first-principles | Fold a new requirement in as if it had been there from day one; don't bolt it on. | 16 | tension with Surgical changes |
| separate-before-serializing-shared-state | If parallel actors might write the same thing, remove the sharing before adding locks. | 16 | — (memory note on concurrent sessions is near) |
| sequence-verifiable-units | Break work into small units that each end in a check; verify each before the next. | 17 | strong: Goal-driven ("plan with a check per step") |
| subtract-before-you-add | Remove dead weight first, then build. | 18 | partial: Simplicity first; tension with Surgical ("mention dead code, don't delete it") |
| test-behavior-not-implementation | A test calls code the way users do; delete tests that pass when everything returns undefined. | 21 | — (tdd skill) |
| type-system-discipline | Make illegal states unrepresentable; brand primitives; parse at boundaries. | 18 | — |

The port changed three principles (attack-the-premise, prove-it-works, test-behavior-not-implementation) as "policy" forks. Even the plain-text principles have drifted between upstream and the port.

## 4. poteto-mode and its 23 playbooks

**What it does.** poteto-mode is a working-style skill. Its sections are: non-negotiable triggers ("any code: name the data shape", "contested design: interrogate", "any prose: unslop", "before review: no-comments"), an index of the 24 principles with when each applies, autonomy rules ("just do it" except irreversible writes), subagent rules, reply-writing rules, and a list of playbooks. On a task it matches a playbook, copies that playbook's steps into a todo list word for word, and routes to other skills as steps fire. A step it skips stays in the list marked `skip: <reason>`.

**How it dispatches.** Yes, it spawns subagents, and it is built on them. Every subagent inside a playbook step uses `subagent_type: "poteto-agent"` (agents/poteto-agent.md), runs in the background, and gets an explicit model per role. Defaults: `grok-4.7-xhigh-fast` for code delegates, `claude-opus-5-5-xhigh` for judgment, prose, and the hardest changes, all overridable in the Cursor model rule. Cursor-specific features it needs: Custom Mode (`mode: true`, `reminder:` frontmatter) to stay on across turns, `AskQuestion`, `/loop` for long runs, cloud workers, Cursor's built-in `create-skill` and babysit, `cursor-team-kit` (`deslop`, `control-ui`, `control-cli`), Bugbot review triage, and Origin, which appears to be a merge CLI. It also ships about 6,700 lines of Bun/TypeScript scripts (`watch-pr`, `orch`, `check-plan.mjs`, `bootstrap.ts`) plus `worktree-audit.sh`. Including those scripts, the skill directory is 7,581 lines. The playbook texts alone are 620 lines.

Playbooks. "Neutral" means plain process text that runs on any agent; at most it names a default model or mentions `/loop` once. "Needs Cursor/tooling" means it depends on Cursor features or the bundled scripts.

| playbook | lines | for | runtime |
|---|---|---|---|
| investigation | 14 | read-only "how / why / are we sure" question | neutral |
| bug-fix | 15 | reproduce, root-cause, fix with runtime evidence | neutral (mentions `/loop` and the grok default once) |
| perf-issue | 25 | trace a measured slowness against a baseline | neutral (grok default) |
| hillclimb | 21 | loop on one metric, one commit per accepted win | neutral (grok default) |
| runtime-forensics | 11 | diagnose a live symptom from instrumentation | neutral |
| trace-forensics | 14 | diagnose a captured profile or trace file | neutral |
| feature | 21 | new behavior built from a named data shape | neutral (arena; grok default) |
| refactoring | 16 | behavior-preserving structural change | neutral (grok default) |
| prototype | 14 | throwaway sketch that settles a design fork by observation | neutral (no runtime terms at all) |
| visual-parity | 11 | pixel-exact UI match between two implementations | mostly neutral (`/loop` per component; needs a UI driver) |
| authoring-a-skill | 12 | write or edit a SKILL.md | needs Cursor's `create-skill` (swap for writing-for-agents) |
| eval | 25 | blinded test of a skill or prompt change | mostly neutral (arena; Cursor transcript path) |
| babysit | 27 | drive a PR or stack to merge-ready | needs tooling: `watch-pr` script, Bugbot, Origin, `/loop` |
| shipping | 17 | verify a green stack, land it bottom-up | needs tooling: `watch-pr`, Origin, control-ui/cli, cloud |
| autonomous-run | 13 | drive one task to a checkable predicate without stopping | needs Cursor `/loop` as the wake mechanism (the text is otherwise neutral) |
| orchestrate | 111 | multi-day program, many PRs, fleets of subagents | needs Cursor cloud workers and the `orch.ts` store |
| autopilot-full | 13 | queue of PRs, one owner each, run to merged | needs Cursor: cloud, `/loop`, Bugbot, cursor-team-kit |
| autopilot-stack | 16 | build one linear stack for the operator to land | needs Cursor: cloud, `/loop`, Bugbot, deslop |
| session-pickup | 11 | resume another agent's in-flight work | mostly neutral (Cursor transcript path, cloud-agent URL) |
| pause-safely | 10 | stop cleanly with a resume note | neutral |
| multi-phase-plan | 155 | write a plan for phased or stacked-PR work | needs tooling: `check-plan.mjs`, swarm, cloud, control-ui |
| worktree-cleanup | 14 | prune merged worktrees and old iOS simulators | needs `worktree-audit.sh` and a `~/.cursor/worktrees` path |
| opening-a-pr | 34 | open a PR from small ordered commits | needs cursor-team-kit `deslop` and Origin; the commit and body rules are neutral |

## 5. Agents, automations, docs/guide

| item | what it is | runtime-neutral form possible | inherently one runtime? |
|---|---|---|---|
| agents/poteto-agent.md (9 lines) | subagent definition that reads poteto-mode in full before any work | doc or skill note ("subagents must read X first"); `.claude/agents/` for Claude Code only | the file format is Cursor/Claude-style; the idea is neutral |
| agents/comment-sicko.md (32 lines) | persona reviewer that deletes comments, with a fixed list of exceptions | fold into no-comments as a reviewer prompt | no, it is plain prompt text |
| automations/benny (12 files, 1,612 lines) | two Cursor automations for Slack bug reports: triage, then reproduce and draft a fix | drop | yes: Cursor automations, `.cursor/automations`, `.cursor/settings.json`, Slack |
| docs/guide (11 pages, 1,104 lines, 6 images) | user tutorial: setup, poteto-mode, understand, design, build, verify, overnight, principles, customizing, recipes | at most a doc for a few ideas; mostly drop | largely yes: written around Cursor install, Custom Modes, `/loop` (the port excluded it) |
| .cursor-plugin/plugin.json | Cursor plugin manifest | drop | yes |

## 6. Name collisions with `skills/`

- **Exact:** `tdd` (pstack: bug-fix-only, test only when cheap; existing: red-green-refactor in vertical slices) and `teach` (pstack: explain code via how and why; existing: teach the user a concept).
- **Near, same job under another name:** `bro` vs `wait-what`; `poteto-help` vs `ask-matt`; `reflect` vs `retro`; `show-me-your-work` vs `decision-log`; `figure-it-out` vs `plans` / `wayfinder`; `recall` vs `handoff` / `session-rollover`; `interrogate` vs `code-review` (which already collides with Claude Code's built-in `/code-review`).
- **Shared words, different jobs:** pstack's `prototype` playbook vs the `prototype` skill (same idea, close fit); pstack's `orchestrate` playbook (no skill of that name); `create-verification-skill` vs Claude Code's bundled `/verify`. The port renamed the generated skill `verify` to replace that built-in, which would be a new collision here.

## 7. Risks for vendoring

- **License.** No concern. Upstream `pstack/LICENSE` is MIT, "Copyright (c) 2026 Lauren Tan". The port is MIT with two copyright lines (Lauren Tan and Michael Denyer), and it also ships `LICENSE-cursor-team-kit` (MIT, "Copyright (c) 2026 Cursor") for the 7 skills it took from that plugin. Copying from the port means carrying both notices. Copying from upstream needs only Lauren Tan's.
- **Model sheet dependency.** 9 skills read `pstack-models.mdc` role lines: architect, arena, how, interrogate, reflect, swarm, why, poteto-help, setup-pstack. They fall back to hard-coded `claude-opus-5-5-xhigh` / `grok-4.7-xhigh-fast` slugs. Outside Cursor those slugs mean nothing and grok may not be available. The port replaced this with `models.json` plus a per-runtime sheet.
- **Skills that call other skills.** Calls are mostly by bold name (`**how** skill`); a few use `/name` (no-comments calls `/architect`, `/how`, `/why`; ketchup calls `/bro`; setup-pstack calls `/create-verification-skill`). The dependency web is dense. architect needs how, why, arena, and interrogate. teach needs how and why. figure-it-out needs poteto-mode, architect, arena, and show-me-your-work. poteto-mode needs nearly everything. Vendoring one of these alone leaves broken references.
- **Cursor paths and primitives in the text.** `~/.cursor/rules/`, `.cursor/skills/`, `~/.cursor/projects/*/agent-transcripts` (automate-me, recall, reflect, show-me-your-work, eval and session-pickup playbooks), the `mcps/` directory (why), `AskQuestion` (automate-me, poteto-mode, setup-pstack), `environment: "cloud"` (swarm), Cursor `create-skill` (automate-me, reflect, poteto-mode), and `cursor-team-kit` skills that are not in this pack (poteto-mode).
- **Bundled code.** poteto-mode carries about 6,700 lines of Bun/TypeScript tooling (watch-pr, orch) that the port forked heavily: 15 of its 47 fork entries are poteto-mode scripts. Vendoring poteto-mode means owning that code or cutting the playbooks that use it.
- **Biggest skills.** Counting SKILL.md lines alone: poteto-help 154, poteto-mode 147, make-bot-ui 115, technical-writing 106, automate-me 104, why 98. With supporting files: poteto-mode 7,581, why 920, typescript-best-practices 355, interrogate 318, poteto-help 252, reflect 246. The whole `skills/` tree is 11,720 lines, not counting `bun.lock`.
- **Churn.** 51 upstream commits in 90 days, and the port is already 5 days behind with 47 local forks. Any vendored copy needs a pinned commit and a refresh path like the one in `skills/vendored-skills.md`.
- **Philosophy clashes with CONTEXT.md.** never-block-on-the-human and poteto-mode's "just do it" autonomy conflict with "ask when uncertain" and "push of main is the user's call". redesign-from-first-principles, subtract-before-you-add, and migrate-callers-then-delete conflict with "surgical changes".
