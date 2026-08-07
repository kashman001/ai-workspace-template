# Plan — context-snapshot tool (layers 2+3) + rollover property inheritance

User-accepted 2026-08-07. Three deliverables, built in one session.

## D1 — Layer 2: per-turn phase diffs in `context-inspect.sh`

New `--phases` flag. Adds a per-assistant-turn table on top of the existing
report: exact context total (usage envelope), delta vs previous turn, the
attributed estimate for what arrived between the turns (harness attachments
+ user text + tool results + previous assistant output, chars/4), and the
**residual** (exact − attributed). The residual settles attribution
questions like whether the Warp PostToolUse hook's transcribed
`hook_success` records actually enter model context.

- Snapshot mapping: pre-turn-1 disk estimate (already printed) = snapshot 1
  (a *prediction*, no API call exists yet); turn-1 exact = snapshot 2
  (post-first-message); last-turn exact = snapshot 3 (post-workload).
- Implementation: one jq pass emitting `turn-index record-type chars` per
  record, awk aggregation. No change to the default (flagless) output.
- Verify: run `--phases` on this session's transcript; turn totals must
  match the flagless report; per-turn residuals should be small relative
  to deltas.

## D2 — Layer 3: `scripts/context-experiment.sh` (headless driver)

Reproducible protocol runner, claude-only:

1. Baseline run: `claude -p "hi"` with a generated `--session-id` (verify
   flag against live `--help` first; fallback: newest-transcript diff).
2. Workload run: `claude -p "$(cat <workload-file>)"`, workload settable
   via `--workload <file>`; small built-in default otherwise.
3. Analyze both transcripts with `context-inspect.sh --phases`; print the
   three-snapshot comparison (baseline turn-1 vs workload run's growth).

Notes: headless runs bill real tokens — say so in the header. Verify with
one tiny live run.

## D3 — Rollover property inheritance ("auto mode on" for successors)

Gap: `launch-next-session.sh` already *replays*
`work/<proj>/.rollover-options`, but nothing *captures* the dying session's
properties — the skill says "create or update it only from knowledge",
which a session rarely has. The claude transcript records `permissionMode`
per line, so capture is mechanical:

- New `scripts/capture-rollover-options.sh <project> [transcript]`:
  resolves the session transcript (same convention as context-inspect.sh),
  takes the **last** recorded `permissionMode`, maps
  default→default, acceptEdits→edits, auto→auto, bypassPermissions→full,
  plan→default(+note), writes `ROLLOVER_OPT_APPROVAL` into
  `work/<project>/.rollover-options`, preserving existing
  `ROLLOVER_OPT_MODEL`/`ROLLOVER_OPT_EXTRA` lines. Non-claude runtimes /
  no transcript: exit 0 with a note, file untouched (fail-open, matches
  the skill's existing rule).
- Model is deliberately NOT auto-captured: the transcript's model id can't
  be distinguished from "the runtime default at the time", and pinning it
  would silently opt successors out of default-model upgrades. (Rejected
  alternative — record as Tier-2 decision note.)
- Wire into `skills/session-rollover/SKILL.md` step 6 (run the script,
  hand-edit only for model/extra) and `docs/context-budget.md` option-
  inheritance section.
- Run it now for `context-decay` → expect `ROLLOVER_OPT_APPROVAL=auto`
  (this session runs in auto mode); verify with
  `launch-next-session.sh context-decay --dry-run` showing
  `--permission-mode auto`.

## Cross-cutting

- Backlog: add + resolve cards for D1–D3 (built same-session).
- Docs: `docs/context-budget.md` Quickstart — agent gains `--phases` and
  the experiment driver; option-inheritance section gains the capture
  script.
- Ledger/launcher updates at session end; work in a worktree branch,
  committed + pushed.
