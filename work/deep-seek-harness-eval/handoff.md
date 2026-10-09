<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

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

**Current state.** `eval.md` committed. README Files list updated. No backlog
cards and no `decisions.md` yet: both wait on the user's review of R1–R7.
`scripts/check-drift.sh` shows only pre-existing WARN lines (ADR history
paths). Unrelated uncommitted `scripts/` edits belong to another session;
left alone.

**Suggested skills.** `decision-log` for rejections; `writing-for-agents`
before carding anything that touches `skills/`.

**Key files.** `work/deep-seek-harness-eval/eval.md`.

# Session Handoff — 1 (2026-10-08)

**Summary.** Cloned upstream shallow into the session scratchpad (outside the
repo) at `5badb15009ae1756c3afe0ae0cef1faafc290ccc`; nothing upstream was run.
Read root `AGENTS.md` directly; three read-only subagents covered (A) the
Agent Notes system + doc rules, (B) the agent skills, (C) checks/CI/review
policy. Their notes were spot-checked against the clone (8 claims, all held)
and assembled into `source-notes.md` (424 lines). Rolled over proactively at
~100K, before WARN, because `eval.md` needs a full read of the notes.

**Decisions.** Delegated upstream reading to three parallel subagents to keep
this session's context lean (rejected: reading ~400 files inline).

**Current state.** `source-notes.md` written, uncommitted until this
rollover's commit. `eval.md`, `decisions.md` not started. Unrelated
uncommitted edits in `scripts/session-loop.sh`, `scripts/tests/test-plan.sh`,
`scripts/tests/test-session-loop.sh` belong to another session — left alone.

**Candidate themes for eval** (from the notes, not yet judged): decision-note
lifecycle by folder + format gate + frozen hash-sealed archive (vs our
`decisions.md`/ADR tiers); doc word budgets with a repair order (vs
`check-drift.sh` CONTEXT.md size); exact-shrinking ratchet baselines;
"report only commands run" + negative controls ("break it, watch it fail");
CoT-leakage skill (vs writing-for-agents, ledger hygiene); `.claude/skills`
symlink + cross-runtime invocation-metadata gate (vs `test-agent-entrypoints.sh`);
single gate graph with skipped = failed; scoped subtree AGENTS.md.

**Suggested skills.** none required; `writing-for-agents` when drafting
recommendations that touch `skills/`.

**Key files.** `work/deep-seek-harness-eval/source-notes.md`.
