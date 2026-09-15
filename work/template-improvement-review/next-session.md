# Next Session — template-improvement-review (session-management review: PLAN phase)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

Write **Part 2 — the plan** for improving the session-management /
context-budget / multi-session subsystem, on top of the finished findings
(session 5) and the user's scope decisions, then present it for approval.
The findings phase is CLOSED — do not re-review, do not re-run the review
agents, do not re-ask the four direction questions.

No-human-in-the-loop clause: everything up to and including writing the plan
is unattended work. The one thing that needs a person is approving the plan;
stop there with the plan presented (the chain is `interactive`, so the
supervisor pauses for the human).

## Read these, in order

1. `work/template-improvement-review/session-management-review-findings.md`
   — the whole findings state, user decisions (§5), successor brief (§6).
   Read it fully; it is ~250 lines.
2. `work/template-improvement-review/handoff.md` — top block only.

## Do NOT reload

- `review.md`, `decisions.md`, the backlog HTML files whole (settled; the
  template-improvement item's original scope is complete).
- `docs/context-budget.md`, the big scripts, the test suites — the Plan agents
  read those; the parent reads only what a specific plan step needs.
- `~/.claude/plans/now-what-i-want-cheerful-tide.md` — identical to item 1
  above (it is the plan-mode file; if the session is in plan mode, that path
  is the one you are allowed to write Part 2 into, then mirror it back here).

## State snapshot

- `main` = L46 fix + session-5 rollover commit + merge of origin PRs #54–#60;
  clean; ahead of `origin/main` by local commits only (do not push).
- Supervisor live for this item (`.session-loop`, pid 72900, chain budget
  used 1 of 10). This rollover emitted `--loop-mode interactive`.
- Known unfixed small defects (fix inside the plan's first phase, not now):
  `.pending-clear-seed` not gitignored; `SESSION_LOOP_NOTIFY` ROOT resolution;
  ADR-0009 `/clear` transcript-rotation unverified.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
2. Read item 1 above (findings file) end to end, then item 2.
3. Launch ≤3 `Plan` agents in parallel, each given the findings file path and
   the decisions in §5, from these perspectives: (a) the single per-session
   lifecycle record — design, and a migration path from the 7 current state
   files + the roles/lineage/logout inference cluster, with test-posture
   (behaviour over golden strings); (b) maintainability: how to structure,
   isolate, test and *verify* the kept fleet-dispatch machinery and the four
   first-class runtime adapters (Claude, Codex, Copilot, Gemini), including
   what "exercise a real rollover on each" costs; (c) docs/DevX consolidation
   and downloader hygiene (one rule/one place, daily-loop vs fleet reference
   split, assertion-only instruction files, guide section, neutral defaults).
4. Synthesize into ONE phased plan: tracer-bullet order, each phase
   independently shippable and green on the suites, verification per phase,
   explicit answer to "best way to maintain the fleet machinery", explicit
   call on which non-first-class runtimes fold in vs follow up. Write it as
   Part 2 into the findings file (and the plan-mode file if in plan mode).
5. **Architect review (user requirement, 2026-09-14).** Hand the synthesized
   plan to an independent architect agent (fresh `Agent`, general-purpose,
   with the findings file + plan + read access to the scripts) to review the
   suggested changes for soundness, hidden coupling, migration risk and
   simplicity; fold its verdicts into the plan and list what it rejected.
6. **Scenario evaluation (user requirement, 2026-09-14).** Evaluate the plan
   against usage scenarios and flows: the S1–S10 table in the findings file
   (§3), plus the workspace's scenario catalog `work/usage-scenarios/`
   (E1–E18 external, I1–I10 internal; `gaps-and-coverage.md`) and the three
   control-flow loops (measure / rollover / supervise). For each scenario:
   does the proposed design handle it, what changes for the user, what
   verification proves it. Put the matrix in Part 2.
7. Present the plan for approval (ExitPlanMode if in plan mode; otherwise a
   tight summary + pointer to the file). Stop there. After approval: propose
   `create-work-item session-management-redesign` + `to-tickets`.
8. `scripts/context-budget.sh record --label "plan written"` before presenting.

**Code moved under you.** Origin PRs #54–#60 (merged into main by session 5's
rollover) changed the subsystem after the review agents read it: supervised
launcher identity proof (#54/#55), chain-observability + stall-alarm doc
corrections (#56/#57), handoff-anchor gotcha restored (#58), repo-scoped
GitHub access (#59), bootstrap must prove a staged command is unrun (#60).
Have Plan agent (a) skim `git log -p 22ed187..main -- scripts/ docs/` before
designing, and note in Part 2 any finding those PRs already address.
