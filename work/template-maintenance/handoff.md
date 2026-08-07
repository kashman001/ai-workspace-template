<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-06 (context audit: L25–L29 shipped; STOP rollover)

**Trigger:** context-budget STOP (151K, then 157K mid-rollover) right after the
L29 commit. All work committed and pushed; clean tree.

**What shipped (three commits on `main`):**
- `f9bceae` — L25–L27 demand-load trims: context-budget.md section index +
  grep-the-header access note; decision-log skill heredoc-append + 16KB
  archive rule; CONTEXT.md condensed 14.0→12.6KB (graphify removal steps
  moved into recommended-tooling.md §5, ending its circular pointer).
- `4b94d76` — L28: `register` tolerates a missing/empty transcript at
  SessionStart (`method=deferred status=OK`, exit 0) instead of "error:
  measurement failed"; register instruction scoped so Claude Code agents
  don't re-run what the hook already did. Verified live.
- `a3da781` — L29: /context under-reports ~10K until the first real message
  (harness listing attachments materialize with turn one); gotcha documented
  in `docs/operational-knowledge.md`. Tracker was correct throughout.
- Backlog: L25–L29 resolved cards in the archive file, scorecard 43 Resolved.
- Tier-2 decision note (index-over-split, condense-over-delete) in
  `decisions.md`.

**Learnings (parked):**
- Empty-session floor measured ~44.7K (2026-08-06): harness-fixed ~22.5K;
  superpowers plugin ~1.8K; MCP-attributable ~2.2K (github ~900,
  chrome ~500 + ~800 hidden in system prompt/skill, claude.ai connectors
  ~410, rest small); skills roster ~4.9K. Per-server/per-skill tables live
  only in the 2026-08-06 session transcript — re-derive from a fresh
  session's jsonl if needed (method: jq over attachment types).
- Warp terminal plugin injects a `hook_success` envelope per PostToolUse —
  model-visible cost unmeasured; worth checking if it bites again.

---

# Session Handoff — 2026-08-05 (closed out: launch-next-session effort spun out to its own project)

The open question in the block below (background demo vs interactive) was
resumed and resolved: demo run, discussion held, and the whole effort spun
out into **`work/automatic-session-rollover/`** at the user's request — it
grew from one script into script + optionality knobs + cross-vendor trigger
reliability + multi-session identity redesign. See that project's
`relaunch-analysis.md` and ADR-0003 for everything; nothing about this
effort remains pending in template-maintenance. The launcher here is
retargeted to umbrella/backlog duty.

---
