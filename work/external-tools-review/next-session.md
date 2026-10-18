# Catchup prompt — External Tools Review (paste into a new agent session)

We're resuming external-tools-review. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Close success criterion 4: the user dispositions recommendations R1–R16 in
`synthesis.md`; accepted ones become backlog cards (or one small work item
for R2–R4), rejected ones become notes in `decisions.md`. Then close the item.

## Read these, in order

1. `work/external-tools-review/summary.md` (one page — what the user reads)
2. `work/external-tools-review/synthesis.md` (R-numbers, costs, file targets)
3. `work/external-tools-review/handoff.md` (top block only)

The four `research/t*.md` notes only on demand, for a specific R.

## Do NOT reload

- The four tracks — done and spot-checked at source in s2; don't re-research.
- Vendoring REA / CLI-Anything, building on Projects, adding Phonon-2 — all
  rejected in synthesis ("Explicitly not recommended") with reasons.
- R6 is already filed as backlog card **L93**; its disposition is just
  "reword vs CLI mode", recorded on that card.

## State snapshot

- Branch `main`; s2 work committed (not pushed — push is the user's call).
- No running processes. No plan.

## First actions

1. `scripts/context-budget.sh register --project external-tools-review`
2. **Needs the user.** Open the HTML twin for them if helpful
   (`work/external-tools-review/summary.html`) and pose, verbatim:
   > "Here are the 16 recommendations from the external tools review
   > (summary.md). For each of R1–R16, yes / no / later? R2–R4 would go
   > together as one small work item; the rest become backlog cards. For R6
   > (card L93): reword the doc, or add a CLI mode to the transcript script?"
   Grill one question at a time if they prefer, theme by theme (A–D).
3. **No human present:** do nothing further — the item is blocked on the user;
   stop with the question open.
4. On answers: file accepted ones as Open cards in
   `docs/template-workspace-backlog.html` (next free L-ID after L93; bump the
   Open scorecard), or scaffold one work item for R2–R4 with
   `/create-work-item`; write each rejection to `decisions.md`; R1 = a
   cross-link note into `work/concurrent-sessions/`. Then `checkpoint`.
