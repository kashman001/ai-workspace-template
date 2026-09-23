# Template decision-seam inventory (input to the synthesis, 2026-09-23)

Produced by a read-only Explore agent in session 2; file:line pointers spot-checked by the orchestrator where marked ✓. Not a research-wave deliverable — it describes *this template*, not Jev. Verify a pointer before relying on it.

## Seams

**1. rlm leaf classification** — `skills/rlm/SKILL.md:144-171` (prompt: "Use exactly one of these categories … `N: <category>`", regex-parsed); `skills/rlm/scripts/rlm_repl.py:169-239` (`llm_query`), `:242-268` (`llm_query_map`), `:271-345` (`rlm_query`). Decider: a cheap leaf LLM via `claude -p --model $RLM_SUB_MODEL --allowedTools ""` (default `haiku`, `rlm_repl.py:82,193`); recursion `RLM_ROOT_MODEL=sonnet`. Input: 50–100 records per prompt. Output: root-declared closed category list; labels free text parsed after the fact; no `other`, no confidence, no threshold; only a coverage check (`classified == total`). Failures return a `[llm_query: …]` marker. Frequency: tens–hundreds of calls per run, 8 parallel. Swap hooks: env `RLM_SUB_MODEL`, `RLM_ROOT_MODEL`, `RLM_MAX_WORKERS`, `RLM_MAX_DEPTH`, `RLM_LEAF_USAGE_LOG`; `_claude_exe()` (`:112`) is the documented swap point. ✓ (see spot-check)

**2. triage category/state** — `skills/triage/SKILL.md:38-59`, `:84-100`; `docs/agents/issue-tracker.md:31-36`. Decider: the agent in-conversation, human confirms. Input: one issue/PR (1–20K tokens). Output: category {bug, enhancement}; state {needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix (+3 sub-reasons)}; bugs carry severity {critical, major, minor}. No `other`, no confidence. Frequency: a handful per triage session. Swap hooks: none.

**3. doc-review severity/confidence** — `skills/doc-review/SKILL.md:122-136`, `:140-160`. Decider: 6+ reviewer subagents, orchestrator synthesises. Input: whole doc (2–30K tokens) + audience model. Output: per finding, severity {Blocker, Major, Minor, Polish} and confidence {High, Medium, Low} (the template's only verbal confidence field); coverage cell {essential, useful, noise}; root cause ≈ {structural, content gap, surface}; finding text open-ended. Frequency: one-off per review. Swap hooks: none.

**4a. session-loop verdicts** — `scripts/session-loop.sh:14-28`, `:309-354`, `:256-264` (`session_made_progress`), `:355-363`. Decider: shell script; "never talks to a model" (`:10`); ADR-0011 makes mechanical gates binding. Output: closed verdicts {staged, quit_stop, quit_plain, cap} + broken codes {rc_nonzero, logout, staged_invalid, no_own_measurement, record_unreadable, schema_mismatch, stall}. Thresholds env (`SESSION_LOOP_STALL_LIMIT=3`, `MIN_LIFETIME=60`, `MAX_SESSIONS=10`). Only fuzzy judgement: "progress vs. bookkeeping" (`:256`), a file-path heuristic — advisory-only candidate, never a gate.

**4b. context-budget OK/WARN/STOP** — `scripts/context-budget.sh:70-71,513-519`; hook message `scripts/hooks/context-budget-hook-lib.sh:95`; agent-side "WARN asks, STOP goes" `skills/session-rollover/SKILL.md:21-39`. Deterministic threshold compare; poor LLM fit.

**4c. launch-next-session gates** — `scripts/launch-next-session.sh:26-31`, `:368-380`. Hash/heading/seq checks; closed refusal codes; deterministic.

**5a. ledger shape check** — `scripts/check-ledger.py:82,184,236,221-234`. Structural regex; {ok, warn, fail}. Shape only, not content consistency.

**5b. checkpoint/rollover reconciliation** — `skills/checkpoint/SKILL.md:38-60`, `:80-84`; `skills/session-rollover/SKILL.md:76-95`. Agent in-conversation. Mostly closed: learning routing {setup-time, operational, code-pointer, decision, park} (park ≈ none-of-the-above); backlog item status. No script checks the backlog HTML for consistency. Once per boundary.

**5c. decision-log tier / ADR promotion** — `skills/decision-log/SKILL.md:35-55`. Tier {1,2,3}; Tier 3 = boolean 3-leg AND test; `Promote?` {yes, maybe, no}. Agent in-conversation; a few per session.

**Additional:** research-wave fact-check per-claim verdict {CONFIRMED, OVERSTATED, WRONG, UNVERIFIABLE} + overall {CLEAN, CORRECTIONS_NEEDED, SERIOUS} (`skills/research-wave/references/fact-check-brief.md:69-88`; dozens of claims per item — strong fit, UNVERIFIABLE is already a none-of-the-above); code-review pass/fail per axis (`skills/code-review/SKILL.md:84-95`; value is in the prose); wayfinder ticket `Type:` {research, prototype, grilling, task} (`docs/agents/issue-tracker.md:141-150`); ask-matt skill routing (`skills/ask-matt/SKILL.md:20-95`).

## Agent's synthesis (hint, not fact)

- Good fit (closed-set): rlm leaf labelling (best: high volume, caller-declared set, single subprocess swap point); research-wave per-claim verdict; triage category/state/severity; doc-review severity/confidence; decision-log tier/Promote?; rollover learning routing; wayfinder Type; ask-matt routing.
- Bad fit: session-loop, context-budget, launcher, check-ledger gates — deterministic by design; ADR-0011 (`docs/adr/0011-mechanical-gates-and-reason-codes.md:17-30`) requires load-bearing gates to be scripts with reason codes, not model calls. Handoff/launcher writing, triage briefs, doc-review synthesis, code-review prose — open-ended text.
- Constraints on a new integration: CLI-first (`CONTEXT.md:246-248`, `docs/adr/0002-lean-by-default-tool-loading.md:20-21`, `docs/mcp-setup.md:61`); MCP only as an opt-in `mcp-fragments/<name>.json` holding no secrets (`mcp-fragments/README.md:10-20,55-60`); runtime-neutral skills (`docs/workspace-structure.md:346,394`) — rlm's only vendor tie is its `claude -p` leaf (`skills/rlm/SKILL.md:29-37`); credentials in the OS keychain via `security find-generic-password` (`docs/service-access.md:10-27`); knobs are env vars with precedence explicit env > `context-budget.env` > default (`context-budget.sh:60-71`).
