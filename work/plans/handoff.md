<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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
