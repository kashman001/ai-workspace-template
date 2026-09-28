<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

# Session Handoff — 14 (2026-09-27): wave 6 joined (reconcile 14; 13b re-verified 128/128) → hitl gate 15a added ahead of 15 → the user authorized both live calls in-session → run 2 (100 ledger bullets: median 0.26, 94 % below 0.5; leaf agreement tracks confidence, 22/100 overall) + model listing (no versioned id: `jev-latest`/`jev-preview` with release dates) → node 15 done: threshold 0.9 → 0.5, pin = `jev-latest` @ 2026-09-10, skills reworded, fixture r3 0.41, 128/128; frontier 16-reconcile-w7; rolled over at WARN

## What happened

- Reconcile 14 per the plans skill: `start`; 13b verified on disk (test-jev.sh
  128/128, `--help` 0 lines > 80 cols with the ten sections in order, no
  `python ` invocation in skills/rlm/SKILL.md, `verify 13b-uat-fixes` passes);
  13 is hitl, done by the user, its third box satisfied by the sixth note in
  `decisions.md`. No claim failed. Boxes ticked, Log line, `check` silent,
  `sync`, `done` → 15/18.
- Replan (structural, at the join): node 15 was a `work` node whose acceptance
  needs a second real `rlm` run and one `GET /v1/models` — cents each, the
  user's to trigger. A hands-off chain would have dispatched it. `add
  authorize-live-runs --wave 7 --kind hitl` numbered it 17 (after the join,
  `reconcile-last`) → renamed `15a-authorize-live-runs` (Replan rule 1); 15
  is now `blocked_by: [13-uat-gated, 15a-authorize-live-runs]`. Its Goal
  carries the two requests verbatim, including the one-off `curl` for the
  model listing (key straight into the header, never printed). `## Replans`
  line in plan.md.
- Node 15 prep (no key needed) logged on the node: every edit site with line
  numbers (rlm_repl.py constants + comments, rlm SKILL.md 176–182 and
  292–293, jev SKILL.md 81), the fixtures' placeholder id `jev-1.13.0` and
  T2b/T9e/T1g/T8h that follow the pin, candidates 0.5 and 0.25 from run 1.
  No code touched.
- The user then authorized both calls ("You have permission for both"); the
  standing rule that live `jev.sh` calls are the user's to trigger was the
  reason for the wait (not the permission classifier). Listing: `GET
  /v1/models` → `jev-latest` (release 2026-09-10T18:38Z) and `jev-preview`
  only, no versioned ids. Run 2: 100 ledger bullets (`/tmp/jev-uat/
  ledger.txt`, `leg2-keyed.py`), 100/100 jev under a second, min 0.09 /
  median 0.26 / max 0.94, below 0.25/0.5/0.7/0.9 = 41/94/98/99 %. Leaf leg
  (`leg2-leaf.py`, keyless stub, 31 s): agreement by Jev confidence [0,0.25)
  5/41 · [0.25,0.5) 14/53 · [0.5,1] 3/6. Full numbers on node 15a's Log.
- Node 15 done: `DEFAULT_JEV_THRESHOLD` 0.5, `DEFAULT_JEV_MODEL` stays
  `jev-latest` with the release date in the comment; rlm SKILL threshold
  paragraph + knobs, jev SKILL step 6 + Model bullet; fixture r3 0.89 → 0.41
  so T8i still hits the fallback at the new default (T1i/T9a/T9c follow).
  128/128; T14 golden untouched. Eighth decision note (rejected 0.9 / 0.25 /
  0.7, synthetic id). REPL state now holds the ledger corpus.
- Origin: `git fetch --dry-run` silent — nothing landed upstream; main is 71
  ahead, not pushed.

## Decisions

- `decisions.md` seventh note: hitl gate for node 15's paid calls; rejected
  launcher-only requests (invisible to `frontier`/`session-loop.sh`) and
  leaving 15 `doing` across sessions. Promote?: no.
- `work/plans/decisions.md` (dogfood): ticket 06 said "requires a key … after
  UAT" yet became a plain `work` node at plan creation; suggest "Create a plan
  from tickets" puts a hitl node in front of any ticket that names the user, a
  key, spend, or a machine. Promote?: no.

## Open

- 16-reconcile-w7: verify node 15 on disk, record, propose closing the plan
  (goal-level — the user closes). Then the deferred video assessment.
- Deferred: the critical assessment of the three videos' ideas
  (`research/video-notes-2026-09-27.md` → "Deferred") after node 16.
