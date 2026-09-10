# Review — pooled open threads + fresh-eyes findings (2026-09-10, session 1)

Sources: survey of every `work/*` item (README, launcher, top ledger block,
decisions), the 5 open backlog cards + `work/template-maintenance/
open-cards-options-brief.md`, a baseline run of all 21 suites + checks
(all green), and a fresh-eyes review of the adopter-facing docs.

Disposition legend: **FIX** = do now in this item · **BUILD** = design-gap
card built under a stated assumption (see `decisions.md`) · **ROUTE** =
belongs to another work item, pointer added there · **USER** = only the
user can do it · **PARK** = deferred by design, revisit on its trigger.

## A. Housekeeping defects found by the survey (FIX)

| # | Finding | Source | Status |
|---|---|---|---|
| A1 | `work/README.md` lacks a row for `kimi-k3-agent-integration` (git-tracked); never says local-only items (e.g. `learn-agentic-workflows`, gitignored) are excluded by rule | `work/README.md` | done |
| A2 | `work/README.md` status text stale: sdlc-ai-mapping is CLOSED (not "pending sign-off"); template-maintenance has a queued mission (walk the options brief) | `work/README.md:25-26` | done |
| A3 | `work/context-decay/next-session.md` points at `work/context-decay/context-ledger.jsonl`, which moved to `.context-budget/context-ledger.jsonl` (M19). Its gate (≥45 `rollover complete`) has passed (68 now) unnoticed | `next-session.md:15,66` | done |
| A4 | `work/usage-scenarios/README.md` lists M16/L32/L33 as open (all resolved); launcher says "nine suites" (now 21) | `README.md:41-49`, `next-session.md:33` | done |
| A5 | `work/devex-review/next-session.md` says backlog has 1 open card (M16) — stale | `next-session.md:12-13` | done |
| A6 | `work/automatic-session-rollover/.session-seq`=31 but ledger top block is session 32 (ADR-0007: seq is canonical → sync it to 32) | machine-local file | done |
| A7 | `work/template-maintenance/next-session.md` session-16 snapshot uncommitted | git status | done |
| A8 | Cross-item coupling unrecorded: L38 routed into quality-gates; M29 postmortem → feedback-intake forward pointer. Neither target README mentions it | options brief §L38/§M29 | done |
| A9 | Stale banners: `template-maintenance/exit-ux-plan.md` ("ready to implement" — M35 shipped), `context-decay/trim-estimates.md` ("no trims yet" — declined 2026-08-07) | those files, line 1-5 | done |
| A10 | Gitignored work dirs don't survive worktree-forced background sessions (manual `cp` back) — real friction, never carded | `work/learn-agentic-workflows/NOTES.md:26-28` | todo: file backlog card (next session) |

## B. The 5 open design-gap cards (BUILD, per options brief)

| Card | Direction taken | Status |
|---|---|---|
| L38 dep upgrades / suite health | ROUTE into `work/quality-gates/` scope; resolve card as routed | built — backlog card move pending |
| L39 generic backlog convention | Declare "bring your own tracker" in `docs/agents/issue-tracker.md`, pointing at the template's own backlog files as a copyable worked example | built — backlog card move pending |
| M29 postmortem convention | Committed `docs/postmortems/` (README + template), blameless; agent drafts, human reviews; forward pointer to feedback-intake | built — backlog card move pending |
| M28 UAT/beta convention | Extend `docs/work-directory-conventions.md` with a `uat.md` slot (who tests, criteria from spec, results, no-go = Tier-2 decision note); convention only, no skill | built — backlog card move pending |
| M27 testability / failure-mode prompt | Native companion skill `design-for-testability` (advisory interrogation), pointer beside `grill-with-docs`; suggested "Testability" heading in specs | built — backlog card move pending |

## C. Fresh-eyes findings (FIX unless noted)

Baseline from the review: hook configs, command→skill links, skill
frontmatter, gitignore, placeholders all verified clean. Defects are
doc/reality drift. C1 is done in A1. Items marked "todo" are for the next
session (one subagent can do C2–C12 in a single pass; they are all small
doc edits).

| # | Finding | Source | Fix | Status |
|---|---|---|---|---|
| C1 | `work/README.md` missing kimi-k3 row | work/README.md | (= A1) | done |
| C2 | `docs/template-usage.md` §5 prune guide (l.179-182) claims only ADR lines + backlog rows point into `work/`; actually `docs/context-budget.md:157,639,750,758`, `docs/operational-knowledge.md:25`, `README.md:28` link into `work/automatic-session-rollover/…` and `work/usage-scenarios/scenarios.md`; `work/README.md` keeps rows for deleted dirs. Also `scripts/hooks/context-budget-{stop,gemini,opencode}-hook.sh` and `docs/adr/0008:125` cite `work/session-loop-automation/probe-results.md`, which does not exist at all | template-usage.md §5 | (a) §5: "reset `work/README.md` to header + empty table"; (b) list the docs pointers as expected-dangling or move the cited analyses into `docs/archive/`; (c) fix the `session-loop-automation` citations (find where probe results actually live via `git log -S probe-results`) | todo |
| C3 | `docs/workspace-structure.md:313-325` skills inventory stale: lists 7 skills, calls `wayfinder` vendored, omits `doc-review`, `research-wave`, no pointer to `skills/vendored-skills.md` | workspace-structure.md | replace tree with the native list from CONTEXT.md + one vendored-set line; rebuild HTML | todo |
| C4 | `skills/vendored-skills.md:76-78` workspace-authored list omits `research-wave` | vendored-skills.md | add it | todo |
| C5 | `docs/README.md` skips `docs/workspace-setup.md`, `docs/agents/issue-tracker.md`, `docs/superpowers/{plans,specs}/` | docs/README.md | add rows for the first two; for `docs/superpowers/` add a "Developing the template" row or move to `docs/archive/` + prune list | todo |
| C6 | Stop hook (`scripts/hooks/context-budget-stop-hook.sh`, wired in `.claude/settings.json` + `.codex/config.toml`) undocumented; `docs/context-budget.md:690-695` vendor table omits it; `sync-vendored-skills.sh` absent from workspace-structure scripts list | context-budget.md, workspace-structure.md | add to both table rows + "The supervisor" section; add the script line | todo |
| C7 | `writing-for-agents` provenance: CONTEXT.md:142-144 lists it as native; SKILL.md carries upstream provenance and vendored-skills.md:62 says adapted | CONTEXT.md:146-153 | add it to the "(and the adapted …)" parenthetical | todo |
| C8 | `docs/workspace-structure.md:207-209` documents a `<Project>.code-workspace` that does not exist | workspace-structure.md | mark optional or drop | todo |
| C9 | `docs/workspace-structure.md:639` example cites nonexistent `scripts/file-bug.sh` | workspace-structure.md | generic placeholder | todo |
| C10 | `.claude/settings.json.example` enables `youtube-transcript` though `.mcp.json.example` carries only graphify (youtube is a fragment) | settings.json.example | drop `youtube-transcript` from `enabledMcpjsonServers` | todo |
| C11 | `docs/template-usage.md:97` placeholder-hunt grep matches HTML tags in `docs/*.html` | template-usage.md | add `--exclude='*.html'` | todo |
| C12 | `docs/recommended-tooling.md:282` says setup-matt-pocock-skills scaffolds `triage-labels.md` + `domain.md`; it writes `triage-labels.md` only when `triage` is installed | recommended-tooling.md | qualify the sentence | todo |

## D. Ready-to-act threads owned by other items (ROUTE)

- Context-decay savings validation: DONE — `work/context-decay/savings-validation-2026-09-10.md`;
  verdict negative (no saving materialized). Its launcher now says so.
- feedback-intake and quality-gates: session 1 never happened. Out of scope
  here beyond the pointers in A8; both stay "scaffolded".

## E. User-only items (USER) — surface in the final report

- Kimi K3 runtime decision (4 options, recommendation on file) — stalled since 2026-08-10.
- Other machine: `git reset --hard origin/main` + git email fix (context-decay).
- Delete the pre-filter backup bundle when satisfied (context-decay).
- Prune 5 locked `.claude/worktrees/*` (all merged) — user call per template-maintenance.
- Push local main (3 commits ahead of origin at session start).
- Resume the learn-agentic-workflows course (lesson 0003).
- Gemini API key / Copilot CLI install for the two live-verification items.

## F. Parked by design (PARK) — no action

Per-item WARN/STOP thresholds; Copilot measured-tier adapter; SendMessage
checkpoint push; `sessions` subcommand; opencode `serve` tier; user-global
context cleanup; usage-scenarios Gap 1/Gap 4 (triggers: second person /
second shared service); three "Promote?: maybe" notes in sdlc-ai-mapping and
usage-scenarios decisions (left for the user — ADR promotion is a judgment
about lasting weight).
