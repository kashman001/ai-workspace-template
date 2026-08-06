# 02 — Permission-mode inheritance across rollovers (classifier "auto mode" gap)

Status: open · raised 2026-08-06 (session 14, post-rollover discussion with user)

## Incident

The first `ROLLOVER_RELAUNCH=auto` successor launched in **manual** permission
mode — `work/automatic-session-rollover/.rollover-options` did not exist
("launch flags unknown"), so `launch-next-session.sh` had nothing to replay
and runtime defaults applied. The lineage had never recorded its own launch
flags, so every auto-relaunched successor defaulted to manual.

Fix applied same day (machine-local, file is gitignored): the user supplied
the missing knowledge; `.rollover-options` now carries
`ROLLOVER_OPT_APPROVAL=full` (user chose full bypass after starting at
`auto`).

## The naming wrinkle (why this issue exists)

Claude Code's permission modes, as discussed with the user:

- **Manual (default)** — every sensitive action prompts.
- **UI "auto mode"** — a safety **classifier** vets each tool call: routine
  actions run unattended; risky ones are blocked/surfaced (observed live:
  the classifier denied a shell write whose effect was enabling a
  permission-bypass flag, while passing hundreds of routine commands).
- **acceptEdits** — auto-approves file edits only; Bash etc. still prompt.
- **Full bypass** (`--dangerously-skip-permissions`) — no prompts, no
  classifier.

The workspace's normalized `ROLLOVER_OPT_APPROVAL` levels map:
`default` → (nothing), `auto` → `--permission-mode acceptEdits`,
`full` → `--dangerously-skip-permissions`. **The script's `auto` is NOT the
UI's classifier-driven auto mode** — there is no level that inherits the
classifier mode, arguably the best default for autonomous rollover chains
(high autonomy + tripwire on dangerous actions).

## Proposed enhancement

Add a fourth normalized level (e.g. `ROLLOVER_OPT_APPROVAL=classifier`, or
re-point `auto` and rename the current one to `edits`) mapping for claude to
`--permission-mode auto`. Per ADR-0003's rule (a nonexistent flag already
slipped in once): **verify against live `--help` first** — confirm current
claude CLI accepts `--permission-mode auto`, and decide per-runtime fallbacks
for codex/gemini/opencode/copilot (they likely have no classifier
equivalent; nearest-level fallback + note, or refuse loudly?). Update the
OPT_ARGS mapping, tests (T14 family in
`scripts/tests/test-launch-next-session.sh`), `skills/session-rollover/
SKILL.md` step 6, and `docs/context-budget.md` "Relaunch knobs".

## Open questions for the user

- Which spelling: new `classifier` level, or make `auto` mean classifier mode
  and rename the acceptEdits level to `edits` (breaking existing files)?
- Should `full` remain the recorded choice for this work item, or switch to
  classifier mode once available?
