## 2026-08-12 — N5 (pre-release V&V) is a real node, not N4's exit gate
**Chose:** Keep the pre-release V&V checkpoint as backbone node N5.
**Because:** It's the home for genuinely phase-like activities (regression, UAT, beta, sign-off) and the traceability target for N1's acceptance criteria; collapsing it leaves UAT and regulated contexts homeless.
**Rejected:** Fold into N4 as exit gate — loses UAT/regulated home; Split (gate in N4 + UAT in N6) — more precise but restructures for little gain. Map notes strong-CI teams may collapse N5 in practice.
**Blast radius:** work/sdlc-ai-mapping/sdlc-map.md (node table, graph, per-node entries)
**Promote?:** no

## 2026-08-12 — N8 (Maintain) keeps node status
**Chose:** Keep Maintain as backbone node N8.
**Because:** Triage, dependency upgrades, and regression-per-fix are distinct activities with their own AI/template story, and N8 is the dominant entry point for a live product — dissolving it hides that.
**Rejected:** Dissolve into the cycle (maintenance work enters at N2 like all work) — philosophically cleaner but strands triage/upgrades without an anchor.
**Blast radius:** work/sdlc-ai-mapping/sdlc-map.md
**Promote?:** no

## 2026-08-12 — Overlay granularity: per node, lanes tagged inline
**Chose:** 8 per-node entries; quality items carry [verification]/[validation] tags and lane-specific items are called out inline.
**Because:** Readable and maintainable; a matrix would be mostly empty cells.
**Rejected:** Full 8×4 node×lane matrix — systematic but heavy, many near-empty cells; per-node plus standalone lane sections — duplicates content between node and lane views.
**Blast radius:** work/sdlc-ai-mapping/sdlc-map.md (per-node entry format)
**Promote?:** no
## 2026-08-13 — Gap disposition: G1 and G2+G3 become work items; G4/G5/G6/G8 backlog cards; G7 out of scope
**Chose:** Two new work items — feedback-intake (G1) and quality-gates (G2 absorbing G3, since gate policy is quality-enablement's first deliverable). G4, G5, G6, G8 become template-backlog cards. G7 (release engineering) declared explicitly out of scope for the template.
**Because:** G1/G2 are the two high-severity gaps (steady-state loop edge; the lane DORA says gets more load-bearing under AI) and need multi-session treatment; the others are bounded single-session additions that can graduate later.
**Rejected:** Three separate items (G2 vs G3 split) — overlapping half-items; promoting G6 to a work item — bounded enough for a card; dropping G5/G8 uncarded — cheap to keep visible.
**Blast radius:** work/sdlc-ai-mapping/sdlc-map.md (gap register), docs/template-workspace-backlog.html (4 new cards, successor session), two future work/ directories.
**Promote?:** no

## 2026-08-13 — G7: release engineering is out of template scope
**Chose:** The template does not own release/deploy machinery (rollout plans, CD pipelines, canary tooling); the map says so explicitly. Escape hatch: docs/runbooks pattern + wizard skill for cutovers when a project needs one.
**Because:** This is a coordination workspace, not a delivery platform; owning N6 tooling would drag in stack-specific machinery the template can't keep agent-agnostic.
**Rejected:** Adding release-runbook coverage now — no concrete demand; silence in the map — omission reads as oversight rather than decision.
**Blast radius:** work/sdlc-ai-mapping/sdlc-map.md (N6 entry, gap register)
**Promote?:** maybe — if the template later grows an opinion on N6, this becomes an ADR-worthy scope boundary

## 2026-08-13 — Review method: seven personas, producer/consumer split governs fix buckets
**Chose:** Seven-persona parallel agent review of sdlc-map.md (leadership, product, architect, quality, engineer, devops, new-reader), each fenced off settled decisions; findings bucketed consumption-layer (A) vs content-accuracy (B) per the user's producer/consumer distinction. Synthesis at review-findings.md; fixes applied P1-first.
**Because:** Consumers (leadership, new readers) only flagged consumption surfaces; producers flagged model accuracy — the split cleanly partitions fixes so consumer-facing additions never risk producer detail.
**Rejected:** Separate EVP/VP and PM/PM-leadership personas — same questions at this altitude; security/compliance persona — overkill outside regulated context; support/CS persona — feedback-intake work item owns that concern.
**Blast radius:** work/sdlc-ai-mapping/review-findings.md, sdlc-map.md (successor session's edits)
**Promote?:** no
