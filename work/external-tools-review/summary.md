# Six outside subjects: what the template should take from them

One-page summary. The full reasoning is in `synthesis.md` and the four notes
in `research/`. T5 and T6 were added in session 3 at your request. HTML version: `summary.html`.

## Words used here

- **Template** — this repo: the starter kit of instructions, skills and scripts
  that people copy to run AI coding agents on their own projects.
- **Agent-agnostic** — works the same in every AI tool people use with the
  template (Claude Code, Codex, Gemini, Copilot), not just one.
- **Vendor** — copy someone else's code or instructions into the template and
  keep them in step with the original.
- **Child / worker** — a helper agent that a main agent sends off to do one
  task and report back.
- **Dispatch contract** — the standard instruction sheet the template gives
  every long-running helper agent (`scripts/fleet.sh dispatch-contract`).
- **CLI** — a command you run in a terminal. The template prefers these over
  heavier add-ons ("CLI-first").
- **Skill** — a file of instructions an agent loads for one kind of task
  (`skills/<name>/SKILL.md`).
- **MCP** — a plug-in protocol that lets an agent call an outside service.
- **AGPL** — a "copyleft" license: copying its code into the template would
  put the template's every copy under the same license.
- **Verdicts** — *adopt* (take it as is), *adapt* (take it with changes),
  *learn-from* (copy only ideas), *skip* (nothing to take).

## The short answer

None of the six should be added to the template. Five have ideas worth
copying, a few lines each, into things the template already has. Phonon-2
isn't needed.

| Tool | What it is | Verdict |
|---|---|---|
| Reverse Engineer Anything | A large tool that lets agents study how an app works | learn-from |
| CLI-Anything | Generates a command-line tool for any program, for agents to use | learn-from |
| Claude Code Projects (redesigned) | Claude's cloud version of "one boss chat, many parallel helpers" | learn-from |
| Phonon-2 | A small offline speech-to-text model | skip |
| "Claude Changed Completely" video | 15 recent Claude Code changes; 10 are Claude-only | learn-from |
| OpenViking | ByteDance's memory database for agents | learn-from |

## The ideas worth taking (most valuable first)

**A. Running helpers in parallel.** Claude Projects runs many helpers but lets
only the main chat own the work. Helpers just report back. That suggests a
simpler answer to our open "several sessions on one job" question (R1). Three
small additions to the helper instruction sheet:
- name the files a helper must read first (R2);
- give helpers a "Remember:" slot for corrections that should outlive the task (R3);
- have helpers save their work in progress as they go (R4).

**B. Command-line tools for agents.** Write down what a good agent-facing
command does: machine-readable output, clear errors, a self-check (R7). Our
own `jev.sh` is the example. Also:
- fix one place where the docs call something a command-line tool when it
  isn't (R6);
- add a "no tool? wrap it" rule (R8);
- every such tool comes with its own skill file (R9).

**C. Careful research.** In our parallel-research skill:
- close every question as answered, partly answered or unresolved;
- say how hard you looked before reporting "not found" (R10).

An optional skill for studying someone else's app feature to rebuild it (R12)
is your call.

**D. Warnings and notes in the docs:**
- don't recommend CLI-Anything's installer `cli-hub`, which runs shell
  commands from a remote list and sends usage data by default (R13);
- a paragraph on using Claude Projects with the template, and its limits (R14);
- a pointer to local transcription for recordings without captions (R15);
- a line telling non-engineers that their computer's dictation works in any
  agent chat (R16).

**E. Skills that earn their place, and "done" that is proved** (from the video):
- a simple test before keeping a skill: run a few tasks with no skill, with
  a dummy file of the same length, and with the skill; keep it only if it
  wins (R17), optionally tried on 3–5 of our skills first (R18);
- "done" means a check command ran and its output is shown — written into
  plan acceptance lines and helper reports (R19);
- don't switch models mid-session; lower the effort instead (R20);
- check whether Claude's silent wait for a usage limit could trip the
  overnight chain's kill timer (R21).

**F. Layered memory** (from OpenViking):
- name the "one-line summary → overview → full detail" pattern in
  `docs/zoom-model.md` (R22);
- add the missing one-line `Purpose:` header to 4 docs (R23);
- a short warning entry for OpenViking: AGPL, needs a server and two AI
  models, sends content to the cloud by default (R24).

Also two additions to earlier ideas: R2 gains a reason (Claude's built-in
Explore and Plan helpers skip `CLAUDE.md`), and R14 gains "check the model
and effort Projects threads run on".

## What we're deliberately not doing

- Copying in REA's or CLI-Anything's own skills or code. They change too fast,
  are too heavy, or only work well in Claude.
- Building on Claude Projects. It's Claude-only, runs only in the cloud, and
  keeps its memory outside the repo.
- Adding a speech-to-text dependency.
- Building on Claude-only features from the video (advisor, forks, routines,
  `/goal`), or deleting skills on the strength of its "7 of 9 skill packs did
  no better than a dummy" claim — no source for it could be found.
- Integrating OpenViking. It doesn't work evenly across agents, keeps memory
  outside git, and its AGPL license would follow it into every copy.

## What I need from you

A yes, no or later on each of R1–R24. A yes becomes a backlog card or one
small work item (R2–R4, and R19, belong together). A no is recorded with its reason in
`decisions.md`.
