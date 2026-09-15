<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

**Open / next.** User reviews Part 2. On go: Stage 3 (fresh architect +
scenario/flow agents over the design, verdicts → Part 3). Part 2 §(m) lists 5
open questions for Stage 3. Supervisor pid 72900 hazard unchanged (decision 12).

# Session Handoff — 6 (2026-09-14): Stage 1 evaluation done and accepted; process re-sequenced to four stages

**Summary.** Started on the launcher's "write Part 2 (the plan)" and dispatched
three Plan agents; the user redirected mid-turn: update from origin (already
current — PRs #54–#60 were merged in session 5; origin had nothing new), then
**no implementation planning until the suggested changes are reviewed and
evaluated**. Stopped the Plan agents, ran three evaluation agents instead
(re-evaluation of F1–F10/S1–S10 against current main; independent architect
review of D-A..D-G; scenario + flow evaluation vs S1–S10, E/I catalog, three
loops). Synthesized as **Part 1b** in `session-management-review-findings.md`;
full reports in `evaluation/stage1-*.md`. User then set the process to four
stages (research/evaluate → design/architecture → evaluate the design vs
scenarios/flows + architect → plan implementation), added the binding
constraint **reliable/repeatable/reproducible without trusting the agent**
(§1b.7 + Tier-2 note in decisions.md), and **accepted all 17 recommendations
in §1b.5**. Committed Stage 1; rolled at WARN.

**Decisions (user, 2026-09-14).** Four-stage process (findings status header);
§1b.5 decisions 1–17 all accepted as recommended (three record writers with
field ownership; never reclaim numbers; orphan → abandoned + N+1; pid liveness;
run V2 before deciding `--clear`; delete both mode markers; keep `--takeover`;
chain budget its own block; Copilot = CLI; Gemini attended-only; fleet →
`scripts/fleet.sh`, delete `watch`, drop child-lock hierarchy; end the
pid-72900 chain before editing `session-loop.sh` + `main "$@"` wrapper first;
log text free-form, `reason=<code>`; D-F = escalation-time append; template
defaults manual / KILL_AFTER=0 / jq req; record gitignored with `user`;
authorise the `--bg` env probe). Tier-2 note written for the reliability
constraint (Promote?: maybe).

**Learnings:**
- The three evaluation agents cost 223K / 359K / 357K tokens and returned
  ≤600-word summaries + 165–282-line reports; the parent stayed under WARN only
  by reading the summaries and one section of one report. Same shape next time.
- Nothing in PRs #54–#60 invalidated a finding; #60 re-added an inference
  mechanism (F2 got worse). `docs/session-chain-scenarios.md` and
  `work/session-loop-hardening/` are cited but do not exist here.
- **Live hazard:** supervisor pid 72900 started before a213b3d changed
  `session-loop.sh` under it (bash reads by offset); it left an orphan
  `.next-command.json`. This rollover still goes through it (no edits to that
  file were made). End the chain deliberately before touching that file.
- `rollover-prep.sh` takes `<project>` before `--reason`; the launcher's
  "First actions" line had the order right, my first call did not.

**Open / next.** Stage 2 = write the design and architecture (Part 2). See
next-session.md. Counter: `seq-sync` noop expected (launcher started this
session as #6).

**Suggested skills.** Fresh `Agent` (general-purpose) to draft the design from
the architect's §7(d) seed + accepted decisions; then Stage 3 = architect +
scenario agents on the design; `decision` for anything new.

# Session Handoff — 5 (2026-09-14): L46 shipped; session-management review findings done, rolled at WARN before the plan

**Summary.** Item was closed; user reopened it with a new request. (1) Found
and fixed **L46**: session-loop round-2 runtime files (`.session-seq.bump.json`,
`.session-loop.budget`, `.session-loop.alarm-stop`) were never gitignored —
`8d2d542`, card archived, scorecard 0/88/4/0/6, main pushed by user earlier
(was 0 ahead; now 1 ahead). (2) User asked for a **holistic review of the
session-management / context-budget / multi-session subsystem** (context decay,
session-loop, launch-next-session, context tracking): findings → plan →
execution. Ran three parallel Explore agents (internals; operating model +
DevX; git history + incident evidence), spot-checked the load-bearing claims,
and wrote the findings to `session-management-review-findings.md` (this dir;
mirror of the plan-mode file `~/.claude/plans/now-what-i-want-cheerful-tide.md`).
User reviewed the findings and gave direction (§5 of that file). Rolled at WARN
(~125K) before the plan phase, at the user's choice. Session ran in **plan
mode** (read-only) throughout the review.

**Decisions (user, 2026-09-14).** Appetite = cleanup **and** structural
redesign (single launcher-owned per-session lifecycle record). Runtimes
first-class = Claude, Codex, GitHub Copilot, Gemini; opencode/others folded in
only if cheap, else follow-up. Fleet dispatch machinery = **keep**; user asks
how best to maintain it (plan must answer). No Tier-2 note yet — these are
scope choices for a plan not yet written; capture as Tier-2 when the plan
lands.

**Learnings:**
- The three review agents cost ~135–195K tokens each but returned dense
  ~2.5K-word reports; running them in parallel from a fresh-ish session was the
  right shape — the parent still hit WARN from reading the reports + spot
  checks + writing findings.
- `.pending-clear-seed` is not gitignored (found by the internals agent; not
  fixed — plan-mode session). `SESSION_LOOP_NOTIFY` in `context-budget.env`
  resolves `${ROOT:-.}` differently in its three sourcing sites. ADR-0009's
  "/clear rotates the transcript?" question is still unverified.
- `capture-rollover-options.sh` maps plan mode to `default` approval — fine.

**Open / next.** Successor writes **Part 2 (the plan)** per §6 of the findings
file, then presents it for approval; execution planning (tickets / new work
item, likely `session-management-redesign`) follows approval. Uncommitted:
nothing besides this rollover's own files. Supervisor live (pid 72900); this
rollover emitted `--loop-mode interactive` because the plan ends in a
user-approval question.

**Suggested skills.** Plan agents (`Agent` type `Plan`, ≤3, perspectives in
§6); `to-tickets` / `create-work-item` after approval; `decision` for the
scope choices once the plan is accepted.

