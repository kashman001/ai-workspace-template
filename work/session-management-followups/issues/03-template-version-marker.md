# 03 — A workspace-level template version marker

**What to build:** a downstream workspace built from this template cannot tell
which generation of the template it carries; the only versioned thing is the
session record's `schema: 1`. The migration in `docs/context-budget.md`
("Migrating work items from the old scripts") works without one because the
files are self-describing, but future upgrades in general need a marker to
compare against. Design the smallest thing that answers "which template
version is this workspace on": one root file with a monotonic value (a date
or an integer), read by nothing yet, bumped by whoever cuts a template
release, and named in `docs/template-usage.md` beside the upgrade guidance.
The human has not chosen a shape; build it under a stated assumption and
record the assumption and the rejected shapes in `decisions.md` so the human
can reverse it cheaply. Do not build an upgrade tool; the marker only.

**Blocked by:** nothing (do last; it is the one debatable ticket).

**Status:** todo

- [ ] Decision note first: chosen file name and value scheme, the
      alternatives considered, and what the human would change to reverse it
- [ ] Failing test first (`scripts/tests/test-template-instantiation.sh` or a
      new small suite): the marker exists, parses, and survives the
      instantiation / prune path in `docs/template-usage.md`
- [ ] Marker shipped; `docs/template-usage.md` names it; `docs/workspace-structure.md`
      tree gains its one line; backlog card opened and resolved in the same commit
- [ ] All suites green; `Decision:` trailer on the commit
