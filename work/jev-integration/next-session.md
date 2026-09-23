# Catchup prompt — jev-integration (paste into a new agent session)

We're resuming `jev-integration`. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## >>> START HERE <<<

Position: research wave 1 is in Phase 3/4. **Finished and closed:** the three
passes, the three fact-checks, and the corrections passes for `what-jev-is` and `integration-paths` (gen 1 DONE). **Still open:** `corr-terms` (gen 1 closed ROLLOVER_NEEDED, nothing applied — open gen 2), the second-round rulings R12–R15 (`what-jev-is`) and R10 (`integration-paths`).
Phase 4 (cross-subject sweep) and the synthesis are not started.

1. `scripts/context-budget.sh register --project jev-integration` (expect `seq=2`).
2. Read `research/rulings.md` in full (every ruling so far, and the wave
   patterns at the end of the `terms` section) and `research/schema.md`. Do
   NOT read `record.md`/`fact-check.md` files whole — grep them.
3. `scripts/fleet.sh dispatch-list --project jev-integration` — trust the
   records over this file for which tasks are open. Every generation should be closed (session 1 waited for all agents). If one is
   still `open`, its report file is partial: `dispatch-close --status KILLED`,
   then `dispatch-open` a fresh generation with the same `--brief`, and
   relaunch a `general-purpose` agent pointing at that brief (prompt shape:
   "read and follow your brief exactly: <path>", the dispatch contract
   `fleet.sh` prints, ≤12-line return, status word first).
4. Finish Phase 3: (a) `dispatch-open` gen 2 of `corr-terms` with `--brief work/jev-integration/research/terms/corrections-brief.md` and launch a corrections agent; its brief plus ruling R9 in `rulings.md` are the instructions, and gen 1's `terms/corrections.md` holds a ready evidence block and edit plan it must re-verify before applying. (b) Fold the second-round rulings (R12–R15 for `what-jev-is`, R10 for `integration-paths`) into one small corrections pass each, or into the Phase 4 sweep's corrections. (c) Read each `corrections.md`'s
   `## Not applied` and `## New findings needing a ruling` sections and rule
   on them in `rulings.md` (a second round is expected — rule yourself,
   never let an agent resolve at the wrong level).
5. Phase 4 — one sweep agent across all three subjects (it may read
   everything, writes only `research/sweep.md`): consistency of standard
   (same evidence pattern scored two ways; Noul/confidence claims across
   subjects), formatting integrity (every table renders — literal `|` in
   snippets), evidence-appendix spot-check (sample quotes vs. sources),
   stale summary counts (pre-correction figures marked historical). Feed it
   the wave patterns from `rulings.md`. Rule on its findings; a corrections
   pass per affected subject if needed.
6. Synthesis → `research/synthesis.md`: the corrected facts (cite claim
   ids), what changed vs. the README's standing claims S1–S6, and a first,
   explicitly **provisional** list of template seams a typed-decision model
   could serve (`rlm` leaf classification, `triage` categorisation,
   `doc-review` verdicts, session-loop stall/halt judgement, ledger/backlog
   checks) with what each needs from the API (closed option set + an `other`
   option, a confidence threshold policy, model-version pinning, cost per
   call at $42/Btok input). The fit **decision** is NOT this session's job.
7. Update `README.md` here (status: research complete) and the
   `work/README.md` row; ledger block `# Session Handoff — 2 (<date>): …`
   on `handoff.md`; rewrite this launcher for the fit-decision session
   (`grill-with-docs` → `decisions.md` note); commit (do not push; report
   how far ahead main is). Then roll over per
   `skills/session-rollover/SKILL.md` with `--loop-mode interactive` — the
   fit decision needs the human.
8. `scripts/context-budget.sh record --label "<phase done>"` at every phase boundary.

## Constraints already decided (do not re-litigate)

- Template rules apply to anything that ships: agent-agnostic, CLI-first or
  `mcp-fragments/`, credentials in the keychain, documented as a first-class
  template addition.
- Research before design: no integration code or spec until a fit decision
  is recorded in `decisions.md`.
- Wave scope is fixed at three subjects (ruling R0.1); off-limits: accounts,
  keys, API calls, spend (R0.4). Raw `pass/*.md`, `fact-check.md`, and the
  briefs are provenance — never edited.
- Corrections mark each changed claim `(corrected <date>; previously: "…")`.

## State snapshot

- Branch `main`; session 1's commit is the one after 43112fb. Files under
  `work/jev-integration/research/`: `schema.md`, `rulings.md`, and per
  subject `brief.md`, `fc-targets.md`, `fact-check-brief.md`,
  `corrections-brief.md`, `pass/`, `record.md`, `profile.md`,
  `verification.md`, `open-verification.md`, `fact-check.md`, and
  `corrections.md` where the corrections agent finished.
- `context-budget.env` here sets `ROLLOVER_RELAUNCH=auto`.

## Read these first, in order

1. `work/jev-integration/handoff.md` (top block — headline findings + patterns)
2. `work/jev-integration/research/rulings.md`
3. `skills/research-wave/SKILL.md` Phases 3–4 (when step 4 reaches it)
