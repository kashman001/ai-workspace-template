---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

<!--
Vendored from github.com/mattpocock/skills — skills/engineering/implement/
at commit 49dd158 (2026-10-09). Upstream content (MIT — see
skills/vendored-skills.md); keep this directory unmodified so refreshes
stay a clean re-copy: scripts/sync-vendored-skills.sh.
-->

Implement the work described by the user in the spec or tickets.

If the user passes a ticket reference, fetch it from the issue tracker and state its title before starting. If the reference is ambiguous, ask.

Call the Skill tool with "tdd" where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, call the Skill tool with "code-review" to review the work.

Commit your work to the current branch.
