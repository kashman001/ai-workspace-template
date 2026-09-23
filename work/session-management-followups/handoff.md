<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 4 (2026-09-22): ticket 03 done — TEMPLATE_VERSION marks the template generation a workspace was cut from (M42); item complete

**Summary.** Third loop session (hands-off, supervised; the human interjected
mid-ticket to have `work/jev-integration/` scaffolded — done in 54b6d01,
separate commit, then this ticket resumed). Ticket 03 landed in 523bf54: root
`TEMPLATE_VERSION`, `#` comment lines plus one ISO-date value line
(`2026-09-22`), bumped by the template maintainer at each release, read by
nothing. Named in `docs/template-usage.md` (new §6 "Upgrading later";
Reference renumbered §7) and the `docs/workspace-structure.md` tree. New suite
`scripts/tests/test-template-version.sh` (V1–V3): exists and parses, both
docs name it, survives the §5 prune — the wholesale command is lifted from
the doc, run in no-git form on a `git ls-files -co` copy of the working tree
so the suite is green before the commit. Red 3/9 before the file existed,
green 9/9 after. Backlog M42 opened and resolved (archived; Resolved 93).
Decision note first, as the ticket asked. All shell suites, the ledger test
(26/26) and `check-workspace-structure.sh` green before the commit; 52K at
register, ~114K at the ticket's record. All three tickets `done`; item
closed through the stop door.

**Decisions.** Shape assumed, not chosen by the human: ISO date over
integer/semver; visible ALLCAPS root file over a dotfile or a key in
`context-budget.env`/`CONTEXT.md`; comments allowed so the file explains
itself after the usage doc is pruned — `decisions.md` 2026-09-22 (top note),
with the reversal path. Not wired into `check-workspace-structure.sh` or
`setup.sh` (the ticket: read by nothing yet).

**Findings.** `docs/setup-guide.html` is hand-maintained, not rendered from
`docs/template-usage.md` (`build-guide-html.sh` renders only
`workspace-structure.md`), so the new §6 is not in the HTML guide —
pre-existing drift, left alone. The `workspace-structure.html is stale`
warning persists (still a warning).

**Learnings:**
- A suite that must be green before the commit cannot clone HEAD; `git
  ls-files -co --exclude-standard -z | tar -c --null -T - -f - | tar -x -C
  <dir> -f -` copies exactly what a clone would hold plus the uncommitted
  work, and nothing gitignored.
- Lift a documented command out of the doc (`grep -m1 '^git rm -r '`) rather
  than restating it in the test, so the test follows the doc when the list
  changes.
- The ledger checker takes the first `session N` in a heading's title as the
  block number: a date-only scaffold heading must not say "session 1 is next".

**Open / next.** Nothing — item complete. main is 6 commits ahead of
`origin/main` after this session's commit; not pushed (the human's call).
The `jev-integration` item is scaffolded and waits for its first session.

# Session Handoff — 3 (2026-09-22): ticket 02 done — one ledger-heading rule shared by check-ledger.py and the launcher's parser (M41)

**Summary.** Second loop session (hands-off, supervised). Ticket 02 landed in
8a14af3: the rule is stated once in `docs/work-directory-conventions.md` →
Ledger ("One heading rule, two parsers"); `check-ledger.py`'s comment and
`top_ledger_session` in `launch-next-session.sh` cite it; the shell parser
now requires the checker's strict opener (`# Session Handoff`, optional
grandfathered `addendum`, then a dash) before extracting a number.
`test-check-ledger.py` gained 13 heading fixtures run through both parsers
(the checker via its CLI plus `parse_heading`; the launcher via the function
extracted with awk). Red on the old launcher with two disagreements (numbered
addendum: checker 23, launcher none — the session 22 refusal; doubled-space
opener: checker rejects, launcher 76), green after. Backlog M41 opened and
resolved (archived; Resolved 92). Decision note in `decisions.md`. All shell
suites, the ledger test (26/26) and `check-workspace-structure.sh` green
before the commit. 58K at register (the runtime's own overhead); ~95K at the
ticket's commit.

**Decisions.** The addendum form stays as grandfathered history instead of
being dropped as the ticket recommended: M36's downstream ledger (session
166) still carries one, and the checker's rule is never to rewrite history —
`decisions.md` 2026-09-22 (top note).

**Findings.** `check-workspace-structure.sh` warns `docs/workspace-structure.html
is stale — run scripts/build-guide-html.sh`; pre-existing (this session did
not touch `workspace-structure.md`), left alone. Importing `check-ledger.py`
from the test wrote `scripts/__pycache__/`; the test now sets
`sys.dont_write_bytecode` before the import.

**Learnings:**
- Before dropping a grandfathered form, read the archived card that
  introduced it (M36 here): the ticket's "no remaining use" described
  producers, not the downstream histories the gate exists to protect.
- A shell function inside a script that runs top-level code is testable by
  extracting it with `awk '/^name\(\) \{/,/^\}/'` and running the text in
  `bash -c` — no need to source the script.

**Open / next.** Ticket 03 (`issues/03-template-version-marker.md`), the one debatable ticket:
decision note first, build under a stated assumption. main is 4 commits ahead
of origin after this rollover's commit; not pushed (the human's call).
