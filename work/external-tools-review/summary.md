# Four outside tools: what the template should take from them

One-page summary. The full reasoning is in `synthesis.md` and the four notes
in `research/`. HTML version: `summary.html`.

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
- **Verdicts** — *adopt* (take it as is), *adapt* (take it with changes),
  *learn-from* (copy only ideas), *skip* (nothing to take).

## The short answer

None of the four tools should be added to the template. Three of them have
ideas worth copying, a few lines each, into things the template already has.
The fourth isn't needed.

| Tool | What it is | Verdict |
|---|---|---|
| Reverse Engineer Anything | A large tool that lets agents study how an app works | learn-from |
| CLI-Anything | Generates a command-line tool for any program, for agents to use | learn-from |
| Claude Code Projects (redesigned) | Claude's cloud version of "one boss chat, many parallel helpers" | learn-from |
| Phonon-2 | A small offline speech-to-text model | skip |

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

## What we're deliberately not doing

- Copying in REA's or CLI-Anything's own skills or code. They change too fast,
  are too heavy, or only work well in Claude.
- Building on Claude Projects. It's Claude-only, runs only in the cloud, and
  keeps its memory outside the repo.
- Adding a speech-to-text dependency.

## What I need from you

A yes, no or later on each of R1–R16. A yes becomes a backlog card or one
small work item (R2–R4 belong together). A no is recorded with its reason in
`decisions.md`.
