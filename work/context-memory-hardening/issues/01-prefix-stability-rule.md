# 01 — Prefix-stability rule for always-loaded context (L49)

**What to build:** a short "Cache the prefix, vary the tail" section in
`docs/context-budget.md`, plus a one-line pointer from `CONTEXT.md` → "Tool
& Context Loading". The rule: always-loaded files (`CONTEXT.md`, the
`MEMORY.md` index) hold no dates, status, counters, or session-specific text.
Volatile state belongs only in launchers and ledgers, which are read as the
tail. Hooks that inject text print byte-stable output.

Then audit what each runtime's SessionStart-type hook prints into context.
Claude's `register` hook currently emits a status line that includes a
per-session `artifact=` path and `pct=`. Find out whether that text reaches
the model's context, and if it does, whether it sits in the cached prefix.
Make it stable or quiet where it does. Record the finding either way. As an
optional extra, add a `check-workspace-structure.sh` rule that flags
date-like lines (`20[0-9][0-9]-[01][0-9]-`) in `CONTEXT.md`. Leave it out if
legitimate content trips it; the "Last updated" strings in other docs are
not in scope.

Background: `work/context-memory-eval/eval.md` → C2, recommendation 1. Use
targeted reads only; don't load `docs/context-budget.md` whole.

**Blocked by:** nothing.

**Status:** done

- [x] Section added to `docs/context-budget.md`; pointer in `CONTEXT.md`
      (edit `CONTEXT.md`, never a symlink)
- [x] Hook-output audit result written in this ticket under `## Answer`
      (per runtime: what is printed, whether it lands in context, what changed)
- [x] If a structure-check rule is added: a failing test first, then green
- [x] Backlog card resolved in the same commit: badge → Resolved, `Fixed:`
      line with the commit, card moved to the matching section of
      `docs/template-workspace-backlog-archive.html`, scorecard and "Last
      updated" changed, change-log row added
- [x] All `scripts/tests/test-*` suites green; `scripts/check-workspace-structure.sh` exit 0
- [x] One commit, `Fix <ID>: …`, with a `Decision:` trailer

**Done (2026-10-07, session 2).** Rule in `docs/context-budget.md` →
"Cache the prefix, vary the tail"; pointer in `CONTEXT.md`; optional date
warning added to `check-workspace-structure.sh` (red, then green, in
`scripts/tests/test-context-prefix-stability.sh`). `CONTEXT.md` has no
date-like lines today, so the rule trips nothing legitimate. It warns
rather than fails, because a static date doesn't break the cache.

## Answer

Hook-output audit, per runtime (from `.claude/settings.json`,
`.codex/config.toml`, `.gemini/settings.json`, `.github/hooks/*.json`,
`.opencode/plugins/context-budget.js`, and the adapter table
`scripts/hooks/context-budget-adapters.conf`):

1. **Claude Code.** `SessionStart` runs `context-budget.sh register`, whose
   stdout goes into context: `runtime=claude method=deferred tokens=0 …
   pct=0 status=OK artifact=<per-session transcript path>` (plus the pending
   prompt on a `/clear` binding, which is meant to be read). Checked in this
   session's own transcript: it is attached after the first user message's
   git-status block and prompt, which already differ every session. So it
   never splits the prefix shared across sessions, and within a session it
   is written once and stays fixed. **No change.** `PostToolUse` speaks only
   on a WARN/STOP escalation (stderr, exit 2), which is tail text.
2. **Codex.** `UserPromptSubmit` registers via the agent; prints
   `additionalContext` only on escalation. Tail. No change.
3. **Copilot CLI.** `sessionStart` check hook: escalation only. No change.
4. **Copilot VS Code.** `SessionStart` registers itself with stdout to
   `/dev/null`, then speaks only on escalation. No change.
5. **Gemini.** `BeforeAgent` prints `{}` unless escalating. The graphify
   `BeforeTool` hook's text is a fixed string. No change.
6. **OpenCode.** `chat.message` plugin adds a part only on escalation.
   No change.

The eval's line "the hooks inject no varying text" was slightly wrong for
Claude Code (the `artifact=` path varies), but where that text sits makes
it harmless.
