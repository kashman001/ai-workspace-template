# Catchup prompt — sdlc-ai-mapping (paste into a new agent session)

We're resuming sdlc-ai-mapping. Works in any runtime (Claude Code, Codex,
Gemini, OpenCode) — all read `CONTEXT.md` via their entrypoint.

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, and REPLACED
> at each rollover: it holds what to do next, still-binding constraints, and
> pointers — never session history. Past-tense provenance lives in
> `handoff.md` (the append-only ledger). Convention:
> docs/work-directory-conventions.md.

## Mission

The SDLC map is **complete and user-reviewed** (`sdlc-map.md`). What remains
is executing the agreed gap dispositions: scaffold two new work items, add
four backlog cards, then close this effort against its success criteria.

## First actions

1. `scripts/context-budget.sh register --project sdlc-ai-mapping`
2. Scaffold `work/feedback-intake/` via `create-work-item` (gap G1: convention
   + skill routing production/user signal into discovery — the N7→N1 edge).
   Seed its README scope from `sdlc-map.md` gap register + N1/N7 entries.
3. Scaffold `work/quality-gates/` via `create-work-item` (gap G2 absorbing G3:
   quality-enablement lane — test infra guidance, CI gate policy, AI
   failure-triage, flake policy). Seed from gap register + N4 entry + lane table.
4. Add backlog cards for G4 (design-time testability prompt), G5 (UAT/beta
   coordination), G6 (postmortem convention), G8 (dependency/test-suite
   health) to `docs/template-workspace-backlog.html` — follow its
   "Maintaining this backlog" section; **targeted reads only, never load the
   HTML whole** (grep for card IDs / section anchors first).
5. Check `README.md` success criteria — all three are now met or met upon
   step 2–4 completion; if so, propose closing/checkpointing this work item
   to the user.

## Constraints already decided (do not re-litigate)

- Graph model: N5 and N8 are real nodes; overlay per node with lane tags —
  `decisions.md` 2026-08-12.
- Gap dispositions (incl. G2+G3 merge, G7 out of scope) — `decisions.md`
  2026-08-13.
- Two views (numbered list + mermaid graph) are both kept on purpose.
- Evidence tiers ([measured]/[established]/[heuristic]/[hype]) come from
  `research-modern-qa.md`; don't restate claims without them.

## State snapshot

- Branch `main`; this work directory committed at rollover (see git log).
- `work/kimi-k3-agent-integration/` is another effort's untracked dir — leave it.
- No running processes; no external tickets.

## Read these, in order

1. `work/sdlc-ai-mapping/README.md`
2. `work/sdlc-ai-mapping/handoff.md` (top block)
3. `work/sdlc-ai-mapping/sdlc-map.md` — gap register + N1/N4/N7 entries
   (targeted reads; the whole file is long)

## Do NOT reload

- `research-modern-qa.md` — already distilled into the map's tiers/claims;
  load only if a citation is questioned.
- The three structural questions and eight gap dispositions — settled, see
  Constraints.
