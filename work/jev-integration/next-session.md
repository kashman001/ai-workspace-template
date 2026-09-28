# Catchup prompt — jev-integration (paste into a new agent session)

We're resuming `jev-integration`. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Two requests to the user (node 15a, hitl — nothing else can move first)

Both are live paid Jev calls with the key in this machine's keychain (cents).
Say the word in a session where you are present and the agent runs them:

1. **"Run the second leg."** A keyed `rlm` `classify(...)` run with
   `threshold=0.0` on ~100 records of a *different kind* from run 1's commit
   subjects — issue titles under `work/*/issues/*.md` or ledger bullets from
   `work/*/handoff.md` — printing min / median / max confidence and the share
   below 0.25, 0.5, 0.9. Recipe: `/tmp/jev-uat/leg-keyed.py` with a new
   `content` and categories (regenerate `/tmp/jev-uat/` from the sixth note in
   `decisions.md` if `/tmp` was cleared).
2. **"Read the model listing."** One `GET https://api.typesafe.ai/v1/models`
   with the Bearer key to learn the versioned id behind `jev-latest` — the
   one-off `curl` is in the node file (key straight into the header, never
   printed or written; the response shape is not in the research).

Then `scripts/plan.sh done 15a-authorize-live-runs --by human --project
jev-integration`, and node 15 can be worked.

## Mission

Research is closed; the fit decision is approved (`decisions.md`, second
note): **integrate Jev at the `rlm` leaf-classification seam, gated on
access** — active only where `jev-api-key` is in the OS keychain; without one,
`rlm` behaves exactly as today. Requirements: `spec.md` (S1–S21) and the six
tickets under `issues/`. Plan `01-gated-integration`: waves 4–7, one node per
ticket, a reconcile last in each wave. Waves 4–6 are done (`scripts/jev.sh` +
`--help`, `scripts/tests/test-jev.sh` T1–T19 128/128, `classify()` in
`skills/rlm/scripts/rlm_repl.py`, credentials docs, `skills/jev/`, UAT passed
by the user). Left: wave 7 — the hitl gate above, then tune the threshold and
pin the model id, then the join. This item is also the `plans` item's dogfood:
findings go to `work/plans/decisions.md`.

## Position

<!-- plan:begin position -->
Position: plan 01-gated-integration, open, wave 7 of 7, done 15/18, doing 0, todo 3, blocked 0, dropped 0, sessions 7.
Frontier: 15a-authorize-live-runs. Remaining: 3 of 18 — wave 7: 15-tune-and-pin todo, 15a-authorize-live-runs todo, 16-reconcile-w7 todo.
<!-- plan:end position -->

## First actions

1. `scripts/context-budget.sh register --project jev-integration` (expect `seq=15`).
2. **Interactive session.** `frontier` is `15a-authorize-live-runs` (hitl). If
   the user is present: run the two requests above with them (each is one
   `rlm` session / one `curl`; record each result as a `plan.sh note` or a
   `decisions.md` line — the node's Acceptance says which), then
   `done 15a-authorize-live-runs --by human`. **Nobody there:** stop; there is
   no keyless work left (node 15's prep is logged on the node).
3. Node `15-tune-and-pin` (read the node first — its s14 Log line lists every
   edit site with line numbers). Inputs: run 1 = sixth note in `decisions.md`
   (min 0.23 / median 0.52 / max 1.0, 90 % below 0.9; candidates 0.5 and
   0.25); run 2 + the listed id = node 15a's records. Set
   `DEFAULT_JEV_THRESHOLD` and `DEFAULT_JEV_MODEL` in `rlm_repl.py`, replace
   the fixtures' placeholder id `jev-1.13.0` (T2b/T9e) and let T1g/T8h follow
   the new default, reword `skills/rlm/SKILL.md` (176–182: the 0.9 guidance
   is contradicted by the UAT; 292–293: pinned id, re-tune when re-pinning)
   and `skills/jev/SKILL.md` line 81. Tier-2 note with both distributions,
   the chosen threshold, observed fallback rate, and the rejected values.
   `llm_query` and the T14 golden untouched. Check = test-jev.sh.
4. `16-reconcile-w7` per `skills/plans/SKILL.md` → "Run a reconcile node";
   it closes the plan (goal-level: the user closes; propose, don't close).
5. After node 16: the user's deferred request — a critical assessment of the
   three videos' implementation ideas against context budget and usefulness;
   candidates under "Deferred" in `research/video-notes-2026-09-27.md`.
6. At WARN/STOP: ledger block (insert after the header's `-->`; blocks are
   `# Session Handoff — N`; keep two, archive the rest newest-on-top, no
   duplicate N; verify the header count after writing), `plan.sh sync`,
   commit with a `Decision:` trailer, then `session-rollover` (supervised
   chain → `--emit`). Do not push `main`.
7. `plan.sh` flags are separate words (`--project jev-integration`).
   `frontier` exits 1 while a reconcile node is `doing` — do not chain it
   with `&&`. `done` on a `todo` node needs `start` first (or `--force`);
   hitl nodes need `--by`. A node `check:` runs from the work item directory:
   every path needs `"$WORKSPACE_ROOT/"`. `plan.sh done` streams the check's
   output — pipe through `tail`. `plan.sh add <slug>` prefixes its own
   number; a node added to a wave that already has its reconcile is renamed
   to `<preceding-number><suffix>` (Replan rule 1), never left after the join.
   Run `sync` *after* `done`, not before — the Position block is a snapshot.
8. Keyless testing: `/tmp/nokey/security` must stay a **pass-through** stub
   that fails only the `jev-api-key` lookup — a blanket-failing stub logs the
   `claude` CLI out and the leaf returns "Not logged in". Leaf batches of 50
   via `claude -p haiku` take ~30 s; that is slow, not hung.

## Do NOT reload

- `research/` beyond claim ids by grep; `spike.md` only if a number is needed.
- `rulings.md`, `sweep.md`, `seam-inventory.md`, the corrections — settled.
- `spec.md` "User Stories" in full — grep an `S<n>` when a box cites one.
- `work/plans/` beyond `decisions.md` (append) and `issues/11-dogfood.md`.
- `handoff.md` — the top block only if something above is unclear.
- `scripts/tests/test-jev.sh` in full (390 lines) — grep a `T<n>` label.
- `uat-help-proposal.txt` — applied; `scripts/jev.sh --help` is the text now.

## Constraints already decided (do not re-litigate)

- **Never run `scripts/jev.sh` without `JEV_ENDPOINT` pointing at the stub
  unless it is `--check` or `--help`.** This machine's keychain holds a real
  key; a bare run is a live paid request. Node 15a's two calls are the user's
  to trigger (cents each) — that is what the hitl node is for.
- Template rules: agent-agnostic, CLI-first, credentials in the keychain,
  documented as a first-class addition, a test that proves it without a live
  key. `scripts/jev.sh` is the only code that knows the endpoint or the key;
  the model-listing `curl` is a one-off in the node file, not a script.
- CLI contract (fourth note in `decisions.md`): request JSON on stdin, passed
  through; one JSON line `{key,value,confidence}` per answer (Noul:
  confidence `null`); key reaches Python via the child env only; exit 0/2/3/4;
  `--check` and `--help` are the only flags. Help text: every line ≤ 80 cols,
  sections USAGE…SEE ALSO in order, examples byte-identical through `jq -c`.
- `llm_query` is byte-for-byte untouched (T14 golden diff — never regenerate
  the golden). `classify()` is done; node 15 changes only the threshold and
  model-id constants (`DEFAULT_JEV_THRESHOLD`, `DEFAULT_JEV_MODEL` /
  `RLM_JEV_MODEL`), the fixtures' id, and the two skills' wording.
- Vendored `skills/jev/typesafe-ai/` is pristine upstream (`65a39f3`,
  v0.5.7) below its provenance comment — never edit the body.
- Gated on access; `rlm` first; Q1 (c), Q2 narrow, Q5 (a) widened to (b) by
  the spec; `Promote?: maybe` on the fit note.
- Raw `pass/*.md`, `fact-check.md`, `record.md`, every brief, and
  `spike.{md,py}` are provenance — never edited. Do not re-run the spike.
  The key stays in the keychain: never print it, never write it to a file.
- No concrete model name in plan files (tiers only). Do not edit `plan.sh`,
  `session-loop.sh`, or the plans skill from this item.

## State snapshot

- Branch `main`, 71 ahead of origin, not pushed; session 14's work committed
  in one commit. Plan `01-gated-integration` open: wave 7 of 7, nodes 01–14
  and 13b `done`, 15a (hitl) / 15 / 16 `todo`; `check` silent.
- `decisions.md`: seven notes (R0.4 lift; fit decision, approved; typed
  helper; CLI stdin/JSON-lines shape; `classify` signature; UAT observation
  with the confidence distribution for node 15; hitl gate for node 15's calls).
- `spec.md` Status: draft (tickets `ready-for-agent`, 05 done by the user).
- REPL state `.claude/rlm_state/state.pkl` holds the 100-commit corpus
  (gitignored); `/tmp/jev-uat/`, `/tmp/nokey/` are machine-local.
- Chain: supervised; session 14 stopped blocked on the user (hitl), not at
  WARN; session 15 is **interactive**.
