# 04 — Trim CONTEXT.md toward the Z0 budget (L51)

**What to build:** bring `CONTEXT.md` from ~20.5 KB (~5K tokens) to about
≤16 KB (~4K tokens), so it sits inside `docs/zoom-model.md`'s 2–5K Z0 band
with room to spare. Move detail that already has a home doc behind a
one-line pointer. Candidates: the long "Context Budget" section
(`docs/context-budget.md`), the vendored-skills paragraph
(`skills/vendored-skills.md`), and the longer skill one-liners. Keep
everything an agent must see without being prompted: the onboarding canary,
the symlink edit warning, Agent Context Discipline, decision-record tiers,
the `ROLLOVER_RELAUNCH=auto` standing authorization, the plan glossary, and
the Template Backlog rule. Don't add dates or status text (ticket 01's
rule).

`scripts/tests/test-doc-consistency.sh` and `test-agent-entrypoints.sh` pin
some `CONTEXT.md` content. Read what they assert before cutting anything.
Background: `work/context-memory-eval/eval.md` → C4, recommendation 4.

**Blocked by:** 01 (its pointer line lands in `CONTEXT.md` first).

**Status:** done

- [x] `wc -c CONTEXT.md` ≤ ~16000; before/after sizes in the commit body
- [x] Every removed passage has a pointer to the doc that now owns it, and
      that doc actually contains it (grep each one)
- [x] Onboarding canary still in place (`test-agent-entrypoints.sh` green)
- [x] Backlog card resolved in the same commit: badge → Resolved, `Fixed:`
      line with the commit, card moved to the matching section of
      `docs/template-workspace-backlog-archive.html`, scorecard and "Last
      updated" changed, change-log row added
- [x] All `scripts/tests/test-*` suites green; `scripts/check-workspace-structure.sh` exit 0
- [x] One commit, `Fix <ID>: …`, with a `Decision:` trailer

**Done (2026-10-07, session 3).** 20,656 → 15,206 bytes. Five sections cut
behind pointers: Workspace Skills, Service Access, Tool & Context Loading,
Context Budget, graphify. Each target doc was grepped and holds what was cut.
Other sections are untouched.
