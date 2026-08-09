## 2026-08-08 — Gap-analysis walk-through verdicts (session 4)
**Chose:** Adopt the recommended sequencing from gaps-and-coverage.md as-is
(Gap 6 clean-room test → Gap 2 Z0 template → Gaps 3+8 → Gap 7 → defer 4 → defer 1).
Green-light Gaps 6 and 2 to start now; Gaps 3+8 and 7 queued; Gaps 4 and 1
deferred until a second service / second person is real (Gap 1 phase-1
identity fields may land any time).
**Because:** Gap 6's test guards every later change; Gap 2 has highest doc
leverage with no design controversy; 4 and 1 can't be honest without a real
second service/person (simplicity guardrails).
**Rejected:** different order — no gap had a stronger claim to go first than
the test that guards the rest; verdicts-only-no-build — user wants the
green-lit gaps started now.
**Blast radius:** scripts/tests/ (new template-eval suite), Z0 doc templates
(SPEC.md/system-design.md area), backlog card M15.
**Promote?:** no — sequencing choice, reversible per gap.

## 2026-08-08 — Fate of usage-scenarios.html
**Chose:** Supersede usage-scenarios.html with the markdown E-catalog
(scenarios.md §3): promote §1/§1b/§1c to a committed zoom-model doc, retire
the HTML to the archive with a pointer. No generated-view machinery.
**Because:** the catalog already supersets the HTML's S1–S6 scope, markdown
is agent-editable with targeted reads, and keeping both guarantees drift.
**Rejected:** keep both (HTML canonical for S1–S6) — drift risk plus three
stale `work/<user>_` references; generated HTML view — machinery with no
consumer.
**Blast radius:** docs/usage-scenarios.html (retire), docs/zoom-model.md or
workspace-structure.md section (new), pointers in CONTEXT.md/docs index.
**Promote?:** maybe — promote to an ADR when Gap 7 executes, if the
supersede proves contentious.

## 2026-08-09 — Fate of the work directory at close-out (session 6)
**Chose:** Keep `work/usage-scenarios/` in maintenance mode (README banner,
launcher replaced with a maintenance note) rather than delete or archive it.
**Because:** committed docs (docs/README.md index, zoom-model.md, the
archived HTML's supersede banner) point into `scenarios.md` §3 as the
canonical external-scenario catalog — deleting the directory breaks those
links; archiving the catalog elsewhere would just move it away from the
conventions that reference it.
**Rejected:** delete the dir (breaks committed links); promote scenarios.md
into docs/ (churns every pointer for zero reader benefit, contradicts the
work-directory convention that active artifacts live where they grew).
**Blast radius:** work/usage-scenarios/README.md + next-session.md only.
**Promote?:** no — housekeeping, reversible.
