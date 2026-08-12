<!--
File: docs/for-non-engineers.md
Purpose: Entry point for non-engineers (PMs, stakeholders) — where to find
status, decisions, and how to contribute, plus the small glossary needed to
participate. Everything else in docs/ assumes an engineering reader.
-->

# For Non-Engineers — Status, Decisions, Contributing

You read markdown, you can paste a command someone gives you, and you work
through an AI agent — but you don't write code. This page is your entry
point; the rest of `docs/` is written for engineers and agents, and you can
ignore it. One prerequisite: someone with an engineering setup (or an agent
on an already-provisioned machine) gets you a working agent session first —
setup is the one part that isn't self-serve.

## Status — "what is the team working on?"

- **Portfolio view:** [`work/README.md`](../work/README.md) — one line and a
  status per active effort.
- **One effort in depth:** open `work/<project>/README.md` — each is a
  one-screen status report (what it is, where the output lives, current
  state). `next-session.md` in the same folder is the plan; `handoff.md` is
  the history, newest first.
- **Findings and fixes** (for template development): the rendered
  [backlog page](https://kashman001.github.io/ai-workspace-template/template-workspace-backlog.html)
  — scorecard, status badges, one card per finding.
- Don't read `git log` for status — it's engineering plumbing. The files
  above are the status surface.

## Decisions — "why did we choose X?"

- **Lasting decisions:** [`docs/adr/`](adr/) — each record gives the context,
  the decision, the alternatives that were rejected and why. Written to be
  read cold.
- **Day-to-day decisions:** `work/<project>/decisions.md` — short
  Chose/Because/Rejected notes per effort.
- Not sure where a decision lives? Ask your agent:
  > Why did we choose X? Check the ADRs in docs/adr/ and every
  > work/*/decisions.md, and quote the relevant record.

## Contributing — specs, new efforts, decisions

You can do all of this conversationally; the agent handles files and git.

- **Write what should be built:** the root `SPEC.md` template ("what it does,
  for whom, the problem it solves") is deliberately jargon-free — it's your
  deliverable. Ask the agent: *"Turn this discussion into a spec in
  `work/<project>/spec.md` using the SPEC.md structure."*
- **Start a tracked effort:** `/create-work-item <name>` — scaffolds the
  status/plan/history files for you.
- **Record a decision:** `/decision <what + why + rejected alternative>`.
- **File a finding or request:** ask the agent — *"add a card to the backlog
  for this"*. (The backlog file is maintained by agents; humans read the
  rendered page.)

If a mentioned workflow (like `to-spec` or `to-tickets`) isn't installed on
your machine, the fallback is always the same: describe the outcome to the
agent in plain language — it can do the work without the named skill.

## Glossary — the six terms you actually need

- **Work item** — one tracked effort, living in `work/<name>/`.
- **Launcher** (`next-session.md`) — the "what to do next" file for an
  effort; rewritten as work progresses.
- **Ledger / handoff** (`handoff.md`) — the effort's history, newest entry
  on top.
- **Rollover** — retiring an agent session before it degrades and handing
  its work to a fresh one via the launcher.
- **ADR / decision note** — a record of why a choice was made and what was
  rejected; ADRs (`docs/adr/`) are the durable ones.
- **Backlog card** — one finding or task on the backlog page, with evidence,
  impact, and fix.

Everything else you may see — MCP, hooks, worktrees, context tokens — is
agent infrastructure. You never need it to read status, follow decisions, or
contribute.
