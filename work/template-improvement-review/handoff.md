<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

# Session Handoff — 4 (2026-09-10): L45 probed live, merged to main, item complete (checkpoint)

**Summary.** Live end-to-end probe of L45 via `Agent(isolation: worktree)`:
the `work/learn-agentic-workflows` symlink appeared in the worktree, the
probe write landed in the real directory, `.git/info/exclude` gained the
exact `work/learn-agentic-workflows` line, and the worktree was auto-cleaned
as "unchanged" while the write survived — the exact case the card named.
Result recorded as a bullet in `operational-knowledge.md` (`7a98718`), then
`fix/l45-gitignored-work-dirs` merged into main `--no-ff` (`5fd5480`).
23/23 suites green on merged main; structure + ledger checks clean. Backlog
row and archived card updated with the merge; `work/README.md` status row
flipped to Complete. Local fix branch deleted (merged).

**Decisions.** None new; promotion scan clean (no `Promote?: yes|maybe`).

**Learnings:**
- The worktree's branch is cut from `origin/main`, which predates the fix,
  so it had no `scripts/link-local-work.sh` — yet the link appeared. Hooks
  run the *main checkout's* lib (`CLAUDE_PROJECT_DIR` in the hook wiring;
  the lib's root resolver walks to the git common dir). The fix therefore
  holds in worktrees cut from any base.
- The harness's worktree guard refuses compound `git -C "$PWD" …; pwd`
  commands inside an isolated subagent; single commands pass.

**Open / next.** Item **complete**. Only outstanding: pushing main (13
ahead of `origin/main`) — the user's call, not done. `review.md` §E lists
user-only items. `.claude/worktrees/learn-agentic-workflows-s2` still holds
a stale real copy of that item (by design; delete it to get the link).
`review/template-improvement-review-s1` is merged but not deleted.

**Suggested skills.** None — no successor session planned. If reopened:
`checkpoint` after the push.

