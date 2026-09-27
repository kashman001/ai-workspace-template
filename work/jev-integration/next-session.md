# Catchup prompt — jev-integration (paste into a new agent session)

We're resuming `jev-integration`. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Research is closed (`research/synthesis.md`; live spike `research/spike.md`).
Direction (user, 2026-09-25) and fit decision (approved by the user in chat,
2026-09-27 — the second note in `decisions.md`): **integrate Jev at the `rlm`
leaf-classification seam, gated on access** — active only where
`jev-api-key` is in the OS keychain; without one, `rlm` behaves exactly as
today. The item runs as **plan `01-gated-integration`**: waves 1–2 are done;
wave 3 writes the spec and tickets (node 05) and its join (node 06) replans
the implementation waves in from those tickets (`replan: structural`). It is
also the `plans` item's dogfood: findings go to `work/plans/decisions.md`.

## Position

<!-- plan:begin position -->
Position: plan 01-gated-integration, open, wave 3 of 3, done 4/6, doing 0, todo 2, blocked 0, dropped 0, sessions 1.
Frontier: 05-spec-and-tickets. Remaining: 2 of 6 — wave 3: 05-spec-and-tickets todo, 06-reconcile-w3 todo.
<!-- plan:end position -->

## First actions

1. `scripts/context-budget.sh register --project jev-integration` (expect `seq=8`).
2. `scripts/plan.sh frontier --project jev-integration` → `05-spec-and-tickets`.
   `start` it, read its node file, write `spec.md` (`to-spec` conventions,
   `docs/agents/issue-tracker.md`) and the tickets under `issues/`
   (`to-tickets`: tracer-bullet, blocking edges), from the fit note plus the
   design input below. Tick verified boxes, `done`.
3. Then `06-reconcile-w3` in this session: verify, record, **structural
   replan** — `add` the implementation waves from the tickets (`skills/plans/
   SKILL.md` → "Create a plan" steps 2–4), one `## Replans` line, `check`
   silent, `sync`, `done`. Then work the new frontier while budget allows.
4. Overruns: `block`/split (Replan rule 1); record which as a finding.
5. At WARN/STOP: ledger block (insert after the header's `-->`; verify block
   headers unique, keep two blocks, archive the rest newest-on-top),
   `plan.sh sync`, commit with a `Decision:` trailer, then
   `session-rollover` (supervised chain → `--emit`). Do not push `main`.
6. `plan.sh` flags are separate words (`--project jev-integration`); a
   variable holding both is rejected.

## Design input for node 05 (from the session-7 conversation with the user)

Slice 1 — this plan's implementation, all agent-agnostic (every runtime,
CLI-first, zero standing context):

- A `scripts/jev.sh` (or small Python) CLI: reads the key from the keychain
  (`security find-generic-password -s jev-api-key -w` on macOS; documented
  equivalent elsewhere), POSTs `/v1/systemone` with `state` + questions,
  prints typed answers + confidence, exits with a reason code when no key —
  never an error, never prints the key. `--help` teaches the three question
  types with one example, so no skill needs loading to use it.
- `skills/rlm/scripts/rlm_repl.py`: the leaf swap at `llm_query` — with a key,
  one request per 50-record batch (`state` = records, one Choice per record,
  the root's categories + explicit `other`), confidence threshold with
  per-record fallback to the current `claude -p` leaf; without a key, the
  current path byte-for-byte. `skills/rlm/SKILL.md`: `other` + threshold
  guidance. Alias `jev-latest`; pin the versioned id once thresholds are tuned.
- A test proving both paths with no live key (no key → identical output; key
  present → request shape against a stub endpoint).
- Docs: `docs/service-access.md` (Jev entry), `docs/runbooks/authentication.md`
  (adding the key), `scripts/check-service-access.sh` (present/absent only).
- One always-on rule in `CONTEXT.md` (< 100 tokens): closed options, many
  items, safe fallback, correctness confirmed elsewhere → use the CLI; never
  for prose/extraction; no key → current way.
- `skills/jev/SKILL.md`, demand-loaded (request shape, `other`, thresholds,
  255-option / 32k-state limits); vendor TypeSafe's SKILL.md beside it with
  provenance — re-check `typesafe-ai/skills` for anything newer than
  2026-09-23 (research integration-paths 1.7, 3.7).
- Cost/limits to cite: $42/Btok input, output free (terms 1.1); 250k tok/s,
  1,200 req/min, 429 beyond (2.1); no SLA (7.3).

Later plans (name them in the spec's "Out of scope", do not ticket them):
tier routing at subagent dispatch (resolves `tier: auto` in `plan.sh` — the
plans item owns that file; baseline to beat: cheap-first, escalate on failed
check); a relevance filter before loading files/tickets; the other seams.

## Do NOT reload

- `research/` beyond claim ids by grep and `spike.md` if a number is needed.
- `rulings.md`, `sweep.md`, `seam-inventory.md`, the corrections — settled.
- `work/plans/` beyond `decisions.md` (append) and `issues/11-dogfood.md`.
- `handoff.md` — the top block only if something above is unclear.

## Constraints already decided (do not re-litigate)

- Template rules: agent-agnostic, CLI-first or `mcp-fragments/`, credentials
  in the keychain, documented as a first-class addition, a test that proves
  it without a live key.
- Gated on access; `rlm` first; Q1 (c), Q2 narrow, Q5 (a); `Promote?: maybe`
  (the session's choice — the user may change it).
- Raw `pass/*.md`, `fact-check.md`, `record.md`, every brief, and
  `spike.{md,py}` are provenance — never edited. Do not re-run the spike.
  The key stays in the keychain: never print it, never write it to a file.
- No concrete model name in plan files (tiers only). Do not edit `plan.sh`,
  `session-loop.sh`, or the plans skill from this item.

## State snapshot

- Branch `main`, not pushed. Plan `01-gated-integration` open: wave 3 of 3,
  nodes 01–04 `done`, frontier `05-spec-and-tickets`.
- `decisions.md`: two notes (R0.4 lift; fit decision, approved, Promote maybe).
- Chain: supervised, reopened 2026-09-27 bound to the plan; session 7 staged
  session 8 hands-off at WARN.
