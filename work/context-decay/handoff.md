<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 2026-08-07 (session #4: trims declined, Warp attribution settled, inspector fixed)

**Ran as a background job (worktree `context-decay-s4`), user live mid-session.**

**Trim candidates (mission steps 1–2):** measured live (turn-1 = 43,855 exact).
skill_listing ~4,026 tok is only ~307 tok workspace-controlled (built-ins
~1,511 / user-global skills ~954 / plugins ~872); CLAUDE.md moderate pass
~600–800, aggressive ~1,000–1,300, all with real downsides (non-Claude
runtimes, downloaders, always-on behavioral rules). Full table:
`trim-estimates.md`. **User declined all trims** — bar was "unused AND no
negative implications"; decision note in `decisions.md` (2026-08-07). Don't
re-propose.

**Warp attribution (mission step 3): settled.** hook_success stdout/stderr
never enter model context; only the `content` field does (context-budget
SessionStart hook: content≈stdout and visibly in context; Warp PostToolUse/
Stop: content=0; superpowers SessionStart arrives as separate
hook_additional_context). Residual analysis over two Warp-heavy transcripts:
whole-JSON attribution → median residual −43/−14 with 57–73% turns negative;
content-only → uniform small-positive (median ≈ +155). Fixed both jq measure
sites in `scripts/context-inspect.sh` (hook_success now content-length);
verified: 136 Warp records drop to 0 tok, residuals all small-positive.
Backlog L31 (archive), scorecard 49.

**Learnings (parked):**
- Every session on this machine carries Warp plugin hooks — there is no
  non-Warp control session; residual-delta comparison within a session is
  the usable method.
- Backlog archive has pre-existing duplicate IDs (two L19s, two L20s from
  parallel passes; L-series otherwise runs to L30 — new cards start L31).

---

