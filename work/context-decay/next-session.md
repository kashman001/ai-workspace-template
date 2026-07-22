# Next Session — context-decay

## Mission

The system is shipped and in live use; the 2026-07-22 follow-up session worked
through spec §12. Remaining work is small and mostly blocked on external state.

## Read these, in order

1. This file.
2. `ledger-analysis.md` — first ledger findings (session baseline ~50K, ~20–40K
   per work unit, 2–3 units per session).
3. `handoff.md` + `docs/context-budget.md` — only if you need build history or
   command/adapter details.

## Do NOT reload

- `context-decay-spec.md` — fully implemented, §12 follow-ups now also done or
  blocked (statuses below); re-reading tempts re-implementation.
- `design.html` — reference for humans; duplicated in docs/context-budget.md.
- The M9 / Gemini-telemetry diffs — done, committed (`2cc2828`, `b278c5f`).

## Follow-up statuses (was spec §12)

- **M9 fixed:** `register` trusted the stale session registry and bound the
  previous session's transcript (false WARN in a fresh session). Now `register`
  always re-discovers; `check`/`record`/`watch` still trust the registry.
- **Gemini telemetry: shipped, one verification pending.** Tracked
  `.gemini/settings.json` enables local-file telemetry; the adapter parses the
  last response's input tokens (both `input_token_count` and
  `gen_ai.usage.input_tokens`). Wiring proven live; parser fixture-verified.
  **Blocked:** confirming against a real successful Gemini response needs
  Gemini auth on this machine (interactive `gemini` login or `GEMINI_API_KEY`;
  ADC/Vertex 403'd on project quran-hifdh-tracker-497421 — don't enable cloud
  APIs for this). One `gemini -p "hi"` in this workspace after auth, then
  `scripts/context-budget.sh check --runtime gemini` should say `method=exact`.
- **Copilot CLI adapter: blocked** — Copilot CLI isn't installed on this
  machine (`~/.copilot` has only `ide/`). Verify if/when it appears.
- **Ledger analysis: first pass done** (`ledger-analysis.md`). Re-run after
  ~20 entries or the first `method=estimate` rows.

## State snapshot

- Branch `main`, clean; commits `2cc2828` (M9) and `b278c5f` (Gemini telemetry).
- Ledger: 6 entries, all claude/exact.
- `.gemini/telemetry.log` exists locally (gitignored) from the auth-failed
  verification run — harmless; delete freely.

## First actions

1. `scripts/context-budget.sh register`
2. If the user has set up Gemini auth: run the pending live verification above.
3. Otherwise: nothing open in this project — follow the Context Budget section
   in `CONTEXT.md` like any other session.
