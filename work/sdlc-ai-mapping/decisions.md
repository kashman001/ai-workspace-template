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

## 2026-08-13 — Round-2 review method: doc-review-orchestrator, agent-supplied audience model
**Chose:** Ran the user-provided `doc-review-orchestrator.md` (10 agents: Diátaxis structure, 5 audience-fit instances, task walkthrough, language, accuracy-vs-repo, skim/forward test) with the Phase-0 audience model supplied by the orchestrating agent from work-item context (user delegated it). Segments S1 leadership / S2 maintainer / S3 external eng lead / S4 stage engineer / S5 cold reader. Synthesis at `review2-findings.md`.
**Because:** The orchestrator's fixed lens set (structure, task-completion, skim divergence) covers dimensions the round-1 persona panel didn't, and the user explicitly directed this method.
**Rejected:** Another free-form persona round — overlaps round 1; asking the user the Phase-0 questionnaire — user delegated the answers.
**Blast radius:** work/sdlc-ai-mapping/review2-findings.md; sdlc-map.md (future fix pass)
**Promote?:** no

## 2026-08-13 — Constraint: sdlc-map.md must be consumable independent of the workspace
**Chose:** Standalone consumability is a binding requirement — a reader with no access to this workspace (S3/S5) must be able to use the map, including understanding what "the template" is and resolving every reference the doc makes. Stated by the user mid-round-2 review; upgrades the implicit-context findings (F1–F3 in review2-findings.md) to Blocker/Major.
**Because:** The map's value extends beyond template maintenance; workspace-internal referents silently exclude every outside reader.
**Rejected:** Splitting into a portable map + workspace overlay — interleaving is the doc's value for the maintainer; a self-identification preamble plus glosses achieves standalone consumability without the drift risk of two documents (revisit only if published externally).
**Blast radius:** sdlc-map.md (summary block, glossary, register intro); all future review fences
**Promote?:** maybe — becomes ADR-worthy if the map is published outside the repo

## 2026-08-13 — Round-2 Minors closed as won't-do; work item closed
**Chose:** Close the remaining round-2 Minors (review2-findings.md §3 leftovers listed in the session-5 handoff block, plus Sourcery's two advisory PR-#7 comments: routing-paragraph density, GAP cross-ref wording consistency) as won't-do, and close the sdlc-ai-mapping work item. User decision, session 6.
**Because:** PR #7 delivered the Blocker + all Majors; the Minors are polish with no accuracy or consumability impact, and the map is already merged and in use.
**Rejected:** A short Minors pass — cost (another review/PR cycle on a ~640-line doc) outweighs the polish gain; reopen only with a fresh reason.
**Blast radius:** none to sdlc-map.md (no edits); work/sdlc-ai-mapping/ ledger + launcher record the closure
**Promote?:** no

## 2026-08-13 — Deck-v3 formulations folded back into the map
**Chose:** Re-integrate four formulations that building the presentation deck ("Where AI Actually Helps", v3) sharpened: (1) claim 4 gains the causal mechanism (AI trades writing time for review time; bottleneck moves to human checkpoints); (2) claim 2 recast as the if/then rule (machine-checkable → AI leads; judgment/authority → AI drafts, human decides); (3) a three-sentence refrain closes "If you read nothing else"; (4) the gap register notes both High-severity gaps are seams, not stages. User decision, session 7 — the deck walkthrough is the "fresh reason" the closure note required.
**Because:** The deck forced compressions the ~640-line map never produced; porting them back makes the map's front matter carry the same punch standalone.
**Rejected:** Porting the deck's "asks" slide (approval bars, funding decisions) — pitch material, not map material; would blur the document's role.
**Blast radius:** sdlc-map.md front matter + gap-register intro only; no node entries, tags, or appendix touched
**Promote?:** no
