<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 17 (2026-09-28): interactive — the approved Jev follow-on was grilled one question at a time (nine questions, plain-language framing at the user's request), `spec.md` amended with S22–S30 and **re-approved**, tickets 08–12 written, plan `02-follow-on` created (7 nodes, 2 waves), `check` silent, `sync` rendered; WARN at 128 K after the plan landed

## What happened

- Registered seq=17 (41 % at start — the system context alone is heavy).
- Grill (`grill-with-docs` → `grilling` + `domain-modeling`), one question
  per turn after the user asked for simple terms and options: **1a** keep 0.5
  by a pre-registered rule (`[0.5,1]` agreement ≥ 2× `[0.25,0.5)`, else move
  to the first boundary where it holds); **2a** two helpers `score()` and
  `check()` shaped like `classify()`; **3a** Noul fallback = probability
  within 0.25 of 0.5; **4a** research-wave: Jev is a *second reader* over
  the fact-check table, flags rows where ≥ 0.5 and disagrees, fact-checker
  and ruling unchanged; **5a** tier routing = evidence batch over both
  items' node files → `work/plans/issues/12-jev-tier-routing.md`, no edit to
  `plan.sh` (the "cheap-first + escalate" baseline was found not to exist);
  **6b** relevance filter = one experiment (docs/README.md rows × five task
  sentences, Noul per row), a note not a feature; **7a** one plan, agent runs
  the paid batches, cost in the node Log, no hitl gates; **8b**
  `scripts/jev-verdicts.sh` thin script + offline test; **9a** experiment
  truth = the tickets' "Read first" lists (weakness stated).
- `spec.md`: Status → in-review → **approved** again (re-approved by the
  user in chat, "approved"); S22–S30 appended under a "Follow-on" heading;
  Implementation and Testing each gained a follow-on bullet; Non-goals
  rewritten (research-wave and Score/Noul lifted; tier-routing *code* and a
  relevance *feature* stay out; "nothing in the ruling depends on Jev" added).
- Tickets `issues/08…12` in the item's format, each with a `Read first:`
  line (that line is S29's truth list). Plan: `plan.sh new follow-on`, seven
  `add`s (`--plan 02-follow-on` is required while plan 01 exists closed —
  without it `add` targets plan 01 and is refused), bodies filled from the
  tickets, `plan.md` Goal/Out of scope written, `check` silent, `sync` done.
  **Waves follow blockers, not the slice order agreed in Q7**: wave 1 =
  nodes 01–03 (independent), wave 2 = 05 and 06 (both need the confirmed
  threshold); two waves, not three — told to the user in the recap.
- Dogfood: `--project <item>` in a shell variable refused as predicted
  (constraint held); `add` without `--plan` picks the closed plan — noted for
  the `plans` item below.
- Budget: WARN (128 K) right after `sync`; wrap-up committed (05b8273), the
  user chose to roll over: launcher rewritten for wave 1 hands-off, staged
  with `--emit --loop-mode handsoff` (supervised chain).

# Session Handoff — 16 (2026-09-27): interactive, then unattended — the user took all three decisions (close the plan, approve the spec, ticket 07 with #1 + #2 + #4) and left; plan `01-gated-integration` **closed** (hand-edit + `sync`, Position re-rendered), spec `approved`, ticket 07 opened and resolved in-session: data-leaves-the-machine sentences in the `jev` skill and `docs/service-access.md`, Score-reliability clause, `JEV_DISABLED=1` off switch in `scripts/jev.sh` (+ help line, spec line, `rlm` knob) with T20 → test-jev.sh 140/140; ninth decision note; dogfood note on ticket 11 + s16 bullet; checkpointed — then the user returned: `main` pushed (75 commits), `/tmp` scratch deleted, index row fixed, and **all Jev follow-on slices approved with spend** → captured in the launcher, rolled over interactive at WARN for session 17 to plan

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
- `/tmp/jev-uat/`, `/tmp/nokey/` deleted at the user's request (2026-09-28).

## After the checkpoint (2026-09-28, same session)

- The user asked for a status recap, then `push main` (done: origin at
  c43a271), then deletion of the two `/tmp` scratch dirs (done), then a list
  of potential next items, then which video suggestions were integrated
  (#1, #2, #4 via ticket 07; #3 measured earlier; #5–#7 not taken).
- `work/README.md` index row for this item was stale ("running its plan")
  — fixed and committed (5139560).
- **The user approved every Jev follow-on item listed and authorized any
  spending** ("You have my approval if any spending is needed"). Scope and
  the how-to-plan are in the launcher's "First actions" (five slices: crisp-
  corpus confirmation batch, Score/Noul in `classify()`, research-wave seam,
  tier routing at dispatch, relevance filter). Committed (4aab5a0) before
  rolling over: the session was at WARN (132 K), and the user chose "roll
  over now" when asked.
- Supervised chain (dry-run refused `supervised_stage_only`): staged
  `--emit --loop-mode interactive`; the successor grills with the user.

