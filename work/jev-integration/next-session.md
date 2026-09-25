# Catchup prompt — jev-integration (paste into a new agent session)

We're resuming `jev-integration`. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Research wave 1 is closed (`research/synthesis.md`) and a live spike with the
user's key closed the facts it left open (`research/spike.md`, 2026-09-24).
The only remaining step is **human-only**: the fit decision, worked through
with `grill-with-docs` and recorded as a Tier-2 note in `decisions.md`. No
integration code or spec until that note exists.

## >>> START HERE <<<

Position: **fit decision open; grill round 1 posed in session 6, unanswered.
This session must be interactive.**

1. `scripts/context-budget.sh register --project jev-integration` (expect `seq=7`).
2. **Re-pose the open question to the user, verbatim:**

   > **Fit decision** in `decisions.md`: which template seam(s) a typed-decision
   > model serves better than the current runtime (or none), with the rejected
   > alternatives and the evidence from `research/`.

   Then re-issue the **four open round-1 questions** exactly, with the
   orchestrator's recommendations (the user may answer each, or say "go with
   your picks"):

   - **Q1 axis of "serves better"** — (a) output quality, (b) cost, (c)
     determinism + thresholdable `confidence`, (d) weighted. *Rec: (c), latency
     second — `spike.md` shows parity on labels, negligible cost, 0.64s vs 4.83s.*
   - **Q2 candidate scope** — all six §5 seams, or narrow to rlm leaf
     classification (+ research-wave verdict) with the other four rejected in
     one line each. *Rec: narrow; rlm is the only "integrate" candidate — the
     verdict seam's value is the re-fetch, not the label.*
   - **Q4 terms risk** — Jev (a) optional path with the current runtime as
     default/fallback, (b) default for the seam, (c) not at all. *Rec: (a);
     ADR-0011 keeps load-bearing gates off model calls; a downloader without a
     key must still get a working `rlm`.*
   - **Q5 scope of the R0.4 lift** — key usable (a) orchestrator fact-finding
     only, (b) any dispatched agent, (c) spike only, rule reinstated. *Rec: (a)
     now; widen to (b) in the spec if "integrate".*

   (Q3 — decide without live evidence? — is closed: the user supplied the key
   and the spike ran; `decisions.md` records the lift.)

   Round 2 (threshold policy, `other` handling, `jev-latest` vs pinned
   `jev-1.13.0`, where the swap point goes in `rlm_repl.py`) only after these.
3. **If nobody answers**: do NOT decide the fit yourself, do NOT start design
   work; end via `checkpoint` (stop door), not a rollover.
4. After the note exists: `scripts/context-budget.sh record --label "fit decision recorded"`,
   commit (do not push; report how far ahead main is), then — only if
   "integrate" — `to-spec` is the next governing skill.

## Do NOT reload

- The research records beyond synthesis §5–§6, `seam-inventory.md`, and
  `spike.md`; claim ids resolve to `record.md` rows by grep.
- The corrections debate (`rulings.md` through R41), the sweep, R0.1.
- Do NOT re-run the spike; its results are on disk. The key is in the macOS
  keychain as `jev-api-key` (`security find-generic-password -s jev-api-key -w`)
  — read it only for a new fact the grill needs, never print it, never write it
  to a file.

## Constraints already decided (do not re-litigate)

- Template rules for anything that ships: agent-agnostic, CLI-first or
  `mcp-fragments/`, key in the keychain, documented as a first-class addition,
  a test that proves it without a live key.
- Research before design: no integration code or spec until `decisions.md`
  records the fit.
- Raw `pass/*.md`, `fact-check.md`, every brief, and `synthesis.md` are
  provenance — never edited (spike facts live in `spike.md` beside them).
- The orchestrator rules; agents recommend. The fit decision is the user's.
- R0.4 lifted for orchestrator fact-finding only (`decisions.md`, 2026-09-24).

## State snapshot

- Branch `main`, clean, 57 commits ahead of `origin/main`, not pushed.
- `work/jev-integration/`: `decisions.md` (one note: R0.4 lift; fit NOT
  recorded), `research/spike.md` + `spike.py`, synthesis and records as before.
  No plan (`plan.sh status`: none). All dispatch records closed.
- `context-budget.env` sets `ROLLOVER_RELAUNCH=auto`; this session was ended
  through the checkpoint door, so the supervisor is not looping.

## Read these first, in order

1. `work/jev-integration/handoff.md` (top block)
2. `research/spike.md`
3. `research/synthesis.md` §5–§6
4. `research/seam-inventory.md` (only once the grill reaches a specific seam)
5. `skills/grill-with-docs/SKILL.md`, `skills/decision-log/SKILL.md`
