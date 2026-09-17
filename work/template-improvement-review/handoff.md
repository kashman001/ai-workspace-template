<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 10 (2026-09-16): Stage 4 tickets cut; phase 0 tasks 2–5 done; chain ended by a plain quit

**Summary.** Cut ten tickets from Part 4 (`issues/01`–`10`, one per phase +
cutover, edges per "Order and gates"; commit 0c1dd35, no user quiz — the
launcher fixed the granularity). Phase 0 (`plans/phase-0.md`): root
`ROLLOVER_RELAUNCH` flipped to `manual` with a committed per-item `auto`
override for this item; `jq` pinned by `test-check-dependencies.sh` D5;
`SESSION_LOOP_NOTIFY` now resolves from the env file's own location
(`test-session-loop-notify.sh` N4; doc paragraph corrected);
`scripts/import-session-seq.sh` + `test-import-session-seq.sh` (26 asserts)
on a throwaway item. All suites green before commit. **Chain ended:** this
session staged no successor; closing it by hand with nothing staged makes the
old supervisor (pid 72900) log a deliberate quit and exit 0. Nothing pushed.

**Decisions.** Record file `session-state.json` with `schema: 1`; import
compares rather than consumes the counter; notify path via `BASH_SOURCE`
(decisions.md 2026-09-16).

**Learnings:**
- macOS has no `timeout`; a suite loop wrapped in it reports rc=127 for every
  suite and looks like a run. Check the per-suite rc line before trusting it.
- macOS 15+ ships `/usr/bin/jq`, so a "jq absent" test needs a PATH built
  without it, not just a bare PATH.
- Tickets + phase 0 + bookkeeping fit one session (WARN at ~125K) only
  because the big scripts were grepped, never read.

**Open / next.** User direction after the session summary (2026-09-17): plan
the remaining phases as a dependency graph and execute them in parallel with
a fleet of agents. Then: one wave per session, rolling over through the LIVE
supervisor (chain kept; `main` frozen, waves on `stage4`). Session 11: mark phase 0 `done`, write `plans/fleet-plan.md` (waves
1∥2 → 3 → 4∥6 → 5 → 7 → 8 → cutover), get the go, launch wave A.

# Session Handoff — 9 (2026-09-15/16): Stage 4 planned (Part 4) and ACCEPTED; tracker in place; rollover at WARN

**Summary.** Republished design v2 page (version 2) with D1–D3 shown as
settled. User gave the go for Stage 4. One Plan agent drafted **Part 4**
(findings file line 765, ~80 lines): 9 phases + cutover, each a vertical slice
with its proving test, touches/deletes, session estimate 18 likely / 15–19
range (10–12 if phase tasks are delegated to subagents). Session review
applied three corrections (`/clear` rotation already probed in Stage 2 →
ADR close-out in phase 8; clear-seed hook + `.pending-clear-seed` deleted in
phase 4; ADR promotion added to phase 8). Created **`stage4-tracker.md`**
("Now" line + per-phase row: status/est/used/commit) and README pointers.
Decision note on plan shape appended. Committed 07a47bb. **User accepted
Part 4** ("Part 4 is approved") and asked to roll over now. Nothing pushed.

**Decisions.** User: Stage 4 go; Part 4 accepted. Session: phase-level plan
+ just-in-time `plans/phase-<n>.md` + tracker (decisions.md 2026-09-15).

**Learnings:**
- Republishing an owned artifact: `Artifact read` returns the raw HTML; the
  previous session's scratchpad copy was byte-equivalent, so patch + republish
  cost ~10K. Don't rebuild pages from markdown when a local copy exists.
- A ~1K-word Part 4 append plus its scaffolding pushed the parent from 93K to
  129K; a plan-writing session should not also publish a page.
- The Plan agent's draft was factually right about the scripts but re-opened a
  question already closed by probe evidence — verify "open item" claims against
  the ledger before accepting a plan.

**Open / next.** `/to-tickets` on Part 4; then phase 0. Supervisor pid 72900
still live on the old loop script: session 10 is the interactive pause where
the chain is ended deliberately (quit with nothing staged) as phase 0's first
step; session 11 onward is started by hand until cutover.

# Session Handoff — 8 (2026-09-15): Stage 3 done (Part 3) + readable design v2; awaiting 3 user decisions and go for Stage 4

**Summary.** Opened by presenting the Part 2 review page. The user's review
findings were about the document, not the design: too long; too much internal
jargon; must be readable independent of the workspace; introduce concepts with
diagrams or simple explanations. On the user's "go", Stage 3 ran as three
parallel reviewers (planned two + a developer/implementer lens, added because
the user asked whether a developer had reviewed it): architect, scenario/flow,
developer — reports `evaluation/stage3-{architect-review,scenario-evaluation,
developer-review}.md` (108/148/107 lines; 121K/132K/130K agent tokens). All
three: sound with amendments. A fork synthesized **Part 3** (findings file
line 688, 76 lines) and rewrote the design as **`evaluation/stage3-design-v2.md`**
(158 lines, 4 mermaid diagrams, 12-term glossary, no ID codes in the body,
three DECISION items in place). Part 2 left untouched (deviation from the
launcher's "edit in place", recorded in the commit trailer). Committed 2dc0d6e.
Design v2 published as a private page: https://claude.ai/artifact/2VMbASSbqw1JN4JTeC9jrb. Nothing pushed.

**Decisions.** User: Stage 3 go with three reviewers + simplicity mandate
(decisions.md 2026-09-15). Consensus adopted into v2 (not yet user-accepted):
`--bg` launch path deleted; verdict rewritten on `launch.predecessor`; prep/
verify verbs replaced by inline launcher checks + `--check`; `opts-sync`
deleted; pid liveness sole oracle; WARN asks iff relaunch manual/off; unread
record fields and ~a third of reason codes cut. Open for the user (v2 §
"Decisions needed"): D1 logout code path on codex/copilot (rec: drop), D2
resumed predecessor after staging (rec: occupation rule, no number spent),
D3 copilot/gemini identity heuristic (rec: accept).

**Learnings:**
- The user reads deliverables only if short, plain, self-contained, and
  diagram-led; saved as memory `review-docs-plain-language`. Every future
  user-facing doc here: one-page summary first, glossary, pointers as footnotes.
- All three reviewers independently found the same (b)/(d) contradiction
  (bump nulls `session`, verdict reads it) — a single design agent misses
  cross-section consistency; parallel lenses catch it.
- Fork-synthesis kept the parent under WARN: parent read only the three
  summaries + design v2; the fork read the 363 report lines.

**Open / next.** User decides D1–D3 and gives the go for Stage 4
(implementation plan, Part 4). Precondition for any code: decision 12 (end
supervisor pid 72900 at its next interactive pause) — still live on old code.

