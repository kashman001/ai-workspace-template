#!/usr/bin/env python3
"""
File: scripts/check-ledger.py
Purpose: Validate the shape of every work-item ledger (work/<project>/handoff.md
         and its handoff-archive.md) — block headings well-formed, none buried
         inside the purpose comment, newest-first ordering, archive continuity.
         Exits non-zero on any failure.
See: docs/work-directory-conventions.md → "handoff.md — the ledger"

The ledger is the provenance record this workspace runs on, and nothing gated
its shape: rollover tooling appends to it unattended, and in one instance two
of five recent blocks were misfiled in two different ways before anyone noticed
(a heading swallowed by an unclosed purpose comment, and a block left out of
order). Both are cheap to detect and expensive to find late.

Usage:
    scripts/check-ledger.py                 # every work/<project>/ ledger
    scripts/check-ledger.py work/foo        # just this one
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

GREEN, RED, YELLOW, RESET = "\033[32m", "\033[31m", "\033[33m", "\033[0m"


def rel(path: Path) -> str:
    """Path for display. Falls back to the absolute path outside the workspace
    (the mutation tests run against fixtures in a temp dir)."""
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)

# Several title conventions are in use and all are legitimate history —
# preferred for NEW blocks:
#       # Session Handoff — 76 (2026-08-22): what happened
# grandfathered (live in older ledgers; do not rewrite history):
#       # Session Handoff — 2026-08-22 (session 68, bg: what happened)
#       # Session Handoff — 2026-08-29 (session #8: what happened)
#       # Session Handoff — s201 (what happened)              [dateless]
#       # Session Handoff — 2026-08-07 (what happened)        [date-only]
#       # Session Handoff — 2026-08-22/23 (what happened)     [midnight span]
#
# Rather than one regex per form, parse tolerantly: the heading must open
# `# Session Handoff` plus a dash, and must yield a session number, a date,
# or both. A session number may carry a letter suffix ("74b") or a
# continuation word ("session 9 cont.") when one session wrote more than one
# block; a midnight-span date range orders by its first date.
HEAD = re.compile(r"^# Session Handoff\s*[—-]\s*(?P<rest>.*)$")
DATE_RE = re.compile(r"\d{4}-\d{2}-\d{2}")
# Number right after the dash ("76 (…", "74b (…", "s201 (…") — matched after
# stripping ISO dates so a year is never read as a session number…
LEAD_NUM = re.compile(r"^s?(?P<num>\d+)[a-z]*\b", re.IGNORECASE)
# …else "session N" / "session #N" anywhere in the title.
SESSION_NUM = re.compile(r"session\s*#?\s*(?P<num>\d+)[a-z]*", re.IGNORECASE)
# Explicit lineage-restart marker: a project that restarted its session
# numbering mid-history places this comment between the lineages (newer
# lineage above, older below). The number chain restarts at the next block
# below the marker; the DATE chain deliberately does not — archives stay
# chronological across the seam, so a misfiled date can't hide behind a
# marker. Rare by design; never add one to paper over an ordinary misfiling.
LINEAGE_RESTART = re.compile(r"<!--\s*ledger-lineage-restart:")


def parse_heading(rest: str) -> tuple[int | None, str | None]:
    """Extract (session number, date) from a heading's post-dash text."""
    dm = DATE_RE.search(rest)
    date = dm.group(0) if dm else None
    nodate = DATE_RE.sub("", rest).lstrip()
    nm = LEAD_NUM.match(nodate) or SESSION_NUM.search(nodate)
    num = int(nm.group("num")) if nm else None
    return num, date


class Block:
    """One `# Session Handoff` heading, located and parsed. Depending on the
    title form, `num` or `date` (never both) may be absent."""

    def __init__(
        self, path: Path, line_no: int, text: str,
        num: int | None, date: str | None, restart: bool = False,
    ):
        self.path = path
        self.line_no = line_no
        self.text = text
        self.num = num
        self.date = date
        # True when a lineage-restart marker sits above this block: the
        # session-number chain starts over here.
        self.restart = restart

    @property
    def describe(self) -> str:
        return f"session {self.num}" if self.num is not None else self.date

    @property
    def where(self) -> str:
        return f"{rel(self.path)}:{self.line_no}"


def parse_file(path: Path, report) -> list[Block]:
    """Return the file's blocks in document order, reporting shape failures."""
    blocks: list[Block] = []
    in_comment = False
    seen_block = False
    pending_restart = False

    for line_no, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.rstrip()

        if LINEAGE_RESTART.search(line):
            pending_restart = True

        # Track HTML-comment depth before classifying the line, so a heading
        # swallowed by an unclosed <!-- --> is caught rather than silently lost.
        opened = "<!--" in line
        closed = "-->" in line
        inside = in_comment or (opened and not closed)
        if opened and not closed:
            in_comment = True
        elif closed:
            in_comment = False

        if line.startswith("## ") and not inside and not seen_block:
            report.bad(
                f"{rel(path)}:{line_no} sub-heading before the first "
                f"session block — {line[:60]!r}"
            )
            continue

        if not line.startswith("# "):
            continue

        if inside:
            report.bad(
                f"{rel(path)}:{line_no} block heading is inside a "
                f"comment (unclosed purpose comment?) — {line[:60]!r}"
            )
            continue

        m = HEAD.match(line)
        if not m:
            report.bad(
                f"{rel(path)}:{line_no} not a well-formed session "
                f"block heading — {line[:70]!r}"
            )
            continue

        num, date = parse_heading(m.group("rest"))
        if num is None and date is None:
            report.bad(
                f"{rel(path)}:{line_no} session block heading yields "
                f"neither a session number nor a date — {line[:70]!r}"
            )
            continue

        seen_block = True
        blocks.append(Block(path, line_no, line, num, date, pending_restart))
        pending_restart = False

    if in_comment:
        report.bad(f"{rel(path)} ends inside an unclosed HTML comment")

    return blocks


def check_ordering(blocks: list[Block], report) -> None:
    """Newest first: session numbers and dates both non-increasing downward.

    Equal numbers are allowed — one session sometimes writes two blocks
    ("41, live continuation" above "41, background") — so this is
    non-increasing, not strictly decreasing.

    Some title forms carry only a number or only a date, so each key is
    checked independently against the nearest block ABOVE that carries it;
    a block missing a key is skipped for that key without breaking the chain.

    An explicit `ledger-lineage-restart` marker restarts the NUMBER chain at
    the block below it (dates keep checking across the seam — see the marker
    regex above).
    """
    prev_num: Block | None = None
    prev_date: Block | None = None
    for b in blocks:
        if b.restart:
            prev_num = None
        if b.num is not None:
            if prev_num is not None and b.num > prev_num.num:
                report.bad(
                    f"out of order: session {b.num} at {b.where} sits below "
                    f"session {prev_num.num} at {prev_num.where} "
                    f"(newest block goes on top)"
                )
            prev_num = b
        if b.date is not None:
            if prev_date is not None and b.date > prev_date.date:
                report.bad(
                    f"out of order by date: {b.date} at {b.where} sits below "
                    f"{prev_date.date} at {prev_date.where}"
                )
            prev_date = b


class Report:
    def __init__(self):
        self.fail = False

    def ok(self, msg: str) -> None:
        print(f"  {GREEN}✓{RESET} {msg}")

    def bad(self, msg: str) -> None:
        print(f"  {RED}✗{RESET} {msg}", file=sys.stderr)
        self.fail = True

    def warn(self, msg: str) -> None:
        print(f"  {YELLOW}!{RESET} {msg}", file=sys.stderr)


def check_ledger(project: Path, report: Report) -> None:
    ledger = project / "handoff.md"
    archive = project / "handoff-archive.md"

    if not ledger.exists():
        report.warn(f"{rel(project)} has no handoff.md — skipped")
        return

    print(f"\n{rel(project)}")

    if "PURPOSE:" not in ledger.read_text(encoding="utf-8")[:1000]:
        report.warn(f"{rel(ledger)} has no PURPOSE comment at the top")

    live = parse_file(ledger, report)
    if not live:
        # Still parse and check the archive: an early return here once let a
        # single broken live heading hide a 193-block archive from the check.
        report.bad(f"{rel(ledger)} contains no session blocks")

    archived = parse_file(archive, report) if archive.exists() else []

    # The two files are one logical ledger: newest-first has to hold across the
    # seam, or a rotation has interleaved them.
    check_ordering(live + archived, report)

    if live:
        report.ok(
            f"{len(live)} block(s) in handoff.md, newest is {live[0].describe}"
        )
    if archived:
        report.ok(
            f"{len(archived)} block(s) in handoff-archive.md, "
            f"newest is {archived[0].describe}"
        )


def main(argv: list[str]) -> int:
    if argv:
        projects = [Path(a).resolve() for a in argv]
    else:
        projects = sorted(p for p in (ROOT / "work").iterdir() if p.is_dir())

    print(f"Checking work-item ledgers at {ROOT}")
    report = Report()
    for project in projects:
        check_ledger(project, report)

    if report.fail:
        print(f"\n{RED}ledger check FAILED{RESET}", file=sys.stderr)
        return 1
    print(f"\n{GREEN}all ledgers well-formed{RESET}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
