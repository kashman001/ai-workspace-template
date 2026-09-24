<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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
