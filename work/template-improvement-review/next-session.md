# Next Session — template-improvement-review (session-management review: STAGE 2 — design + architecture)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

Write **Part 2 — the design and architecture** of the redesigned
session-management / context-budget / multi-session subsystem, on top of the
accepted Stage 1 evaluation. This is a DESIGN, not an implementation plan: no
phases, tickets, or file-by-file edit lists. Stage 3 (evaluate the design vs
scenarios/flows + architect review) follows in a later session; Stage 4 (plan
implementation) only after the design is finalized.

Four-stage process (user, 2026-09-14): (1) research/evaluate ✔ accepted →
(2) design/architecture ← YOU → (3) evaluate design → (4) plan implementation.

## Binding inputs (read in this order)

1. `work/template-improvement-review/session-management-review-findings.md`
   — Part 1 §1–§5 (skim), **Part 1b entirely** (§1b.1–§1b.7). All 17
   decisions in §1b.5 are ACCEPTED as recommended. §1b.7 is a binding
   constraint: reliable / repeatable / reproducible — no load-bearing step may
   depend on the agent remembering, judging or reporting; script-executed,
   script-verified, coded verdicts.
2. `work/template-improvement-review/evaluation/stage1-architect-review.md`
   §7(d) "simplest design" (the seed) and §7(c) hidden couplings; §2a for what
   each current state file encodes.
3. `work/template-improvement-review/evaluation/stage1-scenario-evaluation.md`
   §A (the three loops today vs proposed) and §D (13 probes).
4. `work/template-improvement-review/handoff.md` — top block only.

## Do NOT reload

`review.md`, `decisions.md` (append only), backlog HTML whole, the big scripts
whole (delegate reads to agents; parent reads only what a design section
needs), `stage1-reevaluation-vs-main.md` beyond its verdict table.

## State snapshot

- `main` = Stage 1 commit on top of a213b3d; clean; ahead of origin by local
  commits only (do not push).
- Supervisor pid 72900 live but running pre-a213b3d `session-loop.sh` code
  (hazard, §1b.2). Do NOT edit `session-loop.sh` this session. Decision 12:
  end that chain deliberately (Ctrl-C at an interactive pause) before the
  first edit, and make that edit a `main "$@"` wrapper.
- No code changes yet. F10 small defects remain (fix in Stage 4's first
  phase, not now).

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
2. Read inputs 1–4 above.
3. Cheap probes the user authorised (decisions 5 and 17), run them or
   delegate to one agent, results into Part 2 as evidence:
   - V2: does `/clear` rotate the transcript JSONL? (a throwaway claude
     session with explicit low thresholds; check the artifact path before and
     after `/clear`.) Decides keep-vs-drop of `--clear` / ADR-0009.
   - `claude --bg` env survival (launch-next-session.sh ~:1184 claim): decides
     whether the `successor-pending` handshake can be retired.
4. Draft Part 2 with ONE general-purpose agent (or two, split record+liveness+
   supervisor vs adapters+fleet+docs+tests), given inputs 1–3 and the probe
   results. Required sections: (a) concepts kept (target ≤ 7, name each and
   what it replaces); (b) `work/<p>/session-state.json` schema — every field,
   its single writer, the moment written, the invariant it asserts, what it
   retires; (c) liveness rule per runtime; (d) supervisor verdicts (staged /
   quit / broken) and chain budget; (e) the launch→register identity binding
   (coupling 1–2); (f) runtime adapter table + support matrix (attended /
   supervised per runtime: claude, codex, copilot-CLI, gemini; VS Code and
   opencode as follow-ups) + one hook dispatcher; (g) `scripts/fleet.sh`
   boundary and its interface to the daily loop; (h) the boundary skill and
   the mechanical gates per §1b.7 (each step's script, exit code, refusal
   rule); (i) doc set (one rule / one place) and template defaults;
   (j) test posture (behaviour tests, `reason=<code>`, fixture helper) and the
   probe catalogue mapped to scenarios; (k) ADRs superseded/amended and the
   new ADR(s); (l) explicit non-goals (multi-user, VS Code supervision,
   opencode). Keep it minimal: a concept that is not earned by a scenario or
   an incident is out.
5. Append as **Part 2** to the findings file (keep Part 1/1b intact).
6. `scripts/context-budget.sh record --label "Part 2 design drafted"`.
7. Present a tight summary + pointer; STOP for the user's review. Do not start
   Stage 3 unasked. On the user's go, Stage 3 = fresh architect agent +
   scenario/flow agent over the design (same shape as Stage 1), verdicts into
   Part 3.
