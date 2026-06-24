---
description: Wrap up the current chunk of work and emit a post-/compact catch-up prompt
argument-hint: "[next-focus, e.g. 'Phase 3 Trends'] (optional — inferred from the backlog/active work if omitted)"
---

You are at a **checkpoint between major chunks of work**. The user wants to wrap up what just shipped and
prepare a clean hand-off into the next chunk — so they don't retype this each time.
Next focus (optional): **$ARGUMENTS**

Do these in order, concisely (reference artifacts by path — do NOT duplicate plans/specs/diffs):

1. **Reconcile the record.** Make sure what just shipped is reflected in:
   - the project's **issue tracker / backlog** — per `docs/agents/issue-tracker.md` if the Matt Pocock skills
     were set up, otherwise the repo's own tracking convention (GitHub Issues, a `BACKLOG.md`, `.scratch/`,
     etc.). Mark finished items `Done` (date + how / PR + any deploy versions); add newly-discovered work.
     If committed docs change, follow the repo's branch/PR pattern — don't push to the default branch unless
     that's the convention.
   - **project memory** (the Claude Code per-project memory dir, `~/.claude/projects/<project-id>/memory/`) —
     update the running-arc memory and add durable, non-obvious learnings (gotchas, decisions, preferences);
     update `MEMORY.md` pointers.
   - the matching **reference docs** under `docs/` if a feature shipped or changed.

2. **Write a hand-off doc** for the next chunk: invoke the `handoff` skill (secret-free, with a
   suggested-skills section). Persist it under `work/<username>_<project-name>/` (the workspace convention) or
   the skill's default location. Frame it around the next focus above, or — if none given — the next item in
   the backlog's active sequence. Reference the spec/plan/runbook by path.

3. **Confirm repo/branch state** is clean and recorded: current branch, working tree clean, merged branches
   tidied or noted. If the project deploys, record the live deployment versions too.

4. **Emit a ready-to-paste post-`/compact` catch-up prompt** in a fenced block — it must name the hand-off
   doc path and tell the next session to catch up + continue the next chunk with the right starting skill
   (usually `superpowers:brainstorming`). Keep it ~3–5 lines.

End by telling the user: run `/compact`, then paste the catch-up prompt to continue. Keep the whole response
tight — this is a transition, not a status essay.
