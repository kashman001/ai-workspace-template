# T3 — Claude Code redesigned Projects

Track T3 of `work/external-tools-review/`. Research only; no template files changed.

**Sources** (fetched 2026-10-18):
- [A] Article: https://claude.com/resources/articles/projects-redesigned (2026-09-17)
- [D] Docs: https://code.claude.com/docs/en/claude-projects ("Let Claude coordinate ongoing work with Projects")
- [W] Docs: https://code.claude.com/docs/en/claude-code-on-the-web (cloud sessions)

Overlap: `work/concurrent-sessions/` asks whether several *sessions* can each own part
of one work item (today: one owner + subagents, `docs/context-budget.md` → "Who owns
a work item"). Its research is not written yet (handoff block 1 is only the
scaffold). Projects is a vendor's answer to the same question. See §3 item 2; feed
this note into that item's research instead of repeating it here.

## 1. What it is

- **Goal-driven coordinator chat.** "You describe what needs to get done and Claude
  manages the work": it scopes, delegates, coordinates parallel work, reviews outputs,
  assembles the result [A]. The project conversation is "one long-running session where
  Claude acts as coordinator… It sees what threads report back, not every step they
  take" [D §How a project is organized].
- **Parallel threads.** Each thread is "a separate session with its own context window
  that does one piece of work and reports back"; a cloud thread "works on its own
  branch and opens a pull request" [D]. Overlapping edits surface as ordinary PR merge
  conflicts [A]. Threads can use subagents, loops and workflows themselves [A].
  There is no fixed concurrency; the only hard limit is "200 new threads per day across
  your projects". A thread limit you ask for "is a preference rather than a cap" [D §Usage and cost].
- **Local threads.** The article says local running is "coming very soon" [A]. The docs
  (newer) already describe "Run a thread on your own computer" through Remote Control.
  Such a thread starts with the project instructions "but not with its memory files
  loaded", and runs only while that machine is awake [D].
- **Shared memory.** "Every thread now adds to and draws from a shared memory" [A].
  Concretely, it is notes "stored as files. Every cloud thread reads the index file
  `MEMORY.md` when it starts and opens the other files when it needs them". Users can
  read, edit and delete them in Project settings > Memory. They are kept apart from
  local auto memory and from repo `CLAUDE.md` [D §Give a project standing context].
  Coordination preferences (check-in cadence, threads at once) are saved to memory as
  soft instructions [D §Tune how Claude runs a project].
- **Project instructions.** Up to 16,000 characters, sent to every new thread and to the
  coordinator. Edits reach new threads only [D].
- **Library.** A tab holding user-added files/folders plus files threads produced;
  threads read them under `/mnt/project-files` (limits: 100 files / 2 GB per pick,
  10 folders) [D §Add files and folders]. The article says new work can "build on past
  efforts" through it [A].
- **Overview pane.** Threads are grouped Ready for review / Waiting on you / Working /
  Landing / Idle / Resolved, with tabs for Library, Pull requests and Routines [D].
- **Context.** "You don't manage context windows in a project": threads auto-compact.
  The coordinator works from recent messages, recent threads and memory rather than
  its full history [D §Choose models and let Claude manage context].
- **Constraints** [D §Limitations]: works on web, desktop and mobile only, not the CLI,
  VS Code or JetBrains, and not on Bedrock/Vertex/Foundry. Anthropic is the only model
  provider. One user per project, no sharing, no org controls in the beta. Threads
  can't be moved or exported. Cloud threads need the Claude GitHub App installed on
  each repository [W]. Public beta on Pro/Max only, not Team/Enterprise [D].
  Delete removes memory and files permanently [D].

## 2. What the template already has, per capability

| Projects capability | Template equivalent | Pointer |
|---|---|---|
| Coordinator chat | The work item's single **owner session**. It reads the launcher and picks work from the plan frontier. Across sessions, the supervisor chains successors | `docs/context-budget.md` → "Who owns a work item", "The supervisor"; `scripts/session-loop.sh`; `scripts/plan.sh frontier` |
| Goal statement | Work item README "What this is" + "Success criteria"; plan node `## Goal` / `## Acceptance` | `docs/work-directory-conventions.md`; `docs/plans.md` → "Format" |
| Parallel threads | Subagents under the owner, run under the dispatch contract (report file as heartbeat, capped return, status first line); `research-wave` for parallel fact-checked work | `scripts/fleet.sh` (`dispatch-open/-contract/-list`, `children`); `docs/context-budget.md` → "Dispatching long-running children"; `skills/research-wave/SKILL.md`; `.claude/agents/` |
| Thread isolation (branch per thread) | Worktrees, with coordination state pinned to the main checkout | `docs/context-budget.md` → "Worktrees" (TADR-0006) |
| Overview pane (state groups) | `plan.sh status` derives node state, and `hitl` nodes play the role of "waiting on you"; `fleet.sh dispatch-list` shows open child generations | `docs/plans.md` → "`plan.sh`" |
| Shared memory | Kept in files in the repo, readable by any runtime: `GLOSSARY.md` (terms), `work/<item>/decisions.md` + `docs/adr/` (why), `docs/operational-knowledge.md` (pitfalls), ledger `handoff.md` (what happened) | `CONTEXT.md` → "Decision Records", "Agent Context Discipline" |
| Project instructions | `CONTEXT.md` (symlinked as CLAUDE.md/AGENTS.md/GEMINI.md) + the work item README + launcher | `CONTEXT.md`; `work/<item>/next-session.md` |
| Library | Per-item artefacts under `work/<item>/` (research/, briefs/, HTML twins); `docs/README.md` index | `docs/work-directory-conventions.md` → "Required and optional files" |
| Context management | Measured context budget with WARN/STOP and pruned rollover (the template measures and hands off; Projects auto-compacts) | `docs/context-budget.md`; `skills/session-rollover/` |

Where the template is ahead: it works with any runtime and offline, and it keeps
memory in git, where changes are visible in diffs, reviewable and shared with
collaborators. Context is measured, not implicit.

## 3. Gaps it would fill / ideas worth borrowing

1. **The coordinator "sees what threads report back, not every step"** [D]. This is
   already the dispatch contract's capped return. It confirms the design; nothing new.
2. **Several long-lived workers per item, each a full session**, each with its own
   branch, and conflicts resolved at PR time. This is exactly the open
   `work/concurrent-sessions/` question. Projects avoids every one-owner assumption
   (`seq`, ledger, launcher) because each thread has **no ledger of its own**: the
   coordinator is the only owner, and threads are disposable workers that report back.
   That suggests a cheap path for concurrent-sessions: keep one owner, and promote
   long-running subagents to *separate sessions on worktrees* that report through
   dispatch records, without giving them co-ownership.
3. **A memory index read at thread start, details opened on demand** (`MEMORY.md` +
   files) [D]. The template's memory is spread over four files with no single index
   that a dispatched child is told to read. Gap: a dispatch brief has no standard
   "standing context" pointer list.
4. **Corrections become memory** ("when you correct a thread, also tell Claude to
   remember the correction") [D §Write project instructions]. The template has
   operational-knowledge and decision-log, but no prompt step that routes a correction
   given to a child back to durable memory.
5. **An attention view grouped by state** (Ready for review / Waiting on you / Working…)
   [D]. `plan.sh status` + `dispatch-list` hold the data, but nothing shows one
   "what needs me" line across plan nodes and open dispatches.
6. **Soft coordination preferences** (threads at once, check-in cadence) stored as
   memory [D]. In the template these are conversation-only today.
7. **"Commit and push work in progress" on long tasks**, because sandboxes can lose
   uncommitted changes [D §Limitations]. The same risk applies to worktree children;
   the dispatch contract checkpoints a report file but does not require commits.

## 4. Cost / risk

- **Agent-agnosticism (hard requirement):** Projects is Claude-only and Anthropic-only.
  It does not run in the CLI, VS Code, JetBrains or third-party providers, and needs a
  Pro/Max account plus the GitHub App [D][W]. Codex, Gemini, Copilot and offline
  downloaders get nothing from it. At most it can be an optional layer that a Claude
  user points at the template repo.
- **Lock-in / portability:** memory and library live in Anthropic's UI, not git. A
  project can't be shared, threads can't be exported, and delete is irreversible [D].
  That is the reverse of the template's rule that disk is the source of truth.
- **Two memories drift:** project memory is separate from repo `CLAUDE.md`/files [D].
  A user running both would have two sources of truth. Local threads don't even load
  project memory [D].
- **Cost:** every thread is a full session; "projects can reach usage limits faster" [A][D].
- **Compatibility is good:** cloud threads load `CLAUDE.md`, skills and `.claude/agents`
  from every repo [D §What threads pick up]. So template guidance reaches a
  Projects thread automatically, but hooks (budget measurement) apply only with a
  single repository, and plugins are not loaded [D]. **(unverified in practice:** whether
  `scripts/context-budget.sh` hooks run usefully in a cloud sandbox was not tested.)

## 5. Verdict: **learn-from**

Projects is a polished, Claude-only, cloud-hosted version of what the template already
does with portable files: one coordinator, disposable parallel workers that report
back, standing instructions, shared memory, an artefact store. Adopting it would break
the agent-agnostic, offline, memory-in-git requirements, so it cannot be the
template's mechanism. Its design choices are worth copying, though. Workers have no
ownership. Memory is an index file with details loaded on demand. Corrections are
promoted to memory. One view answers "what needs me". Those choices answer parts of
`work/concurrent-sessions/` cheaply. A short note telling Claude users that Projects
can sit on top of the template (threads already read `CLAUDE.md` + skills) is the most
it should get as an integration.

## 6. Candidate recommendations

1. Feed §3.2 into `work/concurrent-sessions/` research as the vendor reference design: one owner, sessions as workers, no co-ownership.
2. Add a "standing context" line to `fleet.sh dispatch-contract` output that lists the files a child must read first (CONTEXT, GLOSSARY, item README, decisions.md).
3. Add a dispatch-contract clause: "a correction you received that should outlive this task goes in your report under `Remember:`", which the parent then routes to decisions/operational-knowledge.
4. Add a dispatch-contract clause for worktree children: commit work in progress at each checkpoint.
5. Consider a `plan.sh`/`fleet.sh` "needs-me" summary that merges `hitl` nodes, BLOCKED/NEEDS_CONTEXT returns and open dispatches (low priority).
6. One paragraph in `docs/recommended-tooling.md`: Projects is an optional Claude-only layer; threads load `CONTEXT.md`/skills, but hooks run only for single-repo projects and project memory is not in git.
