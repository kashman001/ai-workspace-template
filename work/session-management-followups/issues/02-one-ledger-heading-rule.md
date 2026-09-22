# 02 — One ledger-heading rule shared by the checker and the launcher

**What to build:** `scripts/check-ledger.py` (`HEAD` regex, line 59) accepts
`# Session Handoff addendum — N (date): …`; the launcher's shell parser
`top_ledger_session` (`scripts/launch-next-session.sh:352`) does not, so a
ledger the checker passes made `--emit` refuse `ledger_shape` (session 22 of
`template-improvement-review`). The addendum form existed only because an
attended `register` after a stop-door close re-bound the closed number; M39
(aa25002) mints the next number instead, so the form has no remaining use.
Recommended: drop the addendum form from `check-ledger.py` and its test
(`scripts/tests/test-check-ledger.py`, the "addendum heading" mutation), and
state the single rule in one place in `docs/work-directory-conventions.md`
(the ledger header block) that both parsers cite. Rejected alternative to
record: teaching the shell parser the addendum form. Either way the two
parsers must agree, proven by a test.

**Blocked by:** nothing (do after 01 so one session does not carry both).

**Status:** todo

- [ ] Fixture set of headings (plain numbered, dated-with-session, addendum,
      malformed) run through both `check-ledger.py` and `top_ledger_session`;
      failing test shows the disagreement first
- [ ] Both parsers agree on every fixture; the existing 13 ledger mutations
      still caught (minus the one that the dropped form makes moot, if dropped)
- [ ] Rule stated once in `docs/work-directory-conventions.md`; Decision note
      in `decisions.md`; backlog card opened and resolved in the same commit
- [ ] All suites green; `Decision:` trailer on the commit
