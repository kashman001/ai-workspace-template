# Catchup prompt — jev-integration (paste into a new agent session)

We're resuming `jev-integration`. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Research is closed; the fit decision is approved (`decisions.md`, second
note): **integrate Jev at the `rlm` leaf-classification seam, gated on
access** — active only where `jev-api-key` is in the OS keychain; without one,
`rlm` behaves exactly as today. Requirements: `spec.md` (S1–S21) and the six
tickets under `issues/`. Plan `01-gated-integration`: waves 4–7, one node per
ticket, a reconcile last in each wave. Waves 4–5 and every work node of wave 6
are done (`scripts/jev.sh` + `--help`, `scripts/tests/test-jev.sh` T1–T19
128/128, `classify()` in `skills/rlm/scripts/rlm_repl.py`, credentials docs,
`skills/jev/`, UAT passed by the user). Left: the wave 6 join, then wave 7
(tune the threshold, pin the model id). This item is also the `plans` item's
dogfood: findings go to `work/plans/decisions.md`.

## Position

<!-- plan:begin position -->
Position: plan 01-gated-integration, open, wave 6 of 7, done 14/17, doing 0, todo 3, blocked 0, dropped 0, sessions 6.
Frontier: 14-reconcile-w6. Remaining: 3 of 17 — wave 6: 14-reconcile-w6 todo.
<!-- plan:end position -->

## First actions

1. `scripts/context-budget.sh register --project jev-integration` (expect `seq=14`).
2. **Interactive session** (the user may or may not be present). Run
   `14-reconcile-w6` per `skills/plans/SKILL.md` → "Run a reconcile node":
   `start`, verify nodes 13 and 13b on disk (run `scripts/tests/test-jev.sh`
   → 128/128; `scripts/jev.sh --help | awk 'length > 80'` → nothing;
   `grep -c '^python ' skills/rlm/SKILL.md` → 0; node 13's evidence is the
   sixth note in `decisions.md`), record, replan within `replan: structural`
   if needed, `check` silent, `sync`, `done`. No human needed for this.
3. Wave 7, node `15-tune-and-pin` (read the node first). Inputs already on
   disk: `decisions.md` sixth note — on 100 commit subjects Jev's confidence
   was min 0.23 / median 0.52 / max 1.0, **90 % below the 0.9 default**;
   candidates to evaluate 0.5 and 0.25; label agreement Jev vs leaf is there
   too. The node's acceptance wants a *second* real run and the versioned id
   behind `jev-latest`. **Needs the user:** both are live paid calls with
   the key on this machine (cents). Corpus + recipe: `/tmp/jev-uat/
   commits.txt`, `/tmp/jev-uat/leg-keyed.py` (`threshold=0.0`, prints the
   distribution; regenerate the corpus with `git log --format=%s -n 100` if
   `/tmp` was cleared) — a second corpus should differ in kind (e.g. issue
   titles or ledger bullets). **Nobody there:** prepare everything that needs
   no key (how to read the model listing — check `research/` by grep for
   `models` before inventing; the threshold note draft with the rejected
   values; SKILL.md wording), commit, and stop with the two requests to the
   user written verbatim at the top of this block. Then `16-reconcile-w7`.
4. After node 16: the user's deferred request — a critical assessment of the
   three videos' implementation ideas against context budget and usefulness;
   candidates under "Deferred" in `research/video-notes-2026-09-27.md`.
5. At WARN/STOP: ledger block (insert after the header's `-->`; blocks are
   `# Session Handoff — N`; keep two, archive the rest newest-on-top, no
   duplicate N; verify the header count after writing), `plan.sh sync`,
   commit with a `Decision:` trailer, then `session-rollover` (supervised
   chain → `--emit`). Do not push `main`.
6. `plan.sh` flags are separate words (`--project jev-integration`).
   `frontier` exits 1 while a reconcile node is `doing` — do not chain it
   with `&&`. `done` on a `todo` node needs `start` first (or `--force`);
   hitl nodes need `--by`. A node `check:` runs from the work item directory:
   every path needs `"$WORKSPACE_ROOT/"`. `plan.sh done` streams the check's
   output — pipe through `tail`. `plan.sh add <slug>` prefixes its own
   number; a node added to a wave that already has its reconcile is renamed
   to `<preceding-number><suffix>` (Replan rule 1), never left after the join.
7. Keyless testing: `/tmp/nokey/security` must stay a **pass-through** stub
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
  key; a bare run is a live paid request. Node 15's real runs are the user's
  to trigger (cents each).
- Template rules: agent-agnostic, CLI-first, credentials in the keychain,
  documented as a first-class addition, a test that proves it without a live
  key. `scripts/jev.sh` is the only code that knows the endpoint or the key.
- CLI contract (fourth note in `decisions.md`): request JSON on stdin, passed
  through; one JSON line `{key,value,confidence}` per answer (Noul:
  confidence `null`); key reaches Python via the child env only; exit 0/2/3/4;
  `--check` and `--help` are the only flags. Help text: every line ≤ 80 cols,
  sections USAGE…SEE ALSO in order, examples byte-identical through `jq -c`.
- `llm_query` is byte-for-byte untouched (T14 golden diff — never regenerate
  the golden). `classify()` is done; node 15 changes only the threshold and
  model-id constants (`DEFAULT_JEV_THRESHOLD`, `DEFAULT_JEV_MODEL` /
  `RLM_JEV_MODEL`) and the two skills' wording.
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

- Branch `main`, not pushed; session 13's work committed at rollover (one
  commit). Plan `01-gated-integration` open: wave 6 of 7, nodes 01–13 and
  13b `done`, 14/15/16 `todo`; `check` silent.
- `decisions.md`: six notes (R0.4 lift; fit decision, approved; typed
  helper; CLI stdin/JSON-lines shape; `classify` signature; UAT observation
  with the confidence distribution for node 15).
- `spec.md` Status: draft (tickets `ready-for-agent`, 05 done by the user).
- REPL state `.claude/rlm_state/state.pkl` holds the 100-commit corpus
  (gitignored); `/tmp/jev-uat/`, `/tmp/nokey/` are machine-local.
- Chain: supervised; session 13 staged session 14 **interactive** at WARN.
