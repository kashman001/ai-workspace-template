<!--
File: docs/agent-onboarding-check.md
Purpose: Verify that each AI agent runtime discovers and reads CONTEXT.md
         through its entrypoint symlink, and can operate the workspace.
-->

# Agent Onboarding Check — verify a runtime can use this workspace

Use this to confirm a given AI agent runtime (Claude Code, Codex, OpenCode,
Gemini, or any runtime you add) **discovers and reads the workspace context**
and can **use its tools**. It has two layers:

1. **Static plumbing** — automated, runtime-independent. Run
   `scripts/tests/test-agent-entrypoints.sh`. It proves the entrypoint files
   resolve to `CONTEXT.md` and that the onboarding canary is present. If this
   fails, fix it before testing any agent — no runtime can succeed until it
   passes.

2. **Live runtime check** — you run this *inside* each agent. Open the
   workspace in the runtime and paste the prompts below. Correct answers prove
   the agent loaded the context through its own entrypoint.

## How each runtime discovers the workspace

| Runtime | Entrypoint it is *expected* to read | Resolves to |
|---------|------------------------------------|-------------|
| Claude Code | `CLAUDE.md` | `CONTEXT.md` |
| Codex / OpenCode | `AGENTS.md` | `CONTEXT.md` |
| Gemini CLI | `GEMINI.md` | `CONTEXT.md` |

All are symlinks to the single master `CONTEXT.md`, created by
`scripts/setup.sh` and validated by `scripts/check-workspace-structure.sh` —
so *whichever* file a runtime reaches for, it gets the same content. Adding a
runtime (e.g. GitHub Copilot via `.github/copilot-instructions.md`) means
adding a symlink and registering it in `scripts/setup.sh`,
`scripts/check-workspace-structure.sh`, and
`scripts/tests/test-agent-entrypoints.sh` — never forking the content.

> **Don't assume which entrypoint a runtime uses — make it tell you.** The
> canary reply includes the entrypoint for exactly this reason. Runtimes have
> been observed picking *different* entrypoints on different runs (e.g. a
> Claude-based runtime hosted in another product reading `CLAUDE.md` on one
> run and the host's own instructions file on another). Treat entrypoint
> selection as **non-deterministic** — which is fine, and in fact the point:
> every entrypoint is a symlink to the same master, so the content is
> identical whichever file gets read. That resilience is what the "one
> master, symlink the rest" design buys, and it is why you must never fork
> content into a per-runtime file.

## Live check — paste these into the agent

### 1. Canary (proves the entrypoint was loaded)

> **Prompt:** Report the workspace canary.

**Expected:** one line beginning `WORKSPACE-CONTEXT-OK`, naming the runtime
and entrypoint, e.g. `WORKSPACE-CONTEXT-OK — Codex via AGENTS.md`. Any other
answer (or "I don't see a canary") means the runtime did **not** load
`CONTEXT.md` — check that its entrypoint file exists and resolves (run the
static test).

*Customizing the token:* you may replace `WORKSPACE-CONTEXT-OK` with a
project-specific token (e.g. `MYPROJECT-CONTEXT-OK`). Update it in **both**
`CONTEXT.md` and the `CANARY_TOKEN` variable in
`scripts/tests/test-agent-entrypoints.sh` — the test asserts they agree.

### 2. Comprehension (proves it read the real content, not just the canary line)

Write 3–4 short questions answerable **only** from your `CONTEXT.md` (not
guessable from generic convention), and record the expected answers here.
Good candidates: a project-specific command, a naming convention, a
"which repo/file owns X" fact. Example shape:

> **Prompt:** From the workspace context only, answer briefly:
> (a) <question about a workspace command>
> (b) <question about a convention>
> (c) <question about where something lives>

A wrong answer with a correct canary usually means `CONTEXT.md` itself is
stale or ambiguous — treat it as a documentation bug, not a runtime failure.
In practice this check has caught real doc errors that every agent would
have inherited.

### 3. Tooling (proves it can act, not just read)

> **Prompt:** Run the workspace dependency check and tell me if core tooling
> is present.

**Expected:** the agent runs `scripts/check-dependencies.sh` and reports the
result. This confirms the runtime can execute the workspace's agent-neutral
scripts. (If the runtime is read-only / cannot run shell commands, note that —
it can still use the workspace for reasoning, just not execution.)

## What "pass" means per runtime

- **Canary correct** → the runtime discovered and read `CONTEXT.md` via its
  entrypoint. ✔ discovery works.
- **Comprehension correct** → it is using the actual conventions, not guessing.
- **Tooling runs** → it can operate the workspace, not just read it.

Record results as you test each runtime. **Log the entrypoint the agent
actually reported**, not the one you expected — and not the name the agent
gives itself (Claude-based runtimes tend to self-identify as "Claude Code"
even when hosted elsewhere; that is a model quirk, not a setup problem).

| Runtime | Entrypoint reported | Canary | Comprehension | Tooling | Date | Notes |
|---------|--------------------|:------:|:-------------:|:-------:|------|-------|
| | | | | | | |

Two practical rules:

1. **Judge a run by its reported entrypoint line**, not by which file you
   expected the runtime to read.
2. **Keep every entrypoint present and identical.** Do not "optimize" by
   deleting one because a runtime seemed not to use it — it may use it
   tomorrow.

## If a runtime fails

- **Canary fails** — the entrypoint file is missing or not resolving. Re-run
  `scripts/setup.sh` (recreates the symlinks) and
  `scripts/check-workspace-structure.sh`. On Windows, confirm the clone
  preserved symlinks (git `core.symlinks=true`); if not, the runtime may need
  the entrypoint as a real file — but prefer fixing symlink support so content
  stays un-forked.
- **Comprehension fails but canary passes** — either `CONTEXT.md` is stale
  (fix the doc) or the runtime truncates long context. Point it explicitly at
  the relevant section, or reduce what it must hold at once (see "Agent
  Context Discipline" in `CONTEXT.md`).
- **Tooling fails** — the runtime cannot run shell commands, or a tool is
  missing; run `scripts/check-dependencies.sh` yourself to see which.
