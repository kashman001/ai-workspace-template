# Review round 2 — doc-review-orchestrator synthesis (2026-08-13)

Method: `doc-review-orchestrator.md` run against `sdlc-map.md` with ten
independent reviewers — A (structure/Diátaxis), B×5 (audience fit, one per
segment), C (task-completion walkthrough), D (language), E (accuracy vs repo
+ research), F (skim/forward test). Audience model supplied by the
orchestrator from work-item context (user-delegated); segments: S1 leadership
skimmer, S2 template maintainer, S3 external eng lead/architect, S4
single-stage engineer, S5 cold reader. All reviewers fenced off the settled
structural decisions (session 1–2) and the applied P1–P3 fix list.

**Constraint added mid-review (user, 2026-08-13): the map must be consumable
independent of the workspace.** This upgrades S3/S5 from edge segments to
primary and raises the "implicit workspace context" cluster to Blocker.

---

## 1. Verdict

The document substantially serves its five audiences: every reviewer's job
was completable or nearly so, no pre-constraint Blockers were found, and the
accuracy pass verified every named template capability, backlog card, and
research-tier claim clean against the repo — zero drift. Under the
now-binding requirement of workspace-independent consumption it fails at
exactly one seam: it never identifies the template/workspace it assumes, so
the entire Template-support overlay and the gap dispositions are unactionable
for a reader outside the workspace. The single highest-leverage change is a
self-identification + routing upgrade to the "If you read nothing else" block
(name the template, state the investment implication, route each reader type)
plus glossing ~8 internal terms — targeted edits, no restructure.

## 2. Root cause

Not structural (A: macro-architecture is Diátaxis-clean), not surface writing
(D: prose largely clean). The core issue is an **implicit-context
dependency**: the doc was written from inside the workspace and inherits
referents it never establishes — the template itself, the backlog file behind
M27–M29/L38, sibling-file locations, and internal vocabulary
(launcher/ledger, graphify, superpowers, CONTEXT.md, RLM, S-numbers, AIOps).
Secondary root cause: **one-directional linking against targeted reading
paths** — node→register and node→appendix links are missing while the
prescribed read is "jump to your node," so node-level readers miss
dispositions (GAP lines) and guardrails (appendix rows).

## 3. Prioritized findings (merged, de-duplicated)

Severity shown post-constraint; pre-constraint severity in brackets where it
changed. "Flagged by" = independent corroboration.

### Blocker

- **F1 — "This template" is never identified** [was Major]. No name, root
  path, or one-line description anywhere in the file; S5 can plausibly
  misread it as a *document* template. Everything tagged `(native)` and every
  disposition is unactionable standalone. Fix: one sentence in "If you read
  nothing else": *"'The template' throughout means <name>, the AI-workspace
  template repository this file lives in, which ships skills, docs, and
  conventions for agent-driven work."* (B-S5, B-S3, B-S1)

### Major

- **F2 — Unresolvable references for standalone readers.** Backlog file for
  M27–M29/L38 never named (fix: "backlog cards live in
  `docs/template-workspace-backlog.html`" in the register intro); sibling
  pointers `research-modern-qa.md`/`decisions.md` unlocated (add "sibling
  files in this work directory"); `operational-knowledge.md` bare while all
  other docs are repo-rooted; "settled with the user" → "workspace owner";
  the status line's "seven-persona review… P1–P3" jargon — the single
  most-flagged item of the round (6 of 10 reviewers) — replace with
  "Status: stable (reviewed 2026-08-13; history in `decisions.md`)".
  (B-S2, B-S5, C, D, A, B-S1, F)
- **F3 — Unglossed internal vocabulary.** `launcher/ledger`, `graphify`,
  `superpowers`, `CONTEXT.md`, `RLM`, S-numbers, `AIOps`, `NL`, plus
  "this workspace"/"this template" drift (pick one term). Fix: glossary
  entries or first-use parentheticals; S-numbers get one clause at N5
  ("numbered acceptance criteria S1…Sn from the spec; S1–S4 is an example").
  (B-S5, B-S3, B-S4, C, D)
- **F4 — Per-node GAP lines carry no register cross-reference.** A node-only
  reader concludes "nothing is planned" when every gap is dispositioned;
  a future session could re-file G1 as new. Most-corroborated integrity
  defect of the round. Fix: `**GAP (G4 → backlog M27):** …` on all seven
  node GAP lines. (A, B-S2, B-S4)
- **F5 — Reading-path routing failures.** (a) Non-template readers are never
  told Template-support bullets are skippable — where S3 disengages; (b) the
  operative human-override guardrails live only in appendix rows the
  "jump to your node" path never reaches; (c) the tag legend is body text
  invisible to outline-jumpers, so node-landers meet undefined tags;
  (d) CI-failure triage — high value for S4(a) — exists only in the appendix;
  (e) testing spans N4+N5+lanes with no pointer saying so. Fix: expand
  "How to read it" with per-reader routing; promote the legend to a heading;
  add a one-line appendix pointer in node entries. (B-S3, C, B-S4)
- **F6 — Skim layer hides the costs and the "so what".** The N4 verification
  tax + bottleneck shift — the doc's main counterweight to its own premise —
  is mid-bullet, invisible at skim depth (skimmers conclude AI-at-build is
  all wins); the first screen lands the four claims but not the investment
  implication ("invest where AI stresses the seams"), which first appears
  ~line 392; the two [hype] verdicts are likewise skim-invisible. Fix: split
  a bold **Costs:** bullet at N4; add one implication sentence to the summary
  block; bold the two hype items (and/or extend claim 2 with the hype half).
  (F, D, A, B-S1)
- **F7 — Headline claim 3 appears self-contradicted.** The appendix's
  "AI overlay" column shows `[measured]` on the N8 fix-PRs row, undoing the
  skim-visible "only N4 carries [measured]" claim; D also flags the
  subject-misassignment ("tiers rest on practice patterns"). Fix: rescope —
  "only Build-stage *techniques* carry [measured]; where they reappear
  downstream the tag travels with the technique, not the stage." (D, F, E)
- **F8 — Tiers carry no adoption semantics.** C had to invent the
  tier→action mapping (measured=adopt, established=pilot, heuristic=
  pilot-with-override, hype=avoid) to complete the S3 task. Fix: one
  decision-guidance sentence per tier in the legend — extends, doesn't
  change, the fenced rubric. (C)
- **F9 — Gap register can't yield a single next investment.** G1 and G2 are
  both High, both "scaffolded 2026-08-13", no sequencing/effort/status; and
  "scaffolded" records routing, not state. Fix: a "next up" line under the
  register + one sentence stating dispositions record routing as of the date,
  current state lives in each work item's ledger. (C)
- **F10 — N8 "backlog conventions (native)" claims an unshipped capability.**
  The practice lives only in CLAUDE.md's Template Backlog section, which
  adopters are told to delete. Fix: downgrade to honest scoping
  ("template-repo-only practice") or point at the issue-tracker conventions
  that do ship; a generic backlog convention is itself a gap-register
  candidate. (B-S2, repo-verified)
- **F11 — Lane boundary-rule paragraph is unparseable.** Three lanes × eight
  nodes in one ~90-word sentence; both flaggers proposed the same fix: keep
  the two-sentence rule as prose, move the sweeps to a 3-row table.
  *(Disagreement: A rated Major, D Minor; Major kept — three segments hit it
  and it is the doc's densest passage.)* (A, D)

### Minor (grouped)

- **Stale deliberation vs settled decisions:** N6 hedges "arguably out of
  scope" where G7 is settled — align wording (A, B-S4); N5 duplicates
  nodehood rationale already in Settled questions (A).
- **Graph/edge integrity:** N8→N4 hotfix edge exists only in prose, absent
  from mermaid + edge table (E); rollback absent from N7's activities with no
  pointer to N6 (B-S4); bare N-references opaque at node landing — gloss
  inline (B-S4).
- **Tag discipline:** DORA caution tagged [measured] against the legend's own
  definition; tier tokens on cost/caveat claims don't parse. Adopt C's rule —
  tags only on AI-capability items; caveats get plain parentheses ("DORA
  2024, survey-based, correlational") — which also resolves E's retag
  proposal. Untagged Quality items (N5/N6/N8) need the same rationale
  parenthetical used at N4/N7. (E, C, D)
- **Consistency sweep:** edge-notation spacing variants; node-name variants
  across View 1 / mermaid / headings; "V/V" one-off; "work-dir" vs
  "work-item" launcher/ledger; Product-presence bullet absent from legend and
  only at N4–N6; legend titled "two overlays" but defines three tag systems.
  (D, E)
- **Glossary:** DORA entry 3× oversized and carrying unsourced facts — trim
  to definition + pointer (A, E); add self-healing tests + autonomous test
  agents so a reader can recognize the vendor pitch (C, F).
- **Actionability residue:** verification-tax has no task-type discriminator
  (C); [measured] items could name the transferable mechanism for
  non-hyperscalers — N4 half-does, N5/N8 don't (B-S3); no verification
  instrument connected to adoption (point at DORA four keys) (C); N6
  heuristic items are labels without a pattern (B-S4); magnitudes/named
  sources absent for S1 forwarding (B-S1).
- **Maintainer hygiene:** tiers stated in both node entries and appendix with
  no canonical side — declare "node entry wins" (B-S2); `verification.md`
  convention and worktree-isolation claims lack their defining-doc anchors
  (B-S2); N7 restates the runbook pattern without N6's setup-only caveat
  (B-S2).

### Where reviewers disagreed

- Lane-sweep paragraph severity (A: Major / D: Minor) — sided with A, above.
- Hype surfacing: B-S1 wants it in the headline claims; F wants bolding at
  N5 — complementary, do both.
- DORA retag (E) vs tags-off-caveats rule (C) — C's rule adopted as cleaner
  and more general.

## 4. Audience coverage matrix

E = essential, U = useful, N = noise for that segment.

| Section | S1 lead | S2 maint | S3 eng lead | S4 stage eng | S5 cold |
|---|---|---|---|---|---|
| Status header | N | U | N | N | N |
| If you read nothing else | E | U | E | U | E |
| Shape of the model | U | U | E | N | U |
| View 1 (narrative) | U | U | E | U (nav) | U |
| View 2 + deep-dives | N | U | U | N | U |
| Cross-cutting lanes | N | U | U | U | U |
| Tag legend | N | E | E | E | E |
| N1–N8: AI/Quality lines | N | U | E | E | U |
| N1–N8: Template lines | N | E | N | U | N* |
| Gap register: gaps/severity | U | E | U | U | U |
| Gap register: dispositions | N | E | N | N | N* |
| Settled structural questions | N | U | N | N | N |
| Glossary | U | N | U | U | E |
| Appendix (artifacts) | N | U | E | U | U |

\* becomes U once F1/F2 land (standalone readers can then act on them).

The pattern: the template strand (Template lines, dispositions, Settled
questions, status header) is noise for three of five segments — a routing
problem, not a splitting problem, since interleaving is precisely the value
for S2 and the map's thesis.

## 5. Recommended restructure

**Keep one document — no split.** The interleaved two-overlay design is the
doc's point; the standalone defect is a missing preamble plus glosses, not a
wrong shape. (Escalation path only if the map is later published externally:
extract a portable "SDLC × AI" map and keep a thin workspace-overlay
companion — not warranted now.) Outline-level changes:

1. Status/provenance → one plain line, or a footer with the Settled
   structural questions folded in.
2. "If you read nothing else" gains four sentences: template identification
   (F1), investment implication (F6), rewritten claim 3 (F7), per-reader
   routing (F5).
3. `### Legend — tags used in every node entry` promoted to a heading; gains
   tier→action guidance (F8) and the Product-presence line.
4. Traceability / test-plan production / Steady state promoted to H4s under
   View 2 (A).
5. Lane sweeps → 3-row table under the boundary rule (F11).
6. Node entries: uniform bullet grammar — Activities / Quality / AI helps /
   **Costs** (N4) / Product presence / Template support /
   **GAP (G# → disposition)**.
7. Gap register: backlog file named, "next up" sequencing line, dispositions
   marked maintainer-facing.
8. Glossary: +graphify, +superpowers, +RLM, +S-numbers, +AIOps,
   +self-healing tests, +autonomous test agents; DORA trimmed.

## 6. What is already working — do not break

- **The summary block.** Called "a model orientation block" (B-S5) and
  "genuinely skim-optimized" (F); first-100-words test passes for every
  segment that read it.
- **Node findability.** S4 found the right node in seconds in both test
  instances; headings are self-describing (A).
- **Accuracy.** E's full sweep: every named capability, path, card, and
  work item exists and matches; research-tier fidelity confirmed including
  the honest caveats (TestGen-LLM "coverage, not defect outcomes").
- **The gap register's forward direction.** Gap → disposition → landing
  place is complete and verified; the reverse (node → register) is the
  broken half (F4).
- **Tier + "stays human" grammar.** S3 could derive a per-stage AI posture
  and C completed a defensible adoption decision from the doc alone.
- **Honest self-assessment.** N6 "thinnest node", scope-honesty legend note,
  hype verdicts — reviewers consistently trusted the doc *because* of these.
- **Prose.** D: mostly active voice, actors named at decision points,
  telegraphic style consistent; only two Major language items, both already
  covered above.

---

*Per the orchestrator's rules, no fixes have been applied — diagnosis only.
Fix pass awaits user direction. Full per-agent reports live in the session
transcript (session 4, 2026-08-13); this synthesis is the durable record.*
