> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in `handoff.md`
> (the append-only ledger). Convention: docs/work-directory-conventions.md.

# Next Session — context-decay

## Mission

**Context-composition audit** (user-directed, 2026-08-07). The tool is
shipped: `scripts/context-inspect.sh` (see `docs/context-budget.md` →
"Quickstart — agent"). The user runs the experiment protocol themselves:
fresh session → `/context` → say "hi" → `/context` again → then this audit.
Your job in that session:

1. Run `scripts/context-inspect.sh` (no args — resolves this session's
   transcript). Compare its exact turn-1 total and component breakdown
   against the two `/context` outputs the user pastes (expect the first
   `/context` to under-report ~10K — the turn-1 attachment materialization,
   L29, itemized by the tool).
2. Produce the baseline-vs-pulled-in table: harness-fixed remainder,
   CLAUDE.md/memory stack, per-attachment costs (skill_listing ~4K,
   deferred_tools ~2.4K, hook context ~2K, mcp_instructions ~0.9K,
   agent_listing ~0.8K on 2026-08-07 numbers).
3. Where a component is trimmable, propose it with numbers; **for each
   accepted improvement create a work item** (`/create-work-item` for
   multi-session, or a backlog card in
   `docs/template-workspace-backlog.html` for one-shots) and work them by
   user priority. Known candidates already parked: superpowers plugin
   ~1.8K, claude.ai connectors ~410 (both user-global — need user action);
   skill_listing is the largest workspace-controlled block.

## Read these, in order

1. This file.
2. The TOP block of `handoff.md` — the tool's design + the
   transcript-vs-disk attribution learnings.

## Do NOT reload

- `context-decay-spec.md`, `design.html` — implemented; reference only.
- **Gemini auth on this machine** — settled dead ends
  (`docs/operational-knowledge.md`); do not retry.
- `ledger-analysis.md` — re-read only at the next analysis pass.

## Open items (unchanged, externally gated)

1. Gemini live-response verification — needs a user `GEMINI_API_KEY`.
2. Copilot CLI adapter live verification — needs Copilot CLI installed.
3. Next ledger analysis — after ~40 entries / first `method=estimate` rows /
   first non-claude rows.

## State snapshot

Branch `main`, clean, pushed through `4b51a5e` (context-inspect tool).
Live gitignored `.claude/settings.json` carries the SessionStart
registration hook.

## First actions

1. `git fetch origin` + confirm `git log HEAD..origin/main` is empty before
   trusting this launcher (staleness race — see backlog 2026-08-06 finding).
2. `scripts/context-budget.sh register` (skip if the SessionStart hook ran).
3. Follow the Mission — the user drives the `/context` captures.
