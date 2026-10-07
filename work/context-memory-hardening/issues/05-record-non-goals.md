# 05 — ADR: no vector store, no MMR, no numeric decay scoring (D5)

**What to build:** an ADR under `docs/adr/` using `skills/decision-log/SKILL.md`
(Tier-2 note in this item's `decisions.md` first, then promote). Decision:
the template won't adopt hybrid vector retrieval, MMR re-ranking, or
Ebbinghaus-style numeric decay scoring.

Reasons:
- They need a database or embedding service, which breaks the plain-files,
  any-runtime property.
- Curated indexes ("summaries up, pointers down", `MEMORY.md`,
  `docs/README.md`) already meet the need at this scale.
- M43's last-confirmed plus review sweep is the chosen lightweight
  substitute.

Rejected alternatives: adopting them; making them optional (rejected
because it's maintenance cost for unproven value). Also cite the async
consolidation loop deferral (`work/context-memory-eval/decisions.md`) as a
related open question, not part of this decision. Add the ADR to the index
in `docs/adr/README.md`.

D-cards resolve with a `Decided:` line instead of `Fixed:` and status
"Decided" (see D4 in the archive for the shape).

**Blocked by:** 03 (the ADR points to M43's implemented mechanism).

**Status:** done

- [x] Tier-2 note in `work/context-memory-hardening/decisions.md`, then ADR
      `docs/adr/NNNN-…` (next free number) and an index line
- [x] D5 moved to the archive with status Decided and a `Decided:` line;
      scorecard Decided +1
- [x] Backlog card resolved in the same commit: badge → Resolved, `Fixed:`
      line with the commit, card moved to the matching section of
      `docs/template-workspace-backlog-archive.html`, scorecard and "Last
      updated" changed, change-log row added
- [x] All `scripts/tests/test-*` suites green; `scripts/check-workspace-structure.sh` exit 0
- [x] One commit, `Fix <ID>: …`, with a `Decision:` trailer

**Done (2026-10-07, session 3).** ADR-0013 promoted from the Tier-2 note
(flipped to `done → ADR-0013`), indexed in `docs/adr/README.md`. D5 archived
under Decisions with a `Decided:` line. The template "badge → Resolved /
`Fixed:`" box is met by the D-card shape (status Decided, `Decided:` line),
as the ticket's own note says.
