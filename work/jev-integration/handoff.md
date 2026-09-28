<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 14 (2026-09-27): wave 6 joined — reconcile 14 done (13b's four boxes re-verified: 128/128, `--help` clean, rlm skill `python3`; 13's evidence = sixth note); structural replan: hitl gate `15a-authorize-live-runs` added ahead of `15-tune-and-pin` (its acceptance needs two paid live Jev calls only the user may trigger); node 15's keyless prep logged (edit sites, fixture placeholder id `jev-1.13.0`, candidates 0.5 / 0.25); frontier 15a (hitl); stopped blocked on the user, well under WARN

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

- **Node 15a (hitl) — the user's two requests**, verbatim in
  `plans/01-gated-integration/nodes/15a-authorize-live-runs.md` and at the top
  of `next-session.md`: (1) a second keyed `rlm` run at `threshold=0.0` on a
  corpus of a different kind (issue titles or ledger bullets, ~100 records);
  (2) one `GET https://api.typesafe.ai/v1/models` to read the versioned id
  behind `jev-latest`. Then `done 15a-authorize-live-runs --by human`.
- Node 15 then sets `DEFAULT_JEV_THRESHOLD` / `DEFAULT_JEV_MODEL`, the
  fixtures, and the two skills' wording; Tier-2 note with both distributions
  and the rejected values; 16-reconcile-w7 closes the plan.
- Deferred: the critical assessment of the three videos' ideas
  (`research/video-notes-2026-09-27.md` → "Deferred") after node 16.

# Session Handoff — 13 (2026-09-27): interactive UAT close — plan lint fixed (17-13b → 13b-uat-fixes, replan rule 1); UAT node 13 done by the user: keyed `rlm` run 100/100 `source: jev`, keyless 100/100 `leaf` (34 s, nothing mentions Jev); finding for node 15: median confidence 0.52, **90 % would fall to the leaf at the 0.9 default**; node 13b done (`--help` rewritten to the reviewer's text, T19b reworked, rlm skill `python3`; 128/128); frontier 14-reconcile-w6; rolled over interactive at WARN

## What happened

- Lint: `17-13b-uat-fixes` renamed to `13b-uat-fixes` (file + `id:`) and added
  to 14's `blocked_by` — plans skill Replan rule 1 / `docs/plans.md`
  ("number of the node it follows plus a suffix"). `## Replans` line + note.
- UAT (node 13, user): corpus = last 100 commit subjects (`/tmp/jev-uat/
  commits.txt`), recipes `/tmp/jev-uat/leg.py` (default threshold) and
  `leg-keyed.py` (`threshold=0.0`, prints the confidence distribution).
  User's first keyed run at the default reached the leaf fallback and was
  interrupted as "stuck" — the leaf batch of 50 via `claude -p haiku` takes
  ~30 s, so it was slow, not hung. Keyed run with `threshold=0.0`: 100/100
  jev, confidence min 0.23 / median 0.52 / max 1.0, 90/100 below 0.9.
  Keyless run (session, pass-through stub): 100/100 leaf, 34 s, no Jev
  mention. Marked `done --by human`. Full numbers + label agreement: the
  sixth note in `decisions.md`.
- Recipe finding: a fake `security` that fails every call also logs the
  `claude` CLI out (its OAuth token is in the keychain) → leaf answers "Not
  logged in", every label `None` in ~1 s. `/tmp/nokey/security` is now a
  pass-through that fails only the `jev-api-key` lookup. `plan.sh note` + decisions.md.
- Node 13b: `scripts/jev.sh --help` = `uat-help-proposal.txt` with one
  factual tweak (KEY sentence); heredoc delimiter renamed `USAGE` →
  `JEV_HELP` (the new text has a `USAGE` header at column 0, which
  terminated the heredoc — 79 tests failed until renamed). T19b now
  extracts the three multi-line `printf … | scripts/jev.sh` blocks and
  asserts `3 ok` (stricter). `skills/rlm/SKILL.md`: six `python ` → `python3`
  (the sixth is the audit-replay line). 128/128; node check passes.

## Decisions

- Node 13 marked done by the user on the pasted outputs (both legs seen).
- UAT observation recorded as a Tier-2 note for node 15 (threshold is the
  main routing knob, not a safety net; candidates 0.5 and 0.25).

## Open

- 14-reconcile-w6 (frontier), then wave 7: node 15 needs the user's key
  for a second real run and a threshold call; node 16.
- After the plan closes: the deferred video assessment
  (`research/video-notes-2026-09-27.md` → "Deferred").

Learnings:
- A quoted heredoc dies on any content line equal to its delimiter — pick a delimiter that cannot be a section header (second strike → `docs/operational-knowledge.md`).
- A keychain stub for "no key" tests must pass through everything but the one entry; blanket failure disables the `claude` CLI too.
- macOS has no `timeout`; use a Python `subprocess.run(timeout=)` wrapper to cap a probe.

Suggested skills: `plans` (reconcile 14, then node 15), `decision-log` (threshold + pin note), `session-rollover`.

Key files: `work/jev-integration/decisions.md` (sixth note), `plans/01-gated-integration/nodes/{13b-uat-fixes,14-reconcile-w6,15-tune-and-pin}.md`, `scripts/jev.sh` (help heredoc 22–124), `scripts/tests/test-jev.sh` (T19b), `skills/rlm/SKILL.md`, `/tmp/jev-uat/{commits.txt,leg.py,leg-keyed.py}`, `/tmp/nokey/security`.
