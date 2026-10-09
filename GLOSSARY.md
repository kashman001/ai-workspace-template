# <workspace-name> — Glossary

The project's domain language: resolved terms and the aliases to avoid. The
vendored `domain-modeling`, `grill-with-docs` and `improve-codebase-architecture`
skills read and write this file (format: `skills/domain-modeling/GLOSSARY-FORMAT.md`).

## Language

<!-- TODO: Keep terms tight and project-specific; general programming
concepts don't belong. -->

- **<term>** — <one-line definition; note aliases to avoid>

Plan vocabulary — ships with the template, shared by every skill that touches
a plan (reference: `docs/plans.md`; aliases to avoid in italics):

- **Work item** — `work/<item>/`, the durable home of an effort; a plan lives
  inside one. *Not "worktree"* — a git isolation mechanism the plan never names.
- **Plan** — a dependency graph of work for one work item, one markdown file
  per node under `work/<item>/plans/NN-<slug>/`; open or closed, never moved.
  *Not "runner", "workflow", "map".*
- **Node** — one unit of work, one file, sized to one session's budget; its
  `kind` is `work`, `reconcile`, or `hitl`. *Not "task", "ticket", "step" in
  plan files.*
- **Wave** — the nodes sharing a `wave:` number; they may run in parallel
  inside one session, and waves run in order.
- **Reconcile node** — `kind: reconcile`, exactly one per wave and last in it:
  joins results, verifies on disk, records decisions, replans. *Not "join",
  "sync", "gate" in plan files.*
- **HITL node** — `kind: hitl`, a step only a person can complete; has no
  `check`, a person marks it done.
- **Check** — the node's `check:` shell command, exit 0 is pass; also
  `plan.sh check`, the lint that refuses a malformed plan.
- **Tier** — what runs a node: `frontier`, `standard`, `cheap`, or `auto`
  (resolved through `plan-tiers.env`); no model name ever reaches a plan file.
- **Frontier** — the `todo` nodes whose blockers are all `done` or `dropped`,
  in the lowest unfinished wave; derived by `plan.sh frontier`, never stored.
  Also the name of the strongest tier.
