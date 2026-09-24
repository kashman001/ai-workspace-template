<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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
