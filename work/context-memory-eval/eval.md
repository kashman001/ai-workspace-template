# Evaluation — this workspace vs. context/memory-engineering concepts

Session 1, 2026-10-07. Concept IDs come from `source-notes.md`. Verdicts:
**Strong** (the workspace does this on purpose), **Partial** (part of it is
done, or it happens by accident), **Gap** (missing and worth adding),
**Non-goal** (missing on purpose; this template doesn't need it).

## One-page summary

The workspace already follows the article's main idea: **context is RAM, disk
is memory** ("Disk is the source of truth", "Persist intermediate state to
disk" in `CONTEXT.md` → Agent Context Discipline). Two areas are stronger than
the article's design. First, it *measures* context usage from the API
envelope instead of estimating it (`scripts/context-budget.sh`). Second, it
splits memory into tiers that line up with the article's four-tier hierarchy
(see C5).

The weak spots are the three "keep memory healthy over time" ideas:
**structured updates (C6), forgetting (C7), and a background consolidation
loop (C9)**. Memory is written carefully but rarely pruned. Consolidation runs
inside the live session at checkpoint/rollover, so it uses up that session's
budget. Prompt-cache layout (C2) is never mentioned anywhere in the workspace.
The current layout is already mostly cache-friendly, but nothing protects it.

Vector search with MMR re-ranking (C8) and numeric decay scoring (C7's
formula) are reasonable **non-goals** for a plain-files, agent-agnostic
template.

## Scorecard

| ID | Concept | Verdict | Evidence on disk | Notes |
|---|---|---|---|---|
| C1 | Context/memory separation | **Strong** | `CONTEXT.md` → "Agent Context Discipline" rules 1, 4, 5; `docs/work-directory-conventions.md` (launcher/ledger split) | Stated as a rule and enforced by the rollover flow. |
| C2 | Cache-friendly prompt layout | **Partial (by accident)** | Nothing mentions prompt/prefix caching (grep of `docs/ skills/ scripts/ CONTEXT.md`: 0 hits). `scripts/context-budget.sh:270` adds `cache_read`/`cache_creation` tokens into the total but never reports a hit ratio. | The layout happens to be right: `CONTEXT.md` has no volatile content, the hooks inject no varying text, and volatile state lives in `next-session.md`, which is read as tail. No rule keeps it that way. Someone could add a date or status line to `CONTEXT.md` and invalidate the cache for every session. |
| C3 | Compress before injection (AST map) | **Partial** | graphify (AST graph + communities; `CONTEXT.md` → graphify), `.claude/agents/repo-navigator.md`, `docs/zoom-model.md` (Z2 is "generated on demand"), `skills/rlm/` | The idea is fully designed, but it's optional and not active here: there is no `graphify-out/` in this repo. It's a navigation tool. Nothing builds a signature-only "repo map" injection the way Aider does. |
| C4 | Budget allocation | **Strong** | `context-budget.env` (WARN 120K / STOP 150K), `docs/zoom-model.md` ("always-loaded ≤ ~10K; any zoom-in ≤ ~15K") | The best-developed part of the workspace. One measurement worth noting: the always-loaded files total ~29 KB ≈ 7K tokens (`CONTEXT.md` 20.5 KB, global `CLAUDE.md` 6.8 KB, `MEMORY.md` 2 KB), before any plugin/skill listings. That's within the 10K rule, but `CONTEXT.md` alone (~5K tokens) is at the top of Z0's stated 2–5K band. |
| C5 | Four-tier memory hierarchy | **Strong** | Working = session window. Episodic = `work/<item>/handoff.md` (+ archive), transcripts. Semantic = `CONTEXT.md` `## Language`, `work/*/decisions.md`, `docs/adr/`, `docs/repo-context/`, `docs/operational-knowledge.md`, the agent's auto-memory. Procedural = `skills/`, `scripts/`, versioned in git. | Matches the article tier for tier, including "procedural memory in a git repo". |
| C6 | Atomic notes + CRUD | **Partial** | UPDATE: launcher is *replaced* each rollover. DELETE-by-supersede: `docs/adr/README.md:43-44` ("never delete; supersede and link forward"). Atomic one-fact files: Claude Code auto-memory (harness-side, Claude-only). | No ADD/UPDATE/NOOP check before appending to `decisions.md` (2,171 lines across items) or `docs/operational-knowledge.md` (27 KB, 22 sections), so duplicates and contradictions can build up. The atomic-fact store in use (auto-memory) is Claude-specific, which conflicts with the "agent-agnostic" requirement for anything shared. |
| C7 | Controlled forgetting | **Partial** | Count-based: ledger keeps 2 blocks (`docs/work-directory-conventions.md:105`). Status-based: backlog archive, `docs/archive/`, "Retired" markers in `operational-knowledge.md`. | Forgetting happens by count or by hand, never by relevance or staleness. `operational-knowledge.md` is read "before debugging" and has no expiry or review signal. The decay formula itself is a non-goal. A "last-confirmed" date plus a review sweep would cover most of its benefit. |
| C8 | Hybrid retrieval + MMR | **Non-goal** | Retrieval = curated indexes (`docs/README.md`, `MEMORY.md`, `work/README.md`, repos registry) + grep + `graphify query` | Vector + MMR fits big unstructured stores. This workspace keeps small curated indexes ("summaries up, pointers down" — `docs/zoom-model.md`), which is the article's own C11 conclusion. Adding a vector DB would break the plain-files, any-runtime property. |
| C9 | Dual-loop (async consolidation) | **Gap** | Consolidation = `skills/checkpoint/` and `skills/session-rollover/`, both run *inside* the live session. `docs/archive/rollover-cost-analysis-2026-08-11.md` puts rollover at ~10–20K tokens. A `SessionEnd` hook already exists (`.claude/settings.json`), and `scripts/fleet.sh` / `session-loop.sh` can run headless children. | The live session pays for its own memory upkeep, at the moment when its context is fullest. The pieces for an outer loop already exist (SessionEnd hook, headless dispatch); nothing connects them. |
| C10 | Structured post-session extraction | **Partial** | `skills/checkpoint/SKILL.md:46-49` (update memory with durable, non-obvious learnings) | Prose, done by judgment, no schema. Fine for people. Not machine-checkable for duplicates or contradictions. |
| C11 | Curation beats volume | **Strong** | `MEMORY.md` index-only rule; `## Language` glossary; zoom-model "summaries up, pointers down"; "Demand-load, don't pre-load" | Core design stance of the workspace. |

**Tally:** Strong 4 (C1, C4, C5, C11) · Partial 5 (C2, C3, C6, C7, C10) ·
Gap 1 (C9) · Non-goal 1 (C8).

## Recommendations (ranked: value ÷ cost)

1. **Prefix-stability rule (C2) — doc only, cheap.** Add a short "Cache
   the prefix, vary the tail" note to `docs/context-budget.md`, with a pointer
   in `CONTEXT.md` → Tool & Context Loading. Content: no dates, status, or
   counters in always-loaded files; volatile state goes only in launchers;
   hooks print byte-stable text. Maybe add a check to
   `scripts/check-workspace-structure.sh` that flags date-looking lines in
   `CONTEXT.md`.
2. **Report cache-hit ratio (C2) — small script change.** `context-budget.sh`
   already reads `cache_read_input_tokens`. Recording `cache_read / total` in
   the ledger would turn "is our prefix stable?" into a number that can be
   measured. This fits the workspace's "measure, don't guess" stance.
3. **"Last-confirmed" + review sweep for semantic stores (C6, C7) — doc +
   checkpoint step.** Give each `operational-knowledge.md` entry a
   `Last confirmed: YYYY-MM-DD` line. Add a checkpoint step: before appending
   to `decisions.md` / `operational-knowledge.md`, classify the new item as
   ADD / UPDATE (edit the existing entry) / SUPERSEDE (mark the old one
   retired) / NOOP. Entries unconfirmed past N months go to a review list,
   not straight to deletion.
4. **Trim `CONTEXT.md` toward the Z0 band (C4) — doc edit.** ~5K tokens of
   always-loaded text sits at the top of the zoom-model's own 2–5K budget.
   Candidates to demand-load: the vendored-skills paragraph and the long
   Context Budget section, which already has its own doc.
5. **Async consolidation loop (C9) — exploratory, larger.** Prototype a
   `SessionEnd`-triggered headless child that reads the finished transcript
   and *proposes* (never commits) ledger, decision, and op-knowledge updates
   into a review file. This would move upkeep cost out of the live session.
   Risks: runtime coverage (it has to work for Codex/Gemini/Copilot, not just
   Claude), and unattended writes to shared files. Worth a spike, not a
   commitment.
6. **Non-goals to record (C8, C7-formula):** no vector store, no MMR, no
   numeric decay scoring. These are incompatible with plain files plus
   agent-agnostic access, and C11 curation covers the need.

## Method and limits

- Evidence comes from targeted greps and file sizes on disk (2026-10-07,
  HEAD `a753c1b`). Token figures are bytes/4 estimates of file weight, not
  measured session usage.
- Not checked: other runtimes' hook output (Codex/Gemini/Copilot) for prefix
  stability. Not checked: what plugins inject at session start (e.g. the
  superpowers SessionStart text). Plugins sit outside the template, but they
  affect cache stability for users who install them.
