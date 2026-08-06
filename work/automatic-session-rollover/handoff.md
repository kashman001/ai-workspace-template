<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-05 (session 4: documentation phase shipped in one commit; WARN rollover into implementation phase)

Executed the session-3 launcher's documentation plan verbatim; no design was
reopened. Substance is in the committed docs themselves; this block is
provenance only.

- One commit, `9c6a097`, pushed to main: `docs/context-budget.md` gained
  "Rollover trigger policy" / "Relaunch knobs" / "Multi-session model"
  sections (each with an explicit design-accepted-implementation-pending
  status note) and corrected stale copilot-cli "unverified" claims (smoke
  test verified 73.0k exact); knob block landed in `context-budget.env`
  (`ROLLOVER_RELAUNCH=manual`, `ROLLOVER_RUNTIME=claude`);
  `skills/session-rollover/SKILL.md` gained hybrid trigger semantics, the
  hook-less cadence fallback (~10 exchanges), and the relaunch closing step
  (graceful when the script is absent); pointer lines in `CONTEXT.md` +
  `docs/workspace-structure.md`; ADR-0004 companion promoted from the three
  session-3 notes (Promote? fields flipped; ADR-0003 got a Refined-by link);
  `issues/01-vscode-agent-mode-hooks.md` ticket created; backlog card M13
  (registry-clobber bug, Open with approved fix) + scorecard updated.
- Doc-phase decision recorded in `decisions.md` (newest note): one companion
  ADR-0004, not an amended 0003 or four ADRs.
- Ops note: `workspace-structure.md`'s scripts tree already lists planned
  entries (`scripts/tests/` doesn't exist on disk), so the
  `launch-next-session.sh` tree line landing pre-implementation is consistent;
  `check-workspace-structure.sh` iterates existing scripts only.
- WARN (122.7K) fired at commit time; user approved rollover. Docs summary was
  presented; user raised no objections before approving — treat the doc set as
  baseline unless they say otherwise.

Suggested skills for the next session: `superpowers:writing-plans` or `tdd`
(implementation of the registry migration), `decision-log`,
`session-rollover` at the boundary.

---

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

*Older blocks: `handoff-archive.md`.*
