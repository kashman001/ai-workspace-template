<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

# Session Handoff — 7 (2026-09-14): Stage 2 design drafted (Part 2); awaiting user review

**Summary.** Ran the two authorised probes (one agent, isolated temp dir with its
own hook config; report `evaluation/stage2-probes.md`): **V2 = ROTATES** —
`/clear` fires SessionEnd(reason=clear) then SessionStart(source=clear) with a
new session id and a new transcript JSONL, the old file frozen; **`claude --bg`
env = SURVIVES-ONLY-IF-THE-LAUNCH-SPAWNS-THE-DAEMON** — the var reaches the hook
on a cold start, but a second `--bg` 40 s later replayed the first launch's
stale value (daemon pre-forks spares from the spawning caller's env). So
`--clear` stays (ADR-0009 amended, open item closed) and the handshake file is
NOT retired (launcher line ~1184's rationale is mis-stated, the mechanism is
right). Then one general-purpose agent drafted **Part 2** (sections a–m per
the launcher) from the architect's §7(d) seed + the 17 accepted decisions +
§1b.7; appended to `session-management-review-findings.md` (lines 371–679;
source copy `evaluation/stage2-design-part2.md`). Status header updated. No
scripts, skills, docs or ADRs touched; nothing pushed.

**Decisions.** None new by the user this session. The design proposes (for
review, not decided): 7 kept concepts; record field owners launcher→`seq`/
`launch`/`staged`, context-budget.sh→`session`/`options`, session-loop.sh→
`chain`; `--clear` kept; handshake relocated into `launch.pending` + a
`pending_elsewhere` refusal; support matrix claude supported (attended +
supervised), codex/copilot-CLI unverified, gemini attended-unverified /
supervised-unsupported; ADR-0010/0011/0012 proposals.

**Learnings:**
- Probe cost 91K agent tokens / 8 min; design agent 232K / 11.5 min. Parent
  stayed under WARN by reading only headers + agent summaries.
- `/clear` transcript caveats for measurement: filter records by camelCase
  `sessionId` (snake_case `session_id` on some new-file records is stale);
  the `/clear` command record lands in the NEW file; no transcript is written
  when `CLAUDE_CODE_CHILD_SESSION` is inherited (probe needed `env -u`).
- `tmux` is not installed on this machine; `expect` drove the TUI fine.

**Review artifact (session 7, after commit eab995a).** Part 2 + the probe
appendix published as a private claude.ai page for the user's review:
https://claude.ai/artifact/4KeTb5seRPdSS8AtEKQmmV (title "Session Redesign
Part 2"; 13 sections a–m + appendix; source HTML in the session scratchpad,
not in the repo). Rolled over at WARN (137K) on the user's instruction; the
successor opens by presenting the URLs and answers review questions
(`--loop-mode interactive`).

**Open / next.** User reviews Part 2. On go: Stage 3 (fresh architect +
scenario/flow agents over the design, verdicts → Part 3). Part 2 §(m) lists 5
open questions for Stage 3. Supervisor pid 72900 hazard unchanged (decision 12).

