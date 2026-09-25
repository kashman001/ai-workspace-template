<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff — 15 (2026-09-25): ticket 11 started — the user chose `jev-integration` (integrate, gated on Jev access); plan `01-gated-integration` opened there (aec31e5); five dogfood findings recorded; chain cap reached

1. Registered `seq=15`; `git fetch origin` — nothing landed on origin. Posed the ticket-11 question; the user chose (a) `work/jev-integration` and added the constraint: Jev active only where a person has Jev access.
2. Opened the plan per "Create a plan": `plan.sh new gated-integration`, six nodes in three waves (01 decision-note → 02 join; 03 approve-decision [hitl] → 04 join; 05 spec-and-tickets → 06 join + structural replan). `check` silent, `sync` run, frontier `01-decision-note` (tier auto → frontier via the `design` leaf).
3. Mid-session, jev session 6 committed its checkpoint close (524bb2a, 17:23) ten minutes after this session started: the first pass at jev's launcher/ledger was against a stale snapshot and was redone against HEAD — session 6's four open grill questions now ride in nodes 01 and 03 (Q4 answered by the user's direction). Recorded as a finding.
4. Findings appended under "Dogfood findings" in `decisions.md`: `--leaf` needs `--tier auto`; `--blocked-by` wants full ids; checks run item-relative; the supervisor's `staged_alive` page names the wrong condition for an idle interactive session; two sessions on one checkout need a re-read before rewriting. None fixed (11 says note first).
5. Commit aec31e5 (jev item, work index, plans decisions). Suites green: test-plan 238, test-session-loop 140, test-doc-consistency 17, test-template-version 9. WARN at ~128K during the fix pass; this is session 15 of a 15-cap chain, so the plans chain ends here — 11 continues inside jev's chain. Not pushed.

Learnings:
- A plan can open before a spec or tickets exist: draft → hitl approval → spec/tickets → structural replan at the join. This is the L48 shape (wayfinder as a plan) in practice; the verdict waits for the chain to run it.
- `AskUserQuestion` at the launcher's "pose verbatim" step got the answer in one round; the constraint the user attached went straight into `plan.md` → Goal rather than a new grill.

# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 14 (2026-09-24): ticket 10 done — front door, reference, glossary, downloader work

**Summary.** Seq 14, supervised chain, hands-off. Started at ~58K, ended
~118K (at the WARN edge; rolled over rather than start ticket 11, which needs
a fresh window and a person's call — below). Slice a: `CONTEXT.md` gains a
"Plans" section (three-line definition, when to use one, the `plan.sh status`
one-liner, pointers to `docs/plans.md` and `skills/plans/SKILL.md`) and the
plan glossary under Language (work item with *worktree* as the alias to avoid,
plan, node, wave, reconcile node, HITL node, check, tier, frontier) as a
labelled block below the project's own `<term>` placeholder. Slice b:
`docs/plans.md` completed — a wayfinder-and-plans paragraph (map = `plan.md`,
decision tickets = `hitl` nodes; coexist until the first real plan closes,
L48), a "Per runtime" section (one table row per runtime: how the skill is
invoked, which `plan-tiers.env` knobs ship, registration), and a worked example
quoting the fixture plan with verb output verified against a temporary copy of
it under `work/` (removed after); the optional `plans/NN-<slug>/` row in
`docs/work-directory-conventions.md`; a **Plan** entry in the non-engineer
glossary; `docs/plans.md` and `skills/plans/` in the structure tree
(`workspace-structure.html` rebuilt — the drift guard flagged it).
`docs/README.md` already indexed `plans.md`. Slice c:
`test-doc-consistency.sh` gains a paths phase — every backticked path rooted at
`docs/ skills/ scripts/ .claude/ work/plans/` in `CONTEXT.md`, `docs/plans.md`,
`skills/plans/SKILL.md`, `.claude/commands/plan.md` exists on disk, plus the
two front-door pointers and the index row (7 → 17 checks); `TEMPLATE_VERSION`
2026-09-22 → 2026-09-24; backlog changelog row for the plans feature, "Last
updated" bumped, scorecard unchanged. Ticket 10 boxes ticked, status `done`.
Suites: test-plan 238/238, test-session-loop 140/140, test-doc-consistency
17/17, test-template-version 9/9, test-agent-entrypoints 10/10.

**Decisions** (commit trailers): the glossary block sits under Language, not
in its own section, because skills read Language for aliases to avoid; the
worked example quotes the committed fixture, so the doc and `test-plan.sh`
cannot drift apart silently; the backlog gets a changelog row, not a resolved
card — plans never had a card, and L48 stays open by its own gate.

**Learnings:** read verbs can be exercised on a fixture by copying it to
`work/<tmp-item>/plans/NN-<slug>/` (the directory name must be the plan id,
not the fixture's folder name) with `--project <tmp-item>`. Backticked
*commands* (`scripts/plan.sh check`) look like paths to a path test — strip
everything after the first space.

**Not done.** Ticket 11 (dogfood) — it needs a real multi-session item to be
the first plan, which is the user's choice (question carried verbatim in the
launcher). Nothing pushed (main 55 ahead of origin). The item's own
`README.md` status line still reads session 2's verdict; ticket 11 owns
updating it.

# Session Handoff — 13 (2026-09-24): ticket 09 done — the `plans` skill, `/plan`, Replans reference

**Summary.** Seq 13, supervised chain, hands-off. Started at ~59K, ended
~115K (below WARN; ticket 10 left for a fresh window). The create procedure
was exercised first on a copy of this item's `issues/` in a throwaway item
under the scratchpad (`plan.sh new`, waves by longest blocker chain, `add` in
wave order with a reconcile node closing each wave, ticket bodies into
Goal/Acceptance, `done --force --by import` for finished tickets): 18 nodes,
7 waves, `check` silent, `frontier` = the ticket-09 node, `sync` wrote the
board and the Position block. The reconcile and replan steps were then run on
that plan (`start`, a subagent-style Log line + tick, `done`, `note`, a
same-wave `add` renamed below the join, `check` silent). Slice a
(`1214a0b`): `skills/plans/SKILL.md` — create / run a reconcile node / replan
procedures + the subagent prompt template (Log lines `- <actor> · …` and
Acceptance ticks only; `status` written by `plan.sh` in the orchestrating
session, never by the child); `docs/plans.md` gains the "Replans" paragraph
the skill points at (authority ladder local / structural / goal, placement,
same-wave numbering). Slice b (`85cb19c`): `.claude/commands/plan.md` +
the `CONTEXT.md` Workspace Skills line; `skills/vendored-skills.md` untouched.
Ticket 09 boxes ticked, status `done` (`38e19af`). Suites: test-plan 238/238,
test-session-loop 140/140, test-doc-consistency 7/7.

**Decision.** A follow-up found at the join goes to the next wave, one found
mid-wave to the same wave (renamed below the reconcile node) — `done` does not
look at blockers, so an edge added to the running reconcile node would be
closed over silently; note in `decisions.md`, `Promote?: no`.

**Learnings:** every `plan.sh` verb needs `--project` when the session is
bound to another item — the registry binding beats the cwd (the skill says so
up front). `done --force --by import` still stamps `sessions` with the
current seq.

**Not done.** Ticket 10 (front door: `CONTEXT.md` Plans section + glossary,
`docs/plans.md` completion, indexes, backlog card, `TEMPLATE_VERSION`,
doc-consistency paths) and 11. Nothing pushed (main 50 ahead of origin).

# Session Handoff — 12 (2026-09-24): ticket 08 done — node split at rollover, sync step in three skills

**Summary.** Seq 12, supervised chain, hands-off. Started at ~58K, ended
~105K (below WARN). The split was exercised three times on a fixture copy
under the scratchpad (plain, with a `check:`, and a verbatim replay of the
skill text) before it was written down. Slice a (`66c8978`):
`skills/session-rollover/SKILL.md` step 3 gains the conditional sync line and
the six-verb split (`show` → `add` → rename to `<id>-b` + carry `sessions` →
dependants' `blocked_by` → drop `check:`, `done`, Log line → `check`, `sync`);
step 5 keeps the position markers when a plan is open; reconcile/hitl nodes
are never split. Slice b (`89490e5`): the same sync line in
`skills/checkpoint/SKILL.md` step 3. Slice c (`874a623`):
`skills/create-work-item/SKILL.md` scaffolds the `## Position` marker block
only on `--plan` (argument-hint updated in `.claude/commands/create-work-item.md`).
Ticket 08 boxes ticked, status `done` (`e50bedf`). Suites: test-plan 238/238,
test-session-loop 140/140, test-doc-consistency 7/7.

**Decision.** The remainder is renamed to the origin's number after `add`
(the `reconcile-last` lint compares ids as strings and `add` numbers past the
wave's join); note in `decisions.md`, `Promote?: no`.

**Not done.** Ticket 09 (the `plans` skill + `/plan`) — a whole skill with
three procedures and a fixture walk-through; left for a fresh window. Nothing
pushed (main 46 ahead of origin).

# Session Handoff — 11 (2026-09-24): ticket 07 done — the loop's plan hook, code + docs

**Summary.** Seq 11, supervised chain, hands-off. Started at ~56K, ended
~110K (below WARN). Slice b (`232688d`): `scripts/session-loop.sh` gains
`--plan <slug>`; after the `supervisor_live` gate it binds a plan (`--plan` →
`chain.plan` in the record → the single `plans/*/plan.md` with `status: open`;
two open → `refused plan_invalid leg=ambiguous`, a slug `plan.sh status`
cannot read → `leg=unresolved`, both before any write) and stamps
`chain.plan` in the start write. Between children, when bound: `plan.sh
sync` then `check` (failure → `broken plan_invalid leg=sync|check`, lines
relayed, staged command kept); a `closed` plan whose highest-wave reconcile
node is `done` → `verdict=plan_closed`, `chain.closed` written, exit 0; a
hitl-only frontier → `launch.mode=interactive` in the record. Docs box
(`b388f07`): `docs/context-budget.md` usage, a "Plans" paragraph under "The
supervisor", the `plan_closed` verdict row, `plan_invalid` in the broken list
and the reason-code table; one sentence in `docs/plans.md` → "Resolution".
Ticket 07 boxes ticked, status `done`. Suites: test-session-loop 140/140,
test-plan 238/238, test-doc-consistency 7/7.

**One ordering detail the tests settled** (no new decision note — the shape
was pinned by P2c/P4b): the `staged` verdict is emitted *before* the plan
outcome, carrying the plan-derived mode; a `plan_invalid` break or a
`plan_closed` close follows it. So the child's rollover is judged on its own,
then the plan says whether the chain goes on.

**Not done.** Ticket 08 (node split at rollover + the conditional sync step
in `session-rollover`, `checkpoint`, `create-work-item`) — needs a fresh
window; the launcher points at it. Nothing pushed (main 41+ ahead of origin).
