# 03 — Last-confirmed dates and write classification for semantic stores (M43)

**What to build:** two lightweight mechanisms that stay plain-files and
agent-agnostic:

1. **Staleness signal.** Every entry in `docs/operational-knowledge.md` gets
   a `Last confirmed: YYYY-MM-DD` line. For an existing entry, use the date
   of the commit that last touched it (`git log -L` or blame). Do not
   invent dates. State the review age, for example 6 months, once at the top
   of the doc.
2. **Write classification.** Add a step to `skills/checkpoint/SKILL.md` and
   `skills/decision-log/SKILL.md` (the places that write these stores).
   Before appending to `operational-knowledge.md` or a `decisions.md`,
   grep for an existing entry on the same subject and classify the new item:
   **ADD** (new), **UPDATE** (edit the existing entry in place and bump
   Last confirmed), **SUPERSEDE** (mark the old entry retired and link
   forward; never delete), or **NOOP** (transient, don't write). Add a
   checkpoint step that lists entries past the review age for a person to
   look at. Nothing is auto-deleted.

Follow `writing-for-agents` (`skills/writing-for-agents/SKILL.md`) when
editing skills. Background: `work/context-memory-eval/eval.md` → C6, C7,
recommendation 3. Out of scope: numeric decay scores (D5 records why).

**Blocked by:** nothing.

**Status:** todo

- [ ] Every `operational-knowledge.md` entry carries a git-derived Last
      confirmed line; review age stated once
- [ ] Classification step in `checkpoint` and `decision-log` skills;
      stale-list step in `checkpoint`
- [ ] If a script lists stale entries: failing test first, then green
      (a doc-only change needs no script)
- [ ] Backlog card resolved in the same commit: badge → Resolved, `Fixed:`
      line with the commit, card moved to the matching section of
      `docs/template-workspace-backlog-archive.html`, scorecard and "Last
      updated" changed, change-log row added
- [ ] All `scripts/tests/test-*` suites green; `scripts/check-workspace-structure.sh` exit 0
- [ ] One commit, `Fix <ID>: …`, with a `Decision:` trailer
