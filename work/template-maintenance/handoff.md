<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 15 (2026-08-31): options brief for the 5 open design-gap cards; blocked on user direction

**What got done (worktree branch tm-s15-options-brief):**
- Ran unattended; per the session-15 mission, did NOT design conventions
  solo. Wrote `open-cards-options-brief.md`: per-card proposed shape,
  landing place, and open questions for M27 (testability prompt), M28
  (UAT/beta), M29 (postmortem), L38 (dep/suite health — recommendation:
  route into `work/quality-gates/`), L39 (generic backlog — extract vs.
  declare bring-your-own-tracker).
- No code, test, doc, or backlog changes. Suites untouched (21 green as
  of s14); backlog still 5 open / 77 resolved.

**State:** blocked on user input — every card needs its open questions
answered before building. Next session walks the brief with the user.

# Session Handoff — 14 (2026-08-31): M16 delivered — id-keyed artifact resolution survives EnterWorktree relocation

**What got done (committed on worktree branch tm-s14-m16, commit 6152b8d):**
- Fixed M16 (twice-bitten wrongful stale-primary sweeps), test-first:
  - New `glob_artifact_for()` in `scripts/context-budget.sh` — resolves
    `~/.claude/projects/*/<sid>.jsonl`, newest match wins over a stale
    copy left at the old path.
  - `claude_discover` uses it (register-side, no sibling bind after a
    move); `resolve_session` adopts a fresher match at check/record and
    re-pins the registry record (loud note); `lock_holder_age` trusts
    the freshest of recorded path + glob, so acquire/sweep/release
    liveness survives relocation; relocated-AND-idle still reads stale.
- Tests M16a–i (relocated-artifact fixture) in
  `test-context-budget-registry.sh` — 9 red pre-fix, 122/0 after; all
  21 suites green. Verified live on this session's own relocated record.
- Docs: `context-budget.md` lock-liveness paragraph; backlog M16 →
  archive Resolved with Fixed: note; scorecard 5 open / 77 resolved.
- Decision (Tier 2, decisions.md): id-keyed glob at every read over a
  worktree-entry re-register hook.

**State:** delivery complete on the worktree branch; launch will
ff-push it to main (launcher self-heal). Backlog 5 open / 77 resolved —
all remaining cards are convention/doc design gaps (M27 testability
prompt, M28 UAT, M29 postmortem, L38 dep/suite health, L39 generic
backlog), each benefiting from user input on shape. No follow-ups from
the M16 work. WARN fired mid-delivery; rolled over after the unit closed.

# Session Handoff — 13 (2026-08-31): M35 delivered — lineage-gate auto-heal, notify-on-quit, two-doors docs; arc complete

**What got done (all committed & pushed to main, worktree tm-s13-exitux):**
- Implemented exit-ux-plan.md in full, test-first, no design deviations:
  - `launch-next-session.sh` lineage gate splits the one-ahead case:
    no-trace → auto-heal (reclaim number, continue); evidence (records
    since seqf mtime / commits / dirty work item) → exit 3 with diagnosis +
    Reconstruct guidance + seq-sync alternative. Other mismatches die
    verbatim as before.
  - `session-loop.sh`: `top_ledger_seq()` helper + ledger-aware `notify`
    on the deliberate-quit path (recorded quit vs "quit WITHOUT a rollover
    or checkpoint" vs generic).
  - Docs: "How a session ends: two doors" in work-directory-conventions.md;
    context-budget.md gate + quit-notify paragraphs; CONTEXT.md pointer.
- Tests: T23e-j reworked (evidence keeps refusal), T24a-h added (heal
  dry/real, record/commit/dirty evidence — git cases in an isolated mini
  workspace), N1-N3 added. Two existing D5b cases adapted (quit now
  notifies): D5b-d asserts no STALL message instead of empty log; D5b-g's
  slow hook fast-paths "chain ended" so its timing margins still measure
  only the alarm reap. Suites: launcher 221/0 (was 207), loop 76/0 (was
  68); check-workspace-structure.sh clean.
- Backlog: M35 filed Resolved (archive Medium section); scorecard 76
  resolved, dated 2026-08-31.

**State:** arc complete; backlog 6 open / 76 resolved. No follow-ups from
this session. Context WARN fired during final verification; closed out
normally (checkpoint door).

