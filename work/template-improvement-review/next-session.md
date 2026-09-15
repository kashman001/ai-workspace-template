# Next Session — template-improvement-review (session-management review: user reviews Part 2 → Stage 3 on go)

> **This file is the LAUNCHER (catch-up prompt).** Forward-only, REPLACED at
> each rollover. Past-tense provenance lives in `handoff.md`.
> Convention: docs/work-directory-conventions.md.

## Mission

**Support the user's review of Part 2 (the design).** The user will read the
design and ask clarifying questions as they go; answer them from the files
(grep the cited lines; never guess), and record any decision they make as a
Tier-2 note (`/decision`) and, where it changes the design, edit Part 2 in
place with the date. Do not start Stage 3 unasked. On the user's explicit go,
run Stage 3 as described under "Stage 3 recipe" below.

Four-stage process (user, 2026-09-14): (1) research/evaluate ✔ → (2) design
✔ drafted → (3) evaluate design ← after the user's review → (4) plan.

**No-human-in-the-loop clause:** this mission IS the conversation. If nobody
answers, present the URLs (First actions step 3), stop, and wait. Do not
dispatch Stage 3 agents, do not edit the design, do not roll over on your own.

## Read these, in order

1. `work/template-improvement-review/session-management-review-findings.md`
   — status header (lines 1–25) and Part 1b §1b.5 + §1b.7 (the 17 accepted
   decisions and the reliability constraint). Read **Part 2 (lines ~373–681)
   by section on demand** as the user asks about it; do not load it whole
   unless a question spans it.
2. `work/template-improvement-review/evaluation/stage2-probes.md` — the probe
   evidence Part 2 cites (V2 ROTATES; `--bg` env captured and replayed).
3. `work/template-improvement-review/handoff.md` — top block only.
4. For Stage 3 only: `evaluation/stage1-architect-review.md` §7(c)/(d) and
   `evaluation/stage1-scenario-evaluation.md` §B/§D.

## Do NOT reload

`review.md`, `decisions.md` (append only), backlog HTML whole, the big scripts
whole (grep the cited lines only), `stage1-reevaluation-vs-main.md`,
`skills/session-rollover/SKILL.md` until you actually roll over.

## State snapshot

- `main` = session-7 commits on top of dfd2d58; clean after this rollover's
  commit; ahead of origin by local commits only (do not push).
- Supervisor pid 72900 live on pre-a213b3d `session-loop.sh` code (hazard).
  Do NOT edit `session-loop.sh`; decision 12 applies before any edit.
- No code changes yet. F10 small defects remain for Stage 4's first phase.
- Review artifact published (private): see step 3.

## First actions

1. `scripts/context-budget.sh register --project template-improvement-review`
2. Read inputs 1–3.
3. **Open by presenting the review documents to the user**, verbatim:
   - Rendered page (Part 2 + probe appendix, private):
     https://claude.ai/artifact/4KeTb5seRPdSS8AtEKQmmV
   - Source: `work/template-improvement-review/session-management-review-findings.md`
     Part 2 (from the `# Part 2` heading, ~line 373) and
     `work/template-improvement-review/evaluation/stage2-design-part2.md`
     (standalone copy); probe evidence
     `work/template-improvement-review/evaluation/stage2-probes.md`.
   - Remind them of the five open questions in Part 2 §(m) and that Stage 3
     starts only on their go. Then STOP and wait for questions.
4. Answer review questions; log decisions; edit Part 2 in place if the user
   changes something (dated). Every ~10 exchanges run
   `scripts/context-budget.sh record --label "review Q&A"`.

## Stage 3 recipe (only on the user's explicit go)

Dispatch two agents in parallel, same shape as Stage 1 (each returns a
≤600-word summary + a report under `evaluation/stage3-*.md`; parent reads
summaries only): (1) a fresh architect agent — AGREE/AMEND/REJECT per Part 2
section with reasons, hidden couplings, simplicity; (2) a scenario/flow agent
— per-scenario YES/PARTLY/NO over S1–S10 / E / I and walks of the three loops
(measure / rollover / supervise) against Part 2. Give each Part 2, inputs 2
and 4, §1b.5/§1b.7, the §(m) questions and any user decisions from the
review. Synthesize into **Part 3** appended to the findings file, apply
accepted amendments to Part 2 in place (dated), `record --label "Stage 3
evaluation done"`, commit, STOP for the user's go on Stage 4.
