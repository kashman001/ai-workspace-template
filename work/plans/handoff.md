<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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
