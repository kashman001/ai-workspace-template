# Catchup prompt — Backlog sweep (paste into a new agent session)

> **This file is the LAUNCHER.** Forward-only, REPLACED at each rollover.
> Provenance lives in `handoff.md`. Convention: docs/work-directory-conventions.md.

## Mission

Close plan `01-open-cards` (`work/backlog-sweep/plans/01-open-cards/`): nodes 12 then 13.

## Position

<!-- plan:begin position -->
Position: plan 01-open-cards, open, wave 5 of 5, done 11/13, doing 0, todo 2, blocked 0, dropped 0, sessions 2.
Frontier: 12-l86-probe-writeup. Remaining: 2 of 13 — wave 5: 12-l86-probe-writeup todo, 13-reconcile-w5 todo.
<!-- plan:end position -->

## Read these, in order

1. `work/backlog-sweep/handoff.md` — top block only
2. `work/backlog-sweep/plans/01-open-cards/nodes/10-l86-user-probes.md` — Log (the probe evidence)
3. `nodes/12-l86-probe-writeup.md`, `nodes/13-reconcile-w5.md`
4. One existing probe note for the Q1–Q4 format: `work/runtime-session-identity/probes/codex-vscode.md`
5. `skills/plans/SKILL.md` → "Run a reconcile node" (for 13)

## Constraints already decided (do not re-litigate)

- Probes are done and passed; read the clone's logs only to quote evidence, never re-run probes.
- Codex desktop = Codex inside ChatGPT.app (`decisions.md`); write it up as `probes/codex-app.md`.
- Only reconcile 13 writes `docs/template-workspace-backlog*.html`, re-reading both right before writing.
- Other sessions share this checkout: stage only your own paths; never push. L99/L100 are the user's call.

## Do NOT reload

- Node 08 review (done, 0 blockers); L85/L95/L96/L98 (archived); `pilot/runs/`.

## First actions

1. `scripts/context-budget.sh register --project backlog-sweep`
2. Node 12: `plan.sh start 12-l86-probe-writeup --session 5 --project=backlog-sweep`; write
   `work/runtime-session-identity/probes/antigravity-ide.md` and `probes/codex-app.md` (Q1–Q4)
   from node 10's Log; name the gap: Codex Desktop runs the `.claude/settings.json` Stop hook
   (`context-budget-stop-hook.sh claude`, Codex payload) — wrote nothing, but a cross-runtime leak.
   Also note L86's "steps 3–4" mislabel (surfaces are the checklist's Optional line). `plan.sh done`.
3. Node 13: archive L86 with a `Fixed:` line, file the Stop-hook leak as a new card, close the
   plan and mark the item closed in `work/README.md`; `scripts/run-checks.sh`; sync; commit.
4. End with `checkpoint` (item closed).
