<!--
PURPOSE: ARCHIVE of the ledger (handoff.md). Older "# Session Handoff"
blocks, newest on top. Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 16 (2026-09-27/30): ledger defects fixed; then, the dogfood plan having closed, ticket 11 done, L48 verdict, findings → tickets 12–15; rolled hands-off at WARN

1. Registered `seq=16` (person restarted after the cap). `plan.sh status --project jev-integration`: `01-gated-integration` open, wave 1 of 3, 0/6 done, frontier `01-decision-note`; jev chain closed (`quit_plain`, 2026-09-25 22:23Z), no supervisor running. No `plan_closed` line, so ticket 11 stays open — launcher step 2 applied.
2. Found the s15 redo had left its stale first pass in `work/jev-integration/handoff.md` (session-6 block twice, both 6→7 bridges; the stale one claimed session 6 never closed). Removed the stale copy; its one unique fact (two supervisor processes) folded into the kept bridge. Commit 5f35266.
3. Found the s15 block of *this* ledger spliced into the header comment. Moved it out to its proper place above block 14; header restored.
4. Both recorded under "Dogfood findings" in `decisions.md` as a candidate ticket 12 (ledger lint). Suites green: test-plan 238, test-session-loop 140, test-doc-consistency 17, test-template-version 9. Nothing pushed.
5. Checkpointed (ac9e447); the user returned 2026-09-30 and asked to finish the remaining work. The dogfood plan had closed meanwhile (`plan_closed seq=17`, 2026-09-29; 18/18, 8 sessions, no split). Ticket 11 closed against that evidence; L48 verdict written (adopt as a plans-skill recipe, keep `wayfinder`); the 12 findings triaged into tickets 12 (ledger lint), 13 (default plan is the open one: plan.sh + session-loop), 14 (plan.sh ergonomics), 15 (docs/skill wording, incl. the L48 recipe). Status lines updated. Commit ecfac2e.
6. Found `scripts/check-ledger.py` already exists and passes both ledgers; ticket 12 narrowed to fixtures for the two s16 shapes + the checkpoint skill step. Rolled over hands-off at WARN (~120K); the user exited.

Learnings:
- A ledger write that anchors on the first `# Session Handoff` match hits the header comment's example text; anchor on `-->` (end of the header) instead.
- After any ledger write, `grep -c '^# Session Handoff'` against the expected count is a two-second check that would have caught both defects.

# Session Handoff — 15 (2026-09-25): ticket 11 started — the user chose `jev-integration` (integrate, gated on Jev access); plan `01-gated-integration` opened there (aec31e5); five dogfood findings recorded; chain cap reached

1. Registered `seq=15`; `git fetch origin` — nothing landed on origin. Posed the ticket-11 question; the user chose (a) `work/jev-integration` and added the constraint: Jev active only where a person has Jev access.
2. Opened the plan per "Create a plan": `plan.sh new gated-integration`, six nodes in three waves (01 decision-note → 02 join; 03 approve-decision [hitl] → 04 join; 05 spec-and-tickets → 06 join + structural replan). `check` silent, `sync` run, frontier `01-decision-note` (tier auto → frontier via the `design` leaf).
3. Mid-session, jev session 6 committed its checkpoint close (524bb2a, 17:23) ten minutes after this session started: the first pass at jev's launcher/ledger was against a stale snapshot and was redone against HEAD — session 6's four open grill questions now ride in nodes 01 and 03 (Q4 answered by the user's direction). Recorded as a finding.
4. Findings appended under "Dogfood findings" in `decisions.md`: `--leaf` needs `--tier auto`; `--blocked-by` wants full ids; checks run item-relative; the supervisor's `staged_alive` page names the wrong condition for an idle interactive session; two sessions on one checkout need a re-read before rewriting. None fixed (11 says note first).
5. Commit aec31e5 (jev item, work index, plans decisions). Suites green: test-plan 238, test-session-loop 140, test-doc-consistency 17, test-template-version 9. WARN at ~128K during the fix pass; this is session 15 of a 15-cap chain, so the plans chain ends here — 11 continues inside jev's chain. Not pushed.

Learnings:
- A plan can open before a spec or tickets exist: draft → hitl approval → spec/tickets → structural replan at the join. This is the L48 shape (wayfinder as a plan) in practice; the verdict waits for the chain to run it.
- `AskUserQuestion` at the launcher's "pose verbatim" step got the answer in one round; the constraint the user attached went straight into `plan.md` → Goal rather than a new grill.

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

# Session Handoff — 10 (2026-09-24): ticket 07 slice a — the loop's plan-hook tests, red

**Summary.** Seq 10, supervised chain, hands-off. Started at ~58K (the
launcher's read list is heavy), hit WARN at ~127K right after the tests were
written, so the ticket ships in two slices. Slice a (`c2ea565`): four
fake-child cases in `scripts/tests/test-session-loop.sh` — P1 `chain.plan`
binding (none / single open / `--plan` / unresolved / ambiguous), P2
`plan_invalid leg=sync|check` refusing the next session, P3 `plan_closed`
ending the chain (and the literal S27 conjunction: closed with the reconcile
node dropped is not `plan_closed`), P4 hitl-only frontier → interactive with
the board synced between children. A `mkplan` helper writes a three-node
one-wave plan (work done, hitl, reconcile) with the board and position
markers; the stub gains `stage-plan` (rolls over keeping the launcher's
position markers, commits nothing); `plan.sh` ships into the throwaway
workspace. 24 red, 116 green (the 105 plan-less assertions untouched). No
code in `session-loop.sh` yet — that is slice b.

**Choices made (one decision note, 2026-09-24).** One new code,
`plan_invalid`, with legs: `unresolved` / `ambiguous` at start (refuse, exit
4, record untouched), `sync` / `check` between children (broken, exit 1,
notify, staged command kept, no close — the shape of `staged_invalid`
mid-chain). `plan_closed` is emitted after the `staged` verdict of the child
that finished the plan (the way `cap` follows `staged`), writes
`chain.closed.reason = plan_closed`, so a restart refuses `chain_closed`.
The interactive choice is the supervisor's own: it sets `launch.mode` to
`interactive` in the record and the `staged` verdict line reads
`mode=interactive`; the child's `--loop-mode` is not consulted for it. The
gate runs only between children (a chain started on a closed or broken plan
runs one session first) — per the ticket's wording; noted, not changed.

**Verification.** `bash scripts/tests/test-session-loop.sh` → passed=116
failed=24, every failure a missing-feature failure (`--plan` unknown option,
`chain.plan` null, no gate). `test-plan.sh` not touched. shellcheck not
installed — not run.

**Budget.** WARN (~127K) as the tests landed; rolled at ~135K. Nothing
pushed; `main` is 38 commits ahead of `origin/main` before the rollover
commit. Untracked `work/jev-integration/research/spike.{md,py}` belong to
another item — left alone.

# Session Handoff — 9 (2026-09-24): ticket 06 done — model knob per runtime, `start` stamp, `add --leaf`, `plan-tiers.env`, docs "Tiers"

**Summary.** Seq 9, supervised chain, hands-off. Ticket 06 finished in two
commits, test-first. Slice b (`67f1c63`): node JSON carries `model` from
`PLAN_MODEL_<RUNTIME>_<TIER>` (null = session model); the runtime is
`--runtime` → `PLAN_RUNTIME` → the bound registry record's `runtime` →
unknown, with `registry_project` now reading through a shared
`registry_record` finder and `resolve_runtime` caching the walk; `start`
logs `started, tier <t>` / `… unavailable on <runtime> (session model)` /
`… unavailable (no runtime; session model)`; T12d re-pinned, T19m–u. Slice
c (`c62fcb6`): `add --leaf <label>`; a `tier_<label>:` outside
`frontier|standard|cheap` refused naming `plan.md` (and a `malformed`
violation in `check`); a bad `PLAN_TIER_*` refused naming `plan-tiers.env`;
an empty knob is unset; the checked-in `plan-tiers.env` (three-row starter
policy, claude `opus`/`sonnet`/`haiku`, codex/gemini/opencode/copilot rows
commented out with each model flag named); `docs/plans.md` → `leaf` row,
`tier_<label>:`, ` (auto)`, `tier_resolved`/`model`, the `malformed` rule,
a "Tiers" section; `docs/workspace-structure.md` lists the file; T20a–h.
Ticket 06's three boxes ticked, status `done`. No new decision note — the
2026-09-24 tiers note already settles the shape.

**Choices made without a decision note.** The forced stamp reads `started
(forced: not on the frontier), tier <t>…` — "forced" qualifies "started".
`check` lints `plan.md`'s `tier_<label>:` lines but not `plan-tiers.env`
(the env is workspace state, not the plan; every other verb refuses on it).
The registry walk for the runtime only runs when some `PLAN_MODEL_*` knob
exists, so a workspace with no knobs pays nothing. `PLAN_TIER_*` / `tier_<label>:`
accept `frontier|standard|cheap` only — `auto` is not a policy value.
The T19 gemini knob became `gemini-pro` so the no-model-name grep (`-w`)
cannot collide with prose.

**Verification.** `bash scripts/tests/test-plan.sh` → passed=238 failed=0;
`test-doc-consistency.sh` 7/7; every `scripts/tests/test-*.sh` green after
slice b (not re-run after slice c's doc-only changes beyond the two named).
shellcheck not installed — not run. `/code-review` skipped at WARN.

**Suggested skills for the successor.** `tdd` for ticket 07 (fake child in
`test-session-loop.sh` first); `decision-log` only if the `plan_closed` /
interactive-launch shape forces a choice the spec (S25–S28) leaves open.

**Budget.** WARN (~122K) as slice c's docs landed; rolled at ~129K. Nothing
pushed; `main` is 36 commits ahead of `origin/main`. Untracked
`work/jev-integration/research/spike.{md,py}` belong to another item — left alone.

# Session Handoff — 8 (2026-09-24): ticket 05 done (docs); ticket 06 slice a — tier resolution, T19a–l

**Summary.** Seq 8, supervised chain, hands-off. Ticket 05's doc half landed
(`f644e8a`): the `sync` row and the launcher's `position` block shape in
`docs/plans.md`, the marker convention once in
`docs/work-directory-conventions.md` → "Generated blocks (markers)"; ticket
05 `done`. Then ticket 06, test-first, first slice (`6dc70f6`): T19a–l in
`scripts/tests/test-plan.sh` (12 assertions, 221 total) — the resolution
order node tier → `plan.md` `tier_<label>:` → `PLAN_TIER_<LABEL>` in
`plan-tiers.env` → the plan's `default_tier` → `standard`, keyed by the
node's new optional `leaf:` label; hitl now defaults to `frontier` and
reconcile/hitl resolve `auto` to `frontier`; `frontier` prints the resolved
tier with ` (auto)`; every node's JSON carries `tier_resolved`. In
`scripts/plan.sh`: `tier_env_json` (sources `plan-tiers.env` in a subshell,
`compgen -A variable` → `{policy, models}` — `models` is already parsed as
`{runtime: {tier: model}}` for the next slice), `plan_tiers_json`,
`RESOLVE_JQ` applied inside `load_nodes`. One decision note (2026-09-24,
tiers). Suites green; WARN at ~122K right after green, so the slice was
committed and the session rolled.

**Left for the successor (ticket 06, slices b and c).** (b) `model` on node
JSON from `$env.models[runtime][tier_resolved]` (null = session model); the
runtime from `--runtime` → `PLAN_RUNTIME` → the bound registry record's
`runtime` (split `registry_project` into a record finder so the walk is
shared) → unknown; `start` logs `started, tier <t>` with a knob, `started,
tier <t> unavailable on <runtime> (session model)` without, `… unavailable
(no runtime; session model)` when unknown — update T12d's pinned line; a
T19 case that no model name (grep the mapping's values) lands in any node
file or `plan.md` after `start`. (c) `add --leaf <label>`; refusals: a
`tier_<label>:` value outside `frontier|standard|cheap` → exit 1 naming
`plan.md` (and a `malformed` violation in `check`), a bad `PLAN_TIER_*`
value → exit 1 naming `plan-tiers.env`. Then the checked-in `plan-tiers.env`
(claude: `opus`/`sonnet`/`haiku` CLI aliases; codex, gemini, opencode,
copilot rows present but unset, each with its `--model` flag named, the
unset-means-session-model case explained in the header), the `plan.sh`
header comment, and `docs/plans.md`: `leaf` row in the node table, `tier_<label>:`
in the plan.md frontmatter paragraph, `frontier`'s ` (auto)`, `add --leaf`,
`tier_resolved`/`model` in the `--json` paragraph, a short "Tiers" section
(order, the two files, per-runtime mapping, the unavailable case, the Log
stamp, "no model name in a plan or node file"). Tick the three boxes, set
ticket 06 `done`.

**Choices made without a decision note.** The board (`sync`) keeps showing
the written tier, not the resolved one — the orchestrator reads `frontier`.
An absent or unknown `leaf:` skips straight to the plan default (no
violation, no warning). `default_tier: auto` bottoms out at `standard`.
`tier_env_json` treats a missing `plan-tiers.env` as empty.

**Verification.** `bash scripts/tests/test-plan.sh` → passed=221 failed=0;
`test-doc-consistency.sh` 7/7 after the ticket 05 docs. shellcheck not
installed — not run. `/code-review` skipped at WARN.

**Budget.** WARN (~122K) the moment slice a went green; rolled under WARN.
Nothing pushed; `main` is 33 commits ahead of `origin/main`. Untracked
`work/jev-integration/research/spike.{md,py}` belong to another item — left alone.

# Session Handoff — 7 (2026-09-24): ticket 05 code landed — `plan.sh sync`, markers, T18; docs left

**Summary.** Seq 7, supervised chain, hands-off. Implemented the code half of
ticket 05 test-first: T18 appended to `scripts/tests/test-plan.sh` (23 new
assertions, 209 total) — the board rendered between `<!-- plan:begin board -->`
markers on the fixture, a second `sync` byte-identical for both files and no
node file touched, text outside the markers byte-identical (diffed), the
`position` block in `work/<item>/next-session.md`, the board and block
following node edits, the all-done footer, `--json`, a launcher without
markers / no launcher / `plan.md` missing its end marker → exit 1 naming the
file and the marker with nothing written, a closed plan still syncing. Then
`marker_check`, `marker_splice` (awk; the block via `ENVIRON`, so no escape
processing) and `cmd_sync` in `scripts/plan.sh`; `sync` dispatches through
`resolve_plan` (read-style). The fixture `plan.md` board was re-rendered by
`sync` itself (wave number only, footer `Frontier: none (07-spec doing).
Remaining: 3 of 9. Sessions used: 2.`) so T18i holds. Ticket 05's three boxes
ticked; status still `ready-for-agent` until the docs land. One decision
note (projection semantics, both markers checked first). Commit `73e4752`.
Every shell suite green (doc-consistency 7/7).

**Left for the successor (ticket 05's doc half).** `docs/plans.md` → the
`plan.sh` table needs a `sync` row (and the Format paragraph already names
the board markers; add the launcher's `position` markers and the two-line
block shape: `Position: plan …, <status>, wave n of m, done d/t, doing, todo,
blocked, dropped, sessions n.` then `Frontier: <ids | none (<id> doing)>.
Remaining: r of t — wave n: <id status, …>.`). `docs/work-directory-conventions.md`
gets the marker convention written once (its own short section near
"Required and optional files": generated blocks sit between
`<!-- plan:begin <name> -->` / `<!-- plan:end <name> -->`, everything outside
is hand-written, markers are added by hand and never invented; opt a launcher
in by adding the `position` pair). The `create-work-item` launcher template
was deliberately left alone — S22 says the scaffold adds nothing extra; S34
(the conditional "sync first" step in rollover/checkpoint/template) is a
later ticket. Then set ticket 05 `done`.

**Choices made without a decision note.** Text output is one line, `synced
<plan.md path>, <launcher path>` relative to the workspace root; `--json` is
`{plan, files:[…]}`. The launcher path is fixed at `work/<item>/next-session.md`.
The board's rows sort by wave then id. The empty-frontier parenthesis lists
the current wave's `doing`/`blocked` nodes only (todo nodes waiting on them
are implied). T18 introduced `between`/`outside` awk helpers in the suite.

**Verification.** `bash scripts/tests/test-plan.sh` → passed=209 failed=0;
every `scripts/tests/test-*.sh` green. shellcheck not installed — not run.
`/code-review` skipped at WARN.

**Budget.** WARN (~120K) hit while the T18 red cases were being written;
~133K after green; rollover under WARN. Nothing pushed.

# Session Handoff — 6 (2026-09-23): ticket 04 landed — `plan.sh` write verbs and the state machine

**Summary.** Seq 6, supervised chain, hands-off. Implemented ticket 04
test-first, one verb per slice: T12–T17 appended to
`scripts/tests/test-plan.sh` (77 new assertions, 186 total) — `start`
(frontier / `--force` / `blocked` resume / `--session` / no number refused /
closed plan refused), `done` (no check, passing check from the item dir with
`WORKSPACE_ROOT`, failing check refused, `loop` 1 and 2 exhaustion writing
`blocked`, `--force` from todo, hitl needs `--by`), `verify`, `block`, `drop`,
`add` (every flag, taken slug, dangling blocker), `note`. Then `cmd_<verb>`
over shared plumbing: `fm_set` (awk, keeps line order and `  # comments`),
`section_append`/`log_append`, `run_check`, `failed_attempts`, `report`;
`resolve_plan write` is strict and refuses a closed plan; `ready`/`frontier`
moved into `DERIVE_JQ` so `start` and `frontier` share one definition.
`docs/plans.md`: seven table rows, a "State machine" paragraph, exit-code
line. Ticket 04 boxes ticked, status `done`. One decision note (stamp source,
check cwd, attempt counting, closed-plan refusal, `start` not linting).
Commit `1780d30`. Full shell suite green.

**Choices made without a decision note.** `--by` accepts any actor, not only
the literal `human` (docs say `--by human`). `done` needs `doing`; `--force`
lifts that for `todo` and is logged as `forced from todo`. `drop` refuses
only an already-dropped node (done → dropped is allowed, "any → dropped").
`block` needs `doing` and a reason (usage otherwise). `add` requires
`--wave` (no "current wave" default), writes `tier`/`parallel`/`loop`/
`check`/`isolated` only when given, and does not lint — the fixture shows a
work node added after wave 3's reconcile trips `reconcile-last` on the next
`check`, which is the lint's job. `note` stamps `s<n> ·` when a session is
known and is otherwise plain. Write verbs honour `--json` with `{id,status}`;
`verify --json` is `{id,result,exit}`. The check's stdout goes to stderr so
`--json` stays clean. The octal bug: `$((n + 1))` on `09` failed silently
in `add`; fixed with `10#$n` in `add` and the identical loop in `new`.

**For ticket 05 (sync + markers).** Wave names ("1 ground") still live in no
frontmatter; `add` writes none. Derive the board's wave column as the number
alone, or omit the name — the fixture board's `1 ground` text is the concept
sketch, not a contract. The fixture's `09-reconcile-verdict` check still
names a plan that does not exist (exit 2) — harmless for `sync`; `done`
tests supply their own check via `addf`. `section_append` in `plan.sh` is
the one place that edits prose sections; the board goes between markers
instead (nothing outside them is generated), so it needs its own splice.

**Verification.** `bash scripts/tests/test-plan.sh` → passed=186 failed=0;
every `scripts/tests/test-*.sh` green (doc-consistency 7/7). shellcheck not
installed — not run. `implement` asks for `/code-review` afterwards; skipped
at WARN, self-reviewed the diff instead.

**Budget.** WARN at ~126K right after the suite went green; wrap-up and
rollover under STOP. Nothing pushed.

# Session Handoff — 5 (2026-09-23): ticket 03 landed — `plan.sh check`, the lint

**Summary.** Seq 5, supervised chain, hands-off. Implemented ticket 03
test-first: T11 appended to `scripts/tests/test-plan.sh` (32 new assertions,
109 total) — the clean fixture is silent and exit 0, `--json` is `[]`, then
one fixture variant per rule tripping exactly that rule (reconcile count zero
and two, reconcile not last, check on a hitl node, dangling `blocked_by`, doing
with no session, malformed frontmatter and an unknown value, wave size via
plan `wave_max`, `PLAN_WAVE_MAX` env, `context-budget.env`, and precedence),
plus "every violation at once" and malformed `plan.md`. Then `cmd_check` over
a lenient `node_parse` (the strict `node_json` now wraps it) and a
`DANGLING_JQ` fragment shared with `load_nodes`. `docs/plans.md`: `check` row,
"Check rules" list, `wave_max` in the plan frontmatter. `context-budget.env`:
`PLAN_WAVE_MAX=6` with rationale. Ticket 03 boxes ticked, status `done`. One
decision note (lenient pass; "last" = highest id; wave size knob placement).
Full shell suite green.

**Choices made without a decision note.** Violation text is `<where>:
<message>` where `where` is the node's path, `plan.md`'s path, or `wave N`;
the JSON object is `{rule, id, wave, path, message}` with nulls where a field
does not apply. Output order is rule order (malformed, blocked-by, per-wave
reconcile/size, hitl-check, doing-sessions), not by node. `reconcile-last` is
skipped when the wave's reconcile count is not one, so a broken wave trips one
rule, not two. A malformed node keeps its file stem as `id` so its dependants
are not reported as dangling. Dropped nodes count toward wave size. `check`
resolves the plan like the other read verbs; with a malformed `plan.md` and
no `--plan`, resolution itself refuses before `check` runs (`open_plans` →
`plan_status`), which is why T11z6 passes `--plan` — the fixture's own
09 node already does the same.

**For ticket 04 (write verbs).** `done` must run the node's `check`; the
fixture's `09-reconcile-verdict` check invokes `plan.sh check --project plans
--plan 01-concept` — a plan that does not exist in `work/plans/plans/`
(exit 2), so a `done` test on that node needs its own check command or a
fixture edit. `start` should probably refuse a plan that fails `check`
(ticket 07 does this between children; deciding whether write verbs do too
is 04's call).

**For ticket 05 (board).** Wave names still live in no frontmatter (ledger
block 3). Unchanged; `check` did not need them.

**Verification.** `bash scripts/tests/test-plan.sh` → passed=109 failed=0;
every `scripts/tests/test-*.sh` green (doc-consistency 7/7). shellcheck not
installed — not run.

**Budget.** ~108K at the record after green (OK); wrap-up under WARN.
Nothing pushed.

# Session Handoff — 4 (2026-09-23): ticket 02 landed — `plan.sh` frontier / remaining / graph

**Summary.** Seq 4, supervised chain, hands-off. Implemented ticket 02
test-first: T8–T10 appended to `scripts/tests/test-plan.sh` (28 new
assertions, 77 total) — frontier text and `--json`, the two empty-frontier
outcomes, wave order (a lower wave's todo node is the whole frontier; a
later wave's unblocked node is named in the reason but not offered), mixed
done/dropped blockers, a dangling `blocked_by`, `remaining` order (wave then
id) and emptiness, `graph` text and `{plan,nodes,edges}` — then the three
verbs as `cmd_<verb>` over one shared jq prelude (`DERIVE_JQ`: padding,
current wave, finished set). `docs/plans.md` table extended plus a
"Frontier" paragraph. Ticket 02 boxes ticked, status `done`. One decision
note (dangling blocker refused at load). Full shell suite green.

**Choices made without a decision note.** Empty frontier with nothing
unfinished is exit 0 and silence (not a refusal — `status` says the plan is
complete); with `--json` the empty-and-unfinished case prints `[]` on stdout
and the reason on stderr, exit 1, so a caller branches on the code as
documented. `frontier`/`remaining --json` return full node objects (what
`show --json` prints) rather than a trimmed shape — one shape to learn.
`remaining` prints `id status wave` one per line, not the concept sketch's
single id line — grep-able, and status is what "what is left" is for. No
DOT option (ticket calls it optional; `graph --json` carries the edges).
The reason line uses an em-dash after "nothing ready" — cosmetic, change
freely.

**For ticket 03 (`check`).** The loader now refuses a dangling `blocked_by`
before any verb runs, so `check`'s "dangling or cross-plan blocked_by" rule
cannot be reached through `load_nodes` as-is: `check` must either parse with
its own lenient pass to report all violations at once, or accept that this
one rule is a load-time refusal (one line, exit 1) rather than a listed
violation. Decide at the start of 03 and note it.

**For ticket 05 (board).** Wave names still live in no frontmatter (ledger
block 3); `graph` prints bare `wave N` headings. Unchanged.

**Verification.** `bash scripts/tests/test-plan.sh` → passed=77 failed=0;
every `scripts/tests/test-*.sh` green (doc-consistency 7/7). shellcheck not
installed — not run.

**Budget.** ~91K at the last record before wrap-up (OK). Nothing pushed.

# Session Handoff — 3 (2026-09-23): ticket 01 landed — `plan.sh` new / show / status, fixture, tests, docs/plans.md

**Summary.** Seq 3, supervised chain, hands-off. Implemented ticket 01
test-first at the one agreed seam (the command line): fixture plan
`scripts/tests/fixtures/plan-01-concept/` (the concept's worked example, nine
nodes), `scripts/tests/test-plan.sh` (49 assertions: usage, status text and
`--json`, show, refusals naming the file, `new` numbering and refusal,
plan and project resolution incl. the registry binding via an ancestor pid
and a recycled-pid guard), then `scripts/plan.sh` (bash 3.2 + jq, ~170
lines). Full shell suite green. `docs/plans.md` started (format + verbs +
exit codes + resolution); indexed in `docs/README.md`. All five acceptance
boxes ticked; ticket status `done`.

**Choices made without a decision note (no rejected alternative worth
recording).** Wave names on the board ("1 ground") are not in any
frontmatter; the board renderer (ticket 05) will have to derive them, most
likely from the wave's reconcile-node slug — flag when 05 starts. `show`
parses the whole plan (cheap, keeps one loader). `isolated` is a JSON
boolean in `--json`. Inline `# comment` stripping needs whitespace on both
sides of the `#`.

**Verification.** `bash scripts/tests/test-plan.sh` → passed=49 failed=0;
every other `scripts/tests/test-*.sh` unchanged and green. shellcheck is not
installed on this machine — not run.

**Budget.** WARN reached right after the doc (~117K at the last record);
wrapped up here. Nothing pushed.

# Session Handoff — 2 (2026-09-23): grill closed, verdict BUILD, concept + spec + 11 tickets; rolled at WARN

**Summary.** Seq 2, supervised chain, launched interactive for the grill.
The user was present. Two grill rounds settled all seven open points
(recommended answers taken on every one; the user asked for plain-language
explanations on the Stop-hook and node-kind questions before deciding).
Landed: seven new notes in `decisions.md` (no "(proposed)" left; both OPEN
sections resolved in place), `concept.md` (definition, five properties,
glossary, this item as a worked plan in node-file form), README status line
= BUILD, `spec.md` (36 stable S-items, two testing seams: the `plan.sh`
command line and the existing session-loop fake-child harness), eleven
tracer-bullet tickets under `issues/` approved by the user as listed,
backlog card L48 (wayfinder as a plan template, deferred). WARN hit right
after the tickets; wrapped up here.

**Decisions this session** (why + rejected in `decisions.md`): build format
+ `plan.sh` + loop hook, no runner; `blocked` explicit / `done` verified
only; HITL nodes have no `check`, human tick, interactive rollover when only
HITL remain; `<!-- plan:begin/end <name> -->` markers; `kind: work |
reconcile | hitl`; integration = all parts except the Stop/SessionEnd hook;
wayfinder untouched in v1 (L48).

**State.** All of the above committed by this rollover. Branch main, nothing
pushed. Spec approved by the user in this session;
tickets are `ready-for-agent`. Frontier: ticket 01 only.

**Next.** `next-session.md` → implement ticket 01 with `implement` + `tdd`.

**Key files.** `work/plans/spec.md`, `work/plans/issues/01-*.md`,
`work/plans/concept.md`, `work/plans/decisions.md`.

# Session Handoff — 1 (2026-09-23): seam inventory + decisions from the concept discussion; rolled at WARN before the grill

**Summary.** First registered session (seq 1, supervised chain). The user
drove the concept in conversation instead of a formal grill; the agent
grounded each point against the workspace and proposed formats. Two files
landed: `seams.md` (ten mechanisms vs. the plan concept, every line claim
verified on disk; two Explore subagents did the reading, spot-checked by the
parent) and `decisions.md` (ten notes: nine **settled**, one **proposed**,
plus two OPEN items). Rolled over at the WARN threshold with the user's
consent, option "roll over now".

**Decisions (see `decisions.md` for the why and the rejected alternatives).**
Node = one session's budget, split on overrun; plans under
`work/<item>/plans/NN-<slug>/`, one open at a time; chain sessions are
orchestrators; waves end in a named reconcile node; parallelism = subagents
within a session, sessions serial, `parallel` caps on node and wave; tiers
abstract (`frontier|standard|cheap|auto`), uniform by default, lookup table
on `auto`, rise at fan-in; replan = capture now (`note`), restructure at
reconcile, authority by blast radius; optional `chain.plan` + `plan_closed`
verdict for the loop; `plan.sh` state tooling (bash+jq, derive-don't-decide),
never a runner; "work item" not "worktree". Proposed, unconfirmed: node files
as truth + rendered `plan.md` index, status set `todo|doing|done|blocked|dropped`.

**Current state.** `seams.md`, `decisions.md` new and committed by this
rollover. No `concept.md`, no `spec.md`, no build verdict on the README
status line. Branch main, nothing pushed.

**Open questions (for the grill).** Build/no-build verdict; confirm the node
file format and status set; `check` semantics for HITL nodes; marker
convention for generated blocks (none exists in the workspace); the
integration question the user raised last: how plans enter the template and
how agents learn them — proposed answer under "OPEN" in `decisions.md`.

**Suggested skills.** `grill-with-docs` on the OPEN items only (the settled
notes are not to be re-litigated); `decision` to record each answer;
`to-spec` once the verdict is build.

**Key files.** `work/plans/seams.md`, `work/plans/decisions.md`,
`work/plans/README.md`, `skills/grill-with-docs/SKILL.md`.

# Session Handoff — 2026-09-23 (scaffold): item created; concept exploration comes next

**Summary.** Scaffolded by a session not bound to this item (so this block
carries no session number; the counter starts at the first
`register --project plans`). The user asked for a work item to explore the
concept of **plans** in this workspace: plans that use graphs, loops, and
sessions to accomplish work in a structured, dependency-aware,
parallelism-aware, and LLM-tier-aware way. A quick survey found the
ingredients already present but disjoint (`to-tickets` blocking edges,
`wayfinder` map/frontier, Workflow tool + `research-wave` fan-out, `/loop`
and `session-loop.sh` chaining, `rlm` root/leaf tiers, launcher/ledger), so
the README frames the item as "should one artifact join them, and what would
it be" rather than "build a runner". The local-only `learn-agentic-workflows`
teaching item (gitignored) covers the graph-orchestration background and may
be worth a read when charting.

**State.** README (goal, success criteria pending a build/no-build verdict),
launcher (seam inventory → grill → concept note), this ledger; row added to
`work/README.md`. No `seams.md`, `concept.md`, `decisions.md`, or `spec.md`
yet. Not committed by the scaffolding session.

**Next.** `next-session.md` → seam inventory, then grill the concept.
