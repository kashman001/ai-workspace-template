# Catchup prompt — sdlc-ai-mapping (paste into a new agent session)

We're resuming sdlc-ai-mapping. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

Apply the seven-persona review fixes to `sdlc-map.md`, **P1 first**, per the
prioritized synthesis in `review-findings.md` (the canonical fix list —
user-approved). P1 = tier honesty + on-ramp + N1/N2 product pass; then P2
(edges, V&V retags, lanes, N4 honesty, N5/N6 framing); then P3 (additions +
dedup + cold-read fixes). After the fix pass, propose closing this work item.

## First actions

1. `scripts/context-budget.sh register --project sdlc-ai-mapping`
2. Work in the existing worktree branch `worktree-sdlc-ai-mapping-s2`
   (pushed to origin) or a fresh worktree merged up to it — do not edit the
   map outside a worktree.
3. Read `review-findings.md` in full; execute P1.1–P1.4 as one unit,
   commit, `record`.
4. Pre-flight headroom, then P2 clusters (commit per cluster), then P3.
5. Re-check README success criteria; propose closure + branch merge to the
   user when the fix pass lands.

## Constraints already decided (do not re-litigate)

- All session-1 constraints stand: N5/N8 nodehood, per-node overlay, two
  views kept, evidence tiers from `research-modern-qa.md`, gap
  dispositions incl. G7 out of scope (`decisions.md` 2026-08-12/13).
- Review roster + producer/consumer fix bucketing — settled
  (`decisions.md` 2026-08-13 review-method note).
- Fix order P1→P2→P3 is user-approved; tensions in `review-findings.md`
  "Tensions noted" are already resolved there — apply the stated
  resolutions (e.g. steady-state: correct wording, then promote).
- N5-collapse reframing (P2.5) is framing only; N5 stays a node.

## Read these, in order

1. `work/sdlc-ai-mapping/review-findings.md` — the fix list (full read)
2. `work/sdlc-ai-mapping/handoff.md` (top block)
3. `sdlc-map.md` — targeted reads per fix cluster; avoid whole-file loads
   (445 lines) unless doing the on-ramp edit (P1.3) which touches the top.

## Do NOT reload

- `research-modern-qa.md` — only consult to verify a specific tier claim
  while executing P1.1.
- The seven raw persona reports — fully distilled into review-findings.md.
- Backlog HTML — no backlog work pending; targeted reads only if a finding
  graduates to a card.

## State snapshot

- Branch `worktree-sdlc-ai-mapping-s2`, clean, pushed to origin (contains:
  scaffolds work/feedback-intake + work/quality-gates, backlog cards
  M27–M29+L38, review-findings.md, this rollover). Not merged to main.
- No running processes; no external tickets.
- `work/kimi-k3-agent-integration/` is another effort's untracked dir — leave it.
