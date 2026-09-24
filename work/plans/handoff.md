<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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
