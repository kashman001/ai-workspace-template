# Seven-persona review of sdlc-map.md — consolidated findings (2026-08-13)

Seven parallel persona reviews (Leadership, Product, Architect, Quality,
Engineer, DevOps, New Reader) of `sdlc-map.md`, each ≤10 findings + verdict.
This file is the deduplicated synthesis; per-persona attribution in
parentheses. All seven verdicts were "yes, with changes" — no persona
rejected the model; universal praise for the graph-not-pipeline shape, the
steady-state loop, the test-plan-accretion paragraph, and the tier idea.

Buckets per the user's producer/consumer distinction: **A = consumption
layer** (additive, serves readers who consume the map), **B = content
accuracy** (edits to the model, serves producers who work inside it).

## Priority 1 — credibility and orientation

- **P1.1 (B) Evidence-tier honesty** (QA F1/F2, Product F4, DevOps F3 — 3
  personas independently). `research-modern-qa.md` only substantiates the
  QA/testing claims, but the legend says every tier comes from it. N1/N2
  product claims, N7 AIOps claims, and many [established] tags (spec
  drafting, grooming, code-review assist, postmortem drafting…) are
  unbacked. Specific inflations: N5 "security review assist [established]"
  → retag [heuristic] (QA F2); DORA [measured] should be annotated
  "survey, correlational"; TestGen-LLM measured coverage/acceptance, not
  defect outcomes (QA F3). Fix: scope the legend honestly ("QA tiers
  research-sourced; others author judgment under the same rubric") +
  retag/annotate the named items.
- **P1.2 (B) Tier vocabulary drift** (QA F7, Engineer 8). Hybrid tags
  ("[established pattern, tooling effectiveness unverified]",
  "[heuristic — weak evidence]") break the 4-token scheme; same lineage
  tiered differently at N1 vs N5. Normalize to four tokens, qualifiers in
  prose; reconcile N1/N5 scenario-drafting.
- **P1.3 (A) On-ramp** (Leadership 1/2/6, New Reader 1/4). Add ~10-line
  "If you read nothing else" top section: purpose + audience statement,
  how to read it, glossary pointer, and 3–4 headline claims — steady-state
  loop, checkable-vs-judgment AI pattern (hoisted from the buried
  "Pattern across the AI column" paragraph), DORA 2024 caution (currently
  hidden in a glossary entry), "only N4 carries [measured] evidence"
  rollup (Leadership 5), and the invest-where-AI-stresses-seams sentence
  above the gap register (Leadership 4).
- **P1.4 (B) N1/N2 product honesty** (Product F1–F3, F6). Steady-state
  paragraph currently demotes discovery — reword: delivery becomes
  N8-dominant while discovery runs *continuous* in parallel (note:
  Leadership wants this same paragraph *promoted*; correct wording first,
  then promote per P1.3). N1 activities add opportunity assessment,
  assumption testing, problem-vs-solution validation; output = validated
  opportunity + PRD. N2 activities add trade-offs under constraint,
  kill/defer decisions, stakeholder negotiation, outcome-vs-output; one AI
  line for prioritization-input synthesis. N1 Quality adds
  "assumption/demand testing with users [validation]".

## Priority 2 — model wiring and V&V correctness

- **P2.1 (B) Edge fixes** (Architect 1/3/6/7, DevOps F1, New Reader 5).
  (a) N5 outbound: scenario/criteria gaps found at V&V need a route to
  N1/N3 (narrative claims it; graph lacks it). (b) Expedited hotfix path:
  N8→N4 dashed edge or a steady-state note. (c) N7→N6 rollback edge:
  separate reverting-the-system (release action) from fixing-the-code
  (N6→N4 relabel). (d) N3→N2 "design revises scope/estimates" or record
  the exclusion. (e) N7→N8 row in the feedback-edge table is a backbone
  edge — retitle table "Edges beyond the forward path" or footnote.
- **P2.2 (B) V&V tag corrections** (QA F4, DevOps F8 — canary called
  independently by both). Canary analysis [validation]→[verification];
  flaky-test discipline is enablement hygiene, not product verification;
  exploratory testing annotate intent-vs-outcome; postmortems untagged at
  N7 (tag or footnote). Plus (A): the [verification]/[validation] tags are
  never legended (New Reader 3) — add third legend bullet.
- **P2.3 (B) Lane instantiation** (Architect 2/4, QA F8). Only Quality
  lane exists per node; enablement/knowledge/coordination are labels.
  Give each non-Quality lane a one-line N1…N8 sweep or an explicit
  "manifests through shared infrastructure" note; state the lane/node
  boundary rule (lanes own practice+infra; nodes own instances); mark
  dual-homed artifacts (tickets, ADRs); add enablement artifact row.
  Also add test environments & test data to the enablement lane + N5
  (QA F6, DevOps F5 — platform/environment work currently homeless;
  either N6 activity or explicit scope-out note).
- **P2.4 (B) N4 honesty pass** (Engineer 1–3). Add debugging to N4
  activities (map's own support column cites debugging skills); add the
  verification-tax cost line (agentic output trades writing time for
  review time, can be net-negative [heuristic]); name the human
  bottlenecks (review latency, CI throughput) as the constraint under
  AI-raised volume; optionally cite worktree isolation as template
  support for concurrent agents.
- **P2.5 (B) N5/N6 framing** (QA F5, Engineer 9, DevOps F2). Flip N5
  collapse caveat: continuous-CI is the norm, standalone N5 is the
  sign-off/regulated case (nodehood itself stays settled); note regression
  suite = CI suite in the common case; carry a "(often folded into 4/6)"
  hedge into View 1 item 5. N6: state deploy ≠ release (flags decouple);
  rename "CI/CD pipelines" activity to "CD / deploy automation";
  "rollback decisions stay human" → "criteria human-owned, execution
  increasingly automated" (DevOps F4).

## Priority 3 — completeness and reading friction

- **P3.1 (B) Node additions**: N3 threat modeling + technical spikes
  (Architect 5/8, slots into G4); N8 breaking-change migrations
  (long-running, launcher/ledger fit) + split refactoring tier
  small=[established]/large=[heuristic] (Engineer 4); N8 flag retirement
  (DevOps F7); DORA four keys named in N6/N7 quality (DevOps F6);
  fuzzing applicability qualifier "(systems/security-critical)"
  (Engineer 7); criteria-maintenance clause on the N1⇢N5 trace
  (Engineer 6); N7→N1 edge label broadened to include qualitative signal
  + N8→N1 path for request-shaped feedback (Product F5); product
  presence line at N4/N5/N6 (Product F7); N5 artifact row covers
  perf/security results (Architect 9); glossary adds 3–4 product terms
  + spike (Product F8, Architect 8); opportunity-assessment artifact row
  at N1 (Product F10).
- **P3.2 (A) Deduplication**: single tier legend (4 personas hit this);
  artifacts table loses its duplicate tier tags (one canonical source),
  leads with the pattern paragraph, moves to appendix or gets per-node
  highlights (Leadership 7, QA F10, Engineer 5, New Reader 7); extend
  "where required" qualifiers to heavyweight artifact rows (Engineer 5).
- **P3.3 (A) Cold-read fixes** (New Reader 2/6/8/9/10): gloss V&V,
  shift-left/right, lane on first use; pre-graph sentence "dotted edge =
  correspondence, not flow"; gloss SETI/TE, rlm, wizard; cut "fractally";
  fix top-of-file forward references to N5/N8 before nodes exist;
  test-plan paragraph placement (Product F9 wants it moved after nodes —
  vs Architect/Engineer who praise it in place; suggest keep but add a
  one-line preface).

## Tensions noted

- Steady-state paragraph: Leadership amplify vs Product correct →
  correct, then amplify (both).
- Test-plan paragraph placement: Product move vs Architect/Engineer keep
  → keep + preface (P3.3).
- N5 collapse reframing (P2.5) brushes the settled N5-nodehood decision
  but doesn't violate it — framing only.
- Artifacts table: consumers want it appendixed; producers want it
  deduped but kept. Both satisfied by canonical-tier + appendix.

## Raw outputs

Full per-persona reports were returned by the seven review agents
(session 2, 2026-08-13); this synthesis is the durable record.
