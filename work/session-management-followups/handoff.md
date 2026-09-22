<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on
TOP. Each "# Session Handoff" block records what happened in one session.
Read the TOP block only; older blocks are in handoff-archive.md. Forward
"what to do next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->


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

# Session Handoff — 2 (2026-09-22): ticket 01 done — attach-session.sh and the statusline read the owner from the record (M40)

**Summary.** First loop session (hands-off, supervised). Ticket 01 landed in
e7c2356: `scripts/lib/session-lib.sh` gained two readers
(`session_record_owner`, `session_owner_live` — pid running and `pid_start`
match, artifact age when there is no pid); `attach-session.sh` and
`statusline-context-budget.sh` source the lib and keep their output shape;
the `link-local-work.sh` comment example corrected. Suites rewritten onto
record fixtures (live/dead/recycled/ended owners; a stray `.active-session`
file proven inert); lib contract tests O1–O4. Backlog M40 opened and resolved
(archived; Resolved count 91). Decision note appended to `decisions.md`.
Full suite, `test-check-ledger.py`, and `check-workspace-structure.sh` green
before the commit. Rolled at WARN (124K) right after the ticket's commit.

**Findings.** `docs/context-budget.md` has no lock-based prose for either
script (grep of both names), so the ticket's doc step was a no-op. The
ticket's acceptance line "grep hits only `import-session-seq.sh` and its
test" is stricter than its own stray-file test allows; every remaining hit
under `scripts/` is a deleter or a test proving the file inert (noted in the
ticket). `context-budget.sh` keeps its own `owner_live()` copy of the rule —
follow-up candidate, outside this item's scope.

**Decisions.** Readers in the lib, `context-budget.sh` untouched, output
shape (`locked=`, "work-item lock" message) kept — `decisions.md` 2026-09-22.

**Learnings:** the ticket's setup reads (ticket + both scripts + lib + both
suites + backlog format) cost ~70K before the first test was written; the
successor should read the ticket and only the files it names, in that order.

**Open / next.** Ticket 02 (`issues/02-one-ledger-heading-rule.md`). main is
ahead of origin; not pushed (the human's call).
