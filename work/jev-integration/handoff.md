<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 16 (2026-09-27): interactive, then unattended — the user took all three decisions (close the plan, approve the spec, ticket 07 with #1 + #2 + #4) and left; plan `01-gated-integration` **closed** (hand-edit + `sync`, Position re-rendered), spec `approved`, ticket 07 opened and resolved in-session: data-leaves-the-machine sentences in the `jev` skill and `docs/service-access.md`, Score-reliability clause, `JEV_DISABLED=1` off switch in `scripts/jev.sh` (+ help line, spec line, `rlm` knob) with T20 → test-jev.sh 140/140; ninth decision note; dogfood note on ticket 11 + s16 bullet; item **finished** — checkpoint, no successor

## What happened

- Registered seq=16 (40 %). Posed the three launcher decisions in one
  message; the user answered all three "yes" (recommended options) and
  then said to continue unattended.
- Close: `status: open` → `closed` in `plans/01-gated-integration/plan.md`,
  `plan.sh sync` (rendered `closed` in the launcher's Position block),
  `status` prints `closed 18/18`, `check` silent. Ticket 11 of the `plans`
  item got a Comments entry: closed by a person, box 1 (chain verdict
  `plan_closed`) stays unticked; `work/plans/decisions.md` an s16 bullet.
- Spec: line 10 `Status: approved`, `Approved-by: Kashif Siddiqui
  (2026-09-27, session 16)`.
- Ticket 07 (`issues/07-data-leaves-machine-score-caveat-off-switch.md`),
  no plan, test-first: T20 appended (12 assertions: request and `--check`
  exit 3, empty stdout, one stderr line naming the switch, nothing sent,
  fake keychain provably not read, switch beats `JEV_API_KEY`,
  `JEV_DISABLED=0` not disabled, `--help` unaffected and documents it) →
  10 red → `scripts/jev.sh` gained the check before key resolution
  (`${JEV_DISABLED:-0}` != 0 → the no-key line, exit 3) plus an ENVIRONMENT
  help line (≤ 80 cols; the >80 lines in the file are code, as before) →
  140/140. Docs: `skills/jev/SKILL.md` step 2 (state leaves the machine,
  SOC 2 claim unverified, no personal/confidential records, `JEV_DISABLED=1`
  to keep a corpus local) and step 3 (Score least reliable in the one
  report; prefer a Choice or one Noul per level); `docs/service-access.md`
  Jev Notes (two sentences); `spec.md` key-resolution item (one clause);
  `skills/rlm/SKILL.md` knobs (one clause). Ticket boxes ticked, `resolved`.
- `decisions.md` ninth note: `JEV_DISABLED=1` is the off switch, default
  stays gate-on-key; rejected default-off, an `--offline` flag, and
  any-non-empty-value semantics. Promote?: no.
- Budget after the ticket: 100 K (67 %), OK — checkpoint, not rollover.

## Decisions

- Ninth Tier-2 note (above). Commit trailer: the plan close and the switch.

## State at close

- Plan closed 18/18, sessions 8. Tickets 01–07 `resolved`. Spec `approved`.
- No open work in this item. Later slices (tier routing, other seams) stay
  where `spec.md` and the assessment left them: not scheduled.
- `/tmp/jev-uat/`, `/tmp/nokey/` still machine-local; safe to delete.

# Session Handoff — 15 (2026-09-27): interactive — wave 7 joined: reconcile 16 done (node 15 re-verified on disk: 128/128, `DEFAULT_JEV_THRESHOLD` 0.5, pin `jev-latest` @ 2026-09-10 in both skills, `git diff HEAD~1` = the eighth note's blast radius); plan `01-gated-integration` 18/18 done, frontier none, left **open** — closing is goal-level, proposed to the user; tickets 01–06 `resolved`; three dogfood findings to `work/plans/decisions.md`; the deferred video assessment written (two doc lines worth doing, one knob for the user, rest no); rolled over interactive at WARN

## What happened

- Registered seq=15. Started `16-reconcile-w7`; verified node 15's four
  boxes on disk (tests 128/128; constants at `rlm_repl.py:99-100`; no `0.9`
  left in either skill; both skills name release 2026-09-10 and "re-tune when
  it changes"; fixture r3 0.41; T8i/T9a/T9c reworded). Diff since HEAD~1
  touched only the eighth note's blast radius plus plan bookkeeping. Box 1
  held by evidence, not as written (no versioned id exists) — noted, no
  follow-up; the fixtures' `jev-1.13.0` stays a stub-only override value.
- Recorded two `plan.sh note` lines; ticked node 16; `check` silent; `done`;
  `sync`. Status: 18/18 done, sessions 8, frontier none, plan still `open`.
- Housekeeping: tickets 01–06 `Status: resolved — node <id> done` (the
  tracker has no `done`; `resolved` is its only terminal state; none had been
  flipped when its node closed). Spec left `draft` — approval is the user's.
  `work/plans/issues/11-dogfood-first-real-plan.md` got a Comments entry;
  `work/plans/decisions.md` an s15 bullet: sync-after-done, tickets never
  flipped by plan-from-tickets, no `plan.sh` verb closes a plan (hand-edit
  `status: closed`, must be the last write).
- Wrote `research/video-assessment-2026-09-27.md` (one page + glossary):
  **do** a data-leaves-the-machine sentence in `skills/jev/SKILL.md` and
  `docs/service-access.md`, and a Score-reliability clause; **user decides**
  a `JEV_DISABLED=1` env knob (spec amendment); agreement measurement is
  already done (node 15a, 22/100 on overlapping categories, tracks
  confidence); tier routing, hooks, OpenRouter: no. Zero always-on context.
- Slip: held `--project jev-integration` in a shell variable → every verb
  refused ("unknown option"); nothing was written by those calls; redone
  with literal flags. Same trap as the s8 dogfood finding (b).

## Decisions

- No new Tier-2 note. Plan notes: box 1 by evidence; the close proposal.
  Ticket state `resolved` chosen over inventing `done` (commit trailer).

## Open for the user (session 16 launcher leads with these)

- Close the plan: `status: closed` in `plans/01-gated-integration/plan.md`.
- Spec Status `draft` → `approved` + `Approved-by`, if the user agrees.
- Ticket 07 from the assessment (#1, #2, optionally #4): yes or no.
