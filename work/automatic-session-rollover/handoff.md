<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-05 (session 3: ALL open questions closed; research + smoke tests landed; user-directed rollover into documentation phase)

Design discussion is COMPLETE. Every open question is closed and recorded;
substance lives in `relaunch-analysis.md` (open-questions section, final
state), `decisions.md` (three new Tier-2 notes), and the three research docs.
This block is provenance only.

- Closed with user: #1 multi-session identity redesign approved (operating
  model: one developer, N concurrent sessions, one per work item); #2 knobs
  (`context-budget.env`, off/manual/auto, `manual` default); #3 all four hook
  deployments in scope (smoke tests collapsed the deferral rationale); #4
  launcher covers all five runtimes seeded-interactive, background claude-only.
- Research delivered (background agents): `vendor-hooks-research.md` (all
  four runtimes PUSH-CAPABLE — the "agent discipline only" matrix rows were
  stale); `smoke-test-opencode.md` (opencode 1.18.14 installed; chat.message
  injection CONFIRMED live, part shape trap documented; sqlite token store);
  `smoke-test-copilot.md` (copilot CLI 1.0.78 installed; hooks CONFIRMED
  live; `copilot -i` seeded-interactive REFUTED the headless-only claim;
  VS Code agent mode ships hooks since v1.109, Preview, reads our formats —
  live verification is the one spun-out ticket).
- Machine state changed: opencode (brew) + copilot CLI (npm) now installed;
  scratch test dirs under the session scratchpad; a stray `$schema` line
  opencode auto-added to `.opencode/opencode.json` was reverted.
- Next phase (user-agreed sequence): documentation first, then
  implementation. See `next-session.md`.

Suggested skills for the next session: `writing-for-agents` (doc edits),
`decision-log` (promotions to the ADR-0003 family), `checkpoint` or
`session-rollover` at the boundary.

---

# Session Handoff — 2026-08-05 (session 2: design discussion — hybrid settled, ADR-0003, codification walkthrough, multi-session redesign proposed; WARN rollover)

Same calendar day as session 1, fresh context. All substance lives in
`relaunch-analysis.md` (written incrementally — effective write-ahead) and
ADR-0003; this block is provenance only.

- Settled with user: consent axis reframe; hybrid trigger (WARN asks, STOP
  automatic); dying agent conducts rollover; write-ahead on declined WARN;
  answer-then-rollover as discussion atomic step; D1–D8 local-vs-LLM verdicts
  + conductor state machine.
- ADR-0003 promoted (user-directed) from a Tier-2 note; committed + indexed.
- User challenged D6 (global active-project state) → multi-session identity
  redesign proposed (session-keyed state + per-project advisory lock);
  **awaiting user verdict** — the successor's first question.
- The registry-clobber bug fired live mid-session (record measured the dead
  demo session); evidence in the analysis, workaround in
  docs/operational-knowledge.md.
- Commits this session: 506a68e, 8e2ac7d, 8eabdb0, 56dc888 + the rollover
  commit; all pushed to main.

---

*Older blocks: `handoff-archive.md`.*
