<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

# Session Handoff — 12 (2026-09-27): interactive UAT session — user ran the three keyed commands and the keyless `--check`/preflight (both PASS); findings: `jev.sh --help` not user-friendly (CLI text-UX review done, replacement text at `uat-help-proposal.txt`), `skills/rlm/SKILL.md` says `python` (Mac has only `python3`); fix node 17-13b-uat-fixes added (lint: reconcile 14 no longer last in wave 6 — unresolved); `rlm` keyed/keyless legs NOT yet run; three Jev videos read, notes + deferred assessment in `research/video-notes-2026-09-27.md`; rolled over at STOP

## What happened

- Frontier was 13-uat-gated (hitl). Posed the UAT. User ran `--check`
  (key present), `--help`, `check-service-access.sh` on the keyed machine;
  then with a fake `security` on PATH: `--check` exit 3 + one stderr line,
  preflight `– jev key absent (optional)`. Both keyless checks PASS.
- Finding 1: `--help` judged not user-friendly. A text-UX subagent ranked
  ten issues (unreadable one-line JSON examples, no synopsis, exit codes
  buried, flags after examples, "key" overloaded) and wrote a 100-line
  replacement (all ≤ 80 cols, examples byte-identical via `jq -c`), saved at
  `work/jev-integration/uat-help-proposal.txt`.
- Finding 2: `skills/rlm/SKILL.md` uses `python` five times; this Mac has
  only `python3` (script shebang is python3). Pre-existing rlm-skill bug,
  inherited by the classify recipe.
- The `rlm` legs never ran: first because of `python`, then because the
  user pasted the `<file>` placeholder literally (`zsh: parse error`).
- `plan.sh add 17-13b-uat-fixes --wave 6 --blocked-by 13-uat-gated` with
  goal/acceptance/check written; `plan.sh check` now fails: "reconcile node
  is not last in wave 6 (17-13b-uat-fixes follow)". Not resolved (STOP).
  Two `plan.sh note` entries record the UAT results.
- User request mid-session: three YouTube tutorials on Jev + Claude Code
  read in full (transcripts via Chrome; yt-dlp rate-limited). Notes and a
  list of deferred implementation candidates in
  `research/video-notes-2026-09-27.md`. User: finish the plan first, then
  assess the videos critically (context-budget cost vs usefulness).

## Decisions

- UAT findings become a wave-6 work node rather than dropping 13 (launcher
  rule); the help rewrite follows the reviewer's text, facts unchanged.
- Video input is deferred until the plan closes (user's call).

## Open

- Node 17 ordering vs reconcile 14 (see node's "Ordering note").
- `rlm` keyed + keyless legs of the UAT; the leaf share for node 15.
- Node 13 stays `todo` until the user marks it.
