<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 3 (2026-10-08)

**Summary.** Filed the seven accepted recommendations as Open cards in
`docs/template-workspace-backlog.html`: R1 → M46, R4 → M47 (Medium: real
gaps), R2 → L66, R3 → L67, R5 → L68, R6 → L69, R7 → L70 (Low: doc/config
nudges). Each card cites `eval.md` with its R-number and scorecard row, and
its change type. Open count 0 → 7. Nothing built.

**Decisions.** Severity: R1 and R4 are Medium because each is a defect that
exists today (Codex can fire manual-only skills; CI skips pass silently).
The rest are Low. Rejected: all seven as Low, which would hide the two
defects among advice.

**Current state.** Item finished. README success criterion marked done,
`eval.md` records the card IDs and the answer, `work/README.md` row closed.
R1 evidence re-checked at HEAD (same six skills lack `agents/openai.yaml`).
`scripts/check-drift.sh`: only the pre-existing ADR-history WARN.
Side note: IDs `L19` and `L20` each appear twice across the backlog files
(pre-existing, not touched).

**Suggested skills.** `tdd` for M46/M47; `writing-for-agents` before L66,
L67, L70.

**Key files.** `docs/template-workspace-backlog.html` (M46, M47, L66–L70),
`work/deep-seek-harness-eval/eval.md`.

# Session Handoff — 2 (2026-10-08)

**Summary.** Wrote `eval.md`: a 45-row scorecard (Already have 14 · Partial 11
· Worth adopting 4 · Not for us 16), a plain-language one-page summary with
glossary, and seven ranked recommendations R1–R7, each tagged doc, script or
config change. Template evidence was checked on disk with targeted greps.
Upstream was not re-opened.

**Decisions.** R1 ranks first because it is a real gap found on disk: six
workspace-native manual-only skills (`create-work-item`, `doc-review`,
`onboard-repo`, `plans`, `research-wave`, `rlm`) set
`disable-model-invocation: true` but have no `agents/openai.yaml`, so Codex
may invoke them unprompted. Rejected: ranking the "report what you ran" rule
(R2) first. It has the widest reach, but it is advice, not a found defect.

**Verdict.** The user accepted all of R1–R7 and gave no rejections, so
`decisions.md` gets nothing. Carding was left to session 3, because this
session reached budget WARN (125K) right after the verdict.

**Current state.** `eval.md` committed. README Files list updated. No backlog
cards yet: R1–R7 are accepted, and session 3 cards them.
`scripts/check-drift.sh` shows only pre-existing WARN lines (ADR history
paths). Unrelated uncommitted `scripts/` edits belong to another session;
left alone.

**Suggested skills.** `decision-log` for rejections; `writing-for-agents`
before carding anything that touches `skills/`.

**Key files.** `work/deep-seek-harness-eval/eval.md`.
