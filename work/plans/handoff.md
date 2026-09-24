<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 3 (2026-09-24): ticket 01 landed — `plan.sh` new / show / status, fixture, tests, docs/plans.md

**Summary.** Seq 3, supervised chain, hands-off. Implemented ticket 01
test-first at the one agreed seam (the command line): fixture plan
`scripts/tests/fixtures/plan-01-concept/` (the concept's worked example, nine
nodes), `scripts/tests/test-plan.sh` (49 assertions: usage, status text and
`--json`, show, refusals naming the file, `new` numbering and refusal,
plan and project resolution incl. the registry binding via an ancestor pid
and a recycled-pid guard), then `scripts/plan.sh` (bash 3.2 + jq, ~170
lines). Full shell suite green. `docs/plans.md` started (format + verbs +
exit codes + resolution); indexed in `docs/README.md`. All five acceptance
boxes ticked; ticket status `done`.

**Choices made without a decision note (no rejected alternative worth
recording).** Wave names on the board ("1 ground") are not in any
frontmatter; the board renderer (ticket 05) will have to derive them, most
likely from the wave's reconcile-node slug — flag when 05 starts. `show`
parses the whole plan (cheap, keeps one loader). `isolated` is a JSON
boolean in `--json`. Inline `# comment` stripping needs whitespace on both
sides of the `#`.

**Verification.** `bash scripts/tests/test-plan.sh` → passed=49 failed=0;
every other `scripts/tests/test-*.sh` unchanged and green. shellcheck is not
installed on this machine — not run.

**Budget.** WARN reached right after the doc (~117K at the last record);
wrapped up here. Nothing pushed.

# Session Handoff — 2 (2026-09-23): grill closed, verdict BUILD, concept + spec + 11 tickets; rolled at WARN

**Summary.** Seq 2, supervised chain, launched interactive for the grill.
The user was present. Two grill rounds settled all seven open points
(recommended answers taken on every one; the user asked for plain-language
explanations on the Stop-hook and node-kind questions before deciding).
Landed: seven new notes in `decisions.md` (no "(proposed)" left; both OPEN
sections resolved in place), `concept.md` (definition, five properties,
glossary, this item as a worked plan in node-file form), README status line
= BUILD, `spec.md` (36 stable S-items, two testing seams: the `plan.sh`
command line and the existing session-loop fake-child harness), eleven
tracer-bullet tickets under `issues/` approved by the user as listed,
backlog card L48 (wayfinder as a plan template, deferred). WARN hit right
after the tickets; wrapped up here.

**Decisions this session** (why + rejected in `decisions.md`): build format
+ `plan.sh` + loop hook, no runner; `blocked` explicit / `done` verified
only; HITL nodes have no `check`, human tick, interactive rollover when only
HITL remain; `<!-- plan:begin/end <name> -->` markers; `kind: work |
reconcile | hitl`; integration = all parts except the Stop/SessionEnd hook;
wayfinder untouched in v1 (L48).

**State.** All of the above committed by this rollover. Branch main, nothing
pushed. Spec approved by the user in this session;
tickets are `ready-for-agent`. Frontier: ticket 01 only.

**Next.** `next-session.md` → implement ticket 01 with `implement` + `tdd`.

**Key files.** `work/plans/spec.md`, `work/plans/issues/01-*.md`,
`work/plans/concept.md`, `work/plans/decisions.md`.
