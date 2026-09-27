<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

# Session Handoff — 11 (2026-09-27): wave 5 closed hands-off — node 11 (CLI widened to Choice/Score/Noul, S7 refusals, `--help` with a worked example per type; `skills/jev/SKILL.md`; TypeSafe's skill vendored at `65a39f3`; Service Access bullet) built test-first (T15–T19, 128/128), reconcile 12 joined; frontier 13-uat-gated (hitl); rolled over interactive at WARN

1. Registered `seq=11` (hands-off, 61K at register). Frontier `11-cli-skill-rule`; `start 11`. Read the node, ticket 04, S5/S7/S17/S18, `jev.sh`, `test-jev.sh`; fetched TypeSafe's `skills/typesafe-ai/SKILL.md` + `LICENSE` at `65a39f3` (`gh api` tree confirmed the path) and the Score/Noul/API doc pages for the exact criteria shapes (Score: ordered array of 2–10 levels; Noul: optional `{true,false}`; Choice ≤255 options).
2. Node 11, `tdd`. Red first: fixtures `scripts/tests/fixtures/jev/score.json` + `noul.json`; the stub gained a `status:<code>` fixture mode (non-200 + small error body); T15 Score, T16 Noul, T17 the two S7 refusals (256 options → exit 2; 255 allowed; 130k-char state → exit 2; no request), T18 exit 4 on 429/401 with status + body head, T19 `--help` content (three valid-JSON examples, exit codes, key order, limits). 15 failures. Green: `scripts/jev.sh` — typed value is `choice`/`score`/`noul` (Noul confidence `null`), the `{key,value,confidence}` line kept; limits checked before the request (chars/4 estimate, same as `classify`); `--help` rewritten. 128/128; T8–T14 untouched and green; `llm_query` golden diff clean.
3. `skills/jev/SKILL.md` (workspace-authored, runtime-neutral, model-invoked, no slash command): gate → request shape → type table → `other` pattern → run/exit codes → threshold + fallback; limits/cost/no-key sections; points to `typesafe-ai/SKILL.md` beside it. Vendored `skills/jev/typesafe-ai/SKILL.md` (pristine body byte-identical to upstream, provenance comment after the frontmatter) + `LICENSE` (MIT, TypeSafe AI). `skills/vendored-skills.md`: new "TypeSafe agent skill" section (pin, refresh procedure, license) and `jev` added to the workspace-authored list. `CONTEXT.md` → Service Access: one bullet, ~83 tokens (edited the real file; `CLAUDE.md` is the symlink).
4. `plan.sh done 11` failed and the node went `blocked`: its `check:` named `scripts/jev.sh` relatively, and `plan.sh` runs checks from the work item directory (`cd "$ITEM"`); `plan.sh check` had not flagged it. Fixed the node's check with `"$WORKSPACE_ROOT/"`, `start` (blocked → doing), `done` → done. Dogfood finding appended to `work/plans/decisions.md` (suggests a Check rule for relative paths, a doc line on the check cwd, and quieter `done` output — it streamed 128 test lines) plus a `plan.sh note`.
5. Reconcile 12: `verify` 09, 10, 11 → exit 0 each; files, box counts, docs entries confirmed on disk; no structural replan (wave 6 stands). `check` silent, `sync`, `done 12`. Plan: wave 6 of 7, 12/16 done, frontier `13-uat-gated` (hitl).
6. Budget: 114.8K after node 11, 123.7K (WARN) after the reconcile. Rolled over `--loop-mode interactive` so the successor poses the UAT to the user. Nothing pushed.

