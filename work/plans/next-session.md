# Catchup prompt — plans (paste into a new agent session)

We're resuming `plans`. Works in any runtime (Claude Code, Codex, Gemini,
OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover: what to do next, still-binding constraints, pointers — never
> session history. Past-tense provenance lives in `handoff.md` (the ledger).
> Convention: docs/work-directory-conventions.md.

## Mission

Tickets 01–10 are `done`: the plans feature is built, documented, and tested.
What remains is ticket **11** (`issues/11-dogfood.md` or `issues/11-*.md`):
run the *next real multi-session work item* as the first plan — open a plan
in that item, drive it with `session-loop.sh --plan` through at least two
waves including one `hitl` and one reconcile node, and record what broke,
what was slow, and whether L48 (wayfinder as a plan template) should be taken
up, in that item's ledger and in `work/plans/decisions.md`. Which item is the
user's call — pose the question below before doing anything else in 11.

## Open question (pose verbatim, then wait)

> Ticket 11 (dogfood) needs a real multi-session work item to run as the
> first plan. Which one? (a) `work/jev-integration` — currently at a research
> spike (`research/spike.{md,py}`, untracked); (b) another item you name;
> (c) defer 11 and close out the plans item now (README status line,
> decisions, ledger), leaving 11 `ready-for-agent` for whichever multi-session
> item comes next.

Before posing it: `git fetch origin` and `git log --oneline main..origin/main`
— if origin landed changes, integrate them first (a blocked-on-user rollover
is the moment to refresh).

## Read these, in order (keep it lean)

1. `issues/11-*.md` (short). Nothing from `spec.md` unless the chosen item's
   plan raises a spec question (S1–S36 are the verification list).
2. `skills/plans/SKILL.md` → "Create a plan" only when the answer is (a) or
   (b); `docs/plans.md` → "Per runtime" and "Worked example" if the verbs are
   unfamiliar.
3. For (c): `README.md` of this item (status line at the top), `decisions.md`
   tail (append the close-out note), `work/README.md` row.

## Do NOT reload

- `concept.md`, `seams.md`, the grill, `spec.md`, tickets 01–10.
- `plan.sh`, `session-loop.sh`, `plan-tiers.env`, the skills, `docs/plans.md`
  body — built and green; 11 changes none of them unless dogfood finds a bug
  (then: a note in `decisions.md` first, fix second, suite third).
- `handoff.md` — the top block only if something above is unclear.

## Still binding

- No concrete model name anywhere. Nothing pushed to origin — report how far
  ahead main is.
- `test-plan.sh` (238), `test-session-loop.sh` (140),
  `test-doc-consistency.sh` (17), `test-template-version.sh` (9) stay green
  (run with `bash …`).
- Plan vocabulary says "work item", never "worktree".
- `plan.sh` verbs need `--project <item>` when this session is bound to
  `plans` but works another item's plan.

## State snapshot

Branch `main`, clean after this rollover's commit; nothing pushed (55
ahead). Tickets: 01–10 `done`; 11 `ready-for-agent`. Chain supervised by
`session-loop.sh` (seq 14 → 15; cap 15 — this is the last session the cap
allows; a person restarts the chain if 11 runs). Budget at rollover: ~118K.
`TEMPLATE_VERSION` = 2026-09-24. Untracked `work/jev-integration/research/
spike.{md,py}` are another item's — leave them. No plan is open in this item.

## First actions

1. `scripts/context-budget.sh register --project plans` (expect `seq=15`).
2. `git fetch origin`; integrate anything landed (see above).
3. Pose the open question verbatim; wait for the answer.
4. (a)/(b): follow `skills/plans/SKILL.md` → "Create a plan" in the chosen
   item (`plan.sh new` there, `--project <item>` on every verb), then hand the
   chain to that item's supervisor; record findings back here as they appear.
   (c): close out — README status line, `decisions.md` note, `work/README.md`
   row, ledger block; `checkpoint`, not rollover.
5. At WARN/STOP or the end: ledger block, rewrite this launcher, update the
   `work/README.md` row, commit. Do not push main.
