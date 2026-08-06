<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->


# Session Handoff — 2026-08-06 (session 12: HTML review rendition shipped; STOP rollover at 155K mid-turn)

**What shipped (committed on `main`, pushed):**

- **`subagent-rollover-research.html` — `d93daea`:** standalone, self-contained
  HTML review rendition of the research note, restructured per user direction:
  problem (with the stats evidence) → the model (§2: roles/policy, verb,
  protocol, files, lock hierarchy, state machines, drain mode, invariants
  I1–I8 — with 5 hand-authored inline-SVG diagrams: system model, resume-vs-
  successor, lock hierarchy, child lifecycle, parent budget modes) → machinery
  already in place (§3) → findings (§4) → proposal R1–R8 + inventory (§5) →
  evaluation model (§6) → next steps. Light/dark via CSS tokens; no external
  deps. Diagrams visually verified in Chrome (3 label-overlap fixes applied
  pre-commit). The markdown note remains the raw record (footer says so).
- Tier-2 decision note (HTML-vs-Artifact) in `decisions.md`; claude-in-chrome
  `file://` gotcha routed to `docs/operational-knowledge.md`.

**Mid-turn user request (binding, NOT started):** enumerate rollover
*scenarios* — mainline functional plus corner/edge cases for resilience,
recoverability, and performance — to (a) keep in mind while working through
the doc and (b) drive evaluation, *before* any implementation. User asked
whether their dimension list misses anything (candidates to consider:
concurrency/contention incl. human attach during drain, observability/
auditability, cost/token-economy, schema evolution of records, degradation on
opaque runtimes, human-in-the-loop policy edges). Seed material: S1–S10 +
P1–P5 + §13 fault model already in the research doc — the new catalog should
extend, not duplicate, those.

**Rollover:** WARN fired mid-diagram-verification (134K), STOP (155K) two
edits later; wrapped the atomic step (commit `d93daea` + this ledger) and
rolled. Second consecutive session terminated on schedule by its own subject
matter.

# Session Handoff — 2026-08-06 (session 11b: subagent-rollover research phase; STOP rollover at 157K)

**What shipped (committed on `main`, pushed through `4fa0cdb`):**

- **`subagent-rollover-research.md`** (this work dir) — full research/design
  note on parent-managed child-session rollover: what transfers from
  main-session rollover, parent-as-manager policy mapping, successor-dispatch
  as the only rollover verb (resume worsens context), per-child files +
  dispatch records, lock hierarchy with transitive validity, drain-mode
  invariant (no parent rollover with live children), checkpoint/yield
  protocol (§8), 14-row rollover inventory (§9), delta requirements R1–R8
  (§10), vendor-agnostic layering (§11), depth/resilience model (§12),
  evaluation model — state machines, invariants I1–I8, scenarios S1–S10,
  fault properties P1–P5, cost model (§13).
- **`subagent-rollover-stats.md`** — measured: 30 subagent transcripts, 3
  crossed 120K WARN, max 141.8K (a *resumed* implementer), 0 ≥ 150K; claude
  child transcripts live at `<project-dir>/<parent-uuid>/subagents/agent-*.jsonl`
  with `.meta.json` siblings.
- **`subagent-vendor-survey.md`** — 4-runtime capability survey: only claude
  (and partially copilot) expose child identity; codex/gemini children are
  opaque; opencode forbids nesting; no runtime reports per-child usage.

**How it was produced:** three parallel background research agents (local
stats; Claude Code docs mechanics; live-CLI vendor survey) + controller
synthesis; user added mid-flight: vendor-agnostic requirement, the
communication protocol, the rollover inventory, and the evaluation model.

**Rollover:** STOP hook fired at 156,987 tokens right after the eval-model
section landed — the system being designed terminated its own design session
on schedule.
