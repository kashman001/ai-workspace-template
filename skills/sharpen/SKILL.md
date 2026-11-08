---
name: sharpen
description: "Make a task deeper, not bigger, then rewrite the prompt. Use for /sharpen."
disable-model-invocation: true
---

<!--
Vendored from github.com/cursor/plugins — pstack/skills/sharpen/
at commit c742dd6 (2026-10-27). Everything below this comment is upstream
content. Refresh: scripts/sync-vendored-skills.sh (adapted
class — it preserves the frontmatter and this comment, re-copies the
upstream body + support files). Adapted: agents/openai.yaml is workspace-owned (Codex's user-invoked switch).
MIT — see skills/vendored-skills.md.
-->

I want a deeper version of this task, not a bigger one. Before rewriting it, do four things:

1. Say what a top professional in this field would do here that I'm not asking for.
2. Name the rawest material they would start from instead of what has already been digested for me.
3. Name the specific methods and tools they would use.
4. Say what, other than you or me, would show the result is right.

Then rewrite my prompt to ask for exactly that.

Leave choices that are mine to make open instead of deciding them.
