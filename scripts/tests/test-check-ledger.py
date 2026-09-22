#!/usr/bin/env python3
"""
File: scripts/tests/test-check-ledger.py
Purpose: Mutation-test scripts/check-ledger.py — inject each ledger defect the
         check exists to catch and assert the check FAILS on it, then assert it
         PASSES on the clean baseline. A gate that only ever says OK is not a
         gate.
See: docs/work-directory-conventions.md → "handoff.md — the ledger"

Run: scripts/tests/test-check-ledger.py
"""

from __future__ import annotations

import importlib.util
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
CHECK = ROOT / "scripts" / "check-ledger.py"
LAUNCHER = ROOT / "scripts" / "launch-next-session.sh"

PURPOSE = """<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Convention: docs/work-directory-conventions.md.
-->
"""

# A clean ledger exercising every accepted title convention (current, sNNN,
# hash-number, date-only, addendum), plus an archive in the legacy
# convention — all are live history and all must parse; the mixed
# date-only/dateless blocks also prove ordering skips a missing key without
# breaking the chain.
CLEAN_LEDGER = PURPOSE + """
# Session Handoff — 76 (2026-08-22): the newest thing that happened

Body prose.

## A sub-heading inside the block

More body.

# Session Handoff addendum — 2026-08-21 (session 75: a second block filed by the same session)

Body prose.

# Session Handoff — 75 (2026-08-21): the older thing that happened

Body prose.

# Session Handoff — s74 (a dateless sNNN block)

Body prose.

# Session Handoff — 2026-08-20 (session #73: a hash-numbered block)

Body prose.

# Session Handoff — 2026-08-19 (a date-only block with no session number)

Body prose.
"""

CLEAN_ARCHIVE = """# Session Handoff — 2026-08-18 (session 72, bg: an archived block)

Body prose.

# Session Handoff — 2026-08-17 (session 71, bg: an older archived block)

Body prose.
"""

# An earlier numbering lineage below an explicit restart marker: session 90
# outranks the 71 above it numerically, which only the marker makes legal.
# Dates still descend across the seam — the marker never excuses those.
RESTART_TAIL = """
<!-- ledger-lineage-restart: numbering restarted; earlier lineage below. -->

# Session Handoff — 2026-08-10 (session 90: last block of the earlier lineage)

Body prose.

# Session Handoff — 2026-08-09 (session 89: an even older block)

Body prose.
"""
RESTART_ARCHIVE = CLEAN_ARCHIVE + RESTART_TAIL


def mutate_unclosed_comment(ledger: str, archive: str):
    """Session 76 defect 1: the purpose comment never closes, so the block
    heading beneath it is swallowed and the block is invisible."""
    return ledger.replace("-->\n", "", 1), archive


def mutate_out_of_order(ledger: str, archive: str):
    """Session 76 defect 2: a block filed below one older than itself."""
    return (
        ledger.replace("76 (2026-08-22)", "TMP (2026-08-22)")
        .replace("75 (2026-08-21)", "76 (2026-08-22)")
        .replace("TMP (2026-08-22)", "75 (2026-08-21)"),
        archive,
    )


def mutate_malformed_heading(ledger: str, archive: str):
    """A block heading that matches neither title convention."""
    return ledger.replace(
        "# Session Handoff — 75 (2026-08-21): the older thing that happened",
        "# Handoff for last session",
    ), archive


def mutate_orphan_subheading(ledger: str, archive: str):
    """Body content stranded above the first block heading."""
    return ledger.replace(
        "\n# Session Handoff — 76", "\n## Stranded notes\n\n# Session Handoff — 76", 1
    ), archive


def mutate_date_regression(ledger: str, archive: str):
    """Numbers ascend correctly but the dates contradict them."""
    return ledger.replace("76 (2026-08-22)", "76 (2026-08-19)"), archive


def mutate_archive_interleave(ledger: str, archive: str):
    """Rotation put a NEWER block in the archive than the live ledger holds —
    the seam between the two files is where rollover tooling writes blind."""
    return ledger, archive.replace("session 72", "session 77")


def mutate_keyless_heading(ledger: str, archive: str):
    """A heading in the right shape but yielding neither a session number nor
    a date — nothing for ordering to hold on to."""
    return ledger.replace(
        "# Session Handoff — 2026-08-19 (a date-only block with no session number)",
        "# Session Handoff — (neither a number nor a date here)",
    ), archive


def mutate_addendum_keyless(ledger: str, archive: str):
    """The addendum form must not relax key extraction: an addendum heading
    yielding neither a session number nor a date still fails."""
    return ledger.replace(
        "# Session Handoff addendum — 2026-08-21 (session 75: a second block filed by the same session)",
        "# Session Handoff addendum — (a keyless addendum heading)",
    ), archive


def mutate_restart_without_marker(ledger: str, archive: str):
    """The earlier-lineage tail WITHOUT its marker — the numbering restart
    must fail unless the marker explicitly declares it."""
    return ledger, archive + RESTART_TAIL.replace(
        "<!-- ledger-lineage-restart: numbering restarted; earlier lineage below. -->\n",
        "",
    )


def mutate_restart_marker_date_regression(ledger: str, archive: str):
    """A marker restarts only the number chain: a NEWER date filed below the
    seam must still be caught."""
    return ledger, archive + RESTART_TAIL.replace(
        "2026-08-10 (session 90", "2026-08-19 (session 90"
    )


def mutate_broken_live_hides_archive(ledger: str, archive: str):
    """The live ledger yields no parseable blocks at all — the check must
    still parse the archive and report its defects, not return early (a
    broken live heading once silently hid a 193-block archive)."""
    broken = PURPOSE + """
# Session Handoff — (wholly unparseable heading)

Body prose.
"""
    swapped = (
        archive.replace("session 72", "TMP")
        .replace("session 71", "session 72")
        .replace("TMP", "session 71")
    )
    return broken, swapped


# (name, mutation, required stderr substring or None)
MUTATIONS = [
    ("purpose comment never closes, heading swallowed", mutate_unclosed_comment, None),
    ("a block is filed below an older one", mutate_out_of_order, None),
    ("a heading matches neither title convention", mutate_malformed_heading, None),
    ("body content stranded above the first block", mutate_orphan_subheading, None),
    ("dates contradict the session numbers", mutate_date_regression, None),
    ("archive holds a newer block than the ledger", mutate_archive_interleave, None),
    ("a heading yields neither number nor date", mutate_keyless_heading, None),
    ("an addendum heading yields neither number nor date", mutate_addendum_keyless, None),
    ("a numbering restart with no lineage marker", mutate_restart_without_marker, None),
    ("a marker must not excuse a date regression", mutate_restart_marker_date_regression, None),
    (
        "broken live ledger must not hide archive defects",
        mutate_broken_live_hides_archive,
        "handoff-archive.md",
    ),
]


# One heading rule, two parsers (docs/work-directory-conventions.md → "Ledger"):
# the launcher's `top_ledger_session` must read the same session number from a
# top heading that check-ledger.py reads, and must read none from a heading
# the checker rejects. Expected numbers come from the convention's worked
# forms; REJECT marks a heading the convention does not accept.
REJECT = "reject"
HEADING_FIXTURES = [
    ("plain numbered", "# Session Handoff — 76 (2026-08-22): what happened", 76),
    ("letter suffix", "# Session Handoff — 74b (2026-08-22): a second block", 74),
    ("dated, session N", "# Session Handoff — 2026-08-22 (session 68, bg: what happened)", 68),
    ("dated, session #N", "# Session Handoff — 2026-08-29 (session #8: what happened)", 8),
    ("dateless sNNN", "# Session Handoff — s201 (what happened)", 201),
    ("date-only", "# Session Handoff — 2026-08-07 (what happened)", None),
    ("midnight span", "# Session Handoff — 2026-08-22/23 (what happened)", None),
    ("year is not a number", "# Session Handoff — 2026-08-22 (what happened in 2026)", None),
    ("addendum, numbered", "# Session Handoff addendum — 23 (2026-09-22): what happened", 23),
    ("addendum, dated session N", "# Session Handoff addendum — 2026-08-22 (session 166: what happened)", 166),
    ("no dash", "# Session Handoff 76 (2026-08-22): what happened", REJECT),
    ("keyless", "# Session Handoff — (what happened)", REJECT),
    ("doubled space", "#  Session Handoff — 76 (2026-08-22): what happened", REJECT),
]


def load_checker():
    sys.dont_write_bytecode = True  # no scripts/__pycache__ from the import
    spec = importlib.util.spec_from_file_location("check_ledger", CHECK)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def checker_reads(tmp: Path, checker, heading: str):
    """What check-ledger.py reads from a ledger whose top block is `heading`:
    REJECT when the check fails, else the session number (None if dateless)."""
    code, _ = run_check(write_project(tmp, PURPOSE + "\n" + heading + "\n\nBody prose.\n", ""))
    if code != 0:
        return REJECT
    num, _ = checker.parse_heading(checker.HEAD.match(heading).group("rest"))
    return num


def launcher_reads(tmp: Path, heading: str):
    """What the launcher's top_ledger_session reads from the same ledger: the
    session number, or None when it yields nothing."""
    ledger = tmp / "work" / "fixture" / "handoff.md"
    fn = subprocess.run(
        ["awk", "/^top_ledger_session\\(\\) \\{/,/^\\}/", str(LAUNCHER)],
        capture_output=True, text=True, check=True,
    ).stdout
    assert fn.strip(), "top_ledger_session not found in launch-next-session.sh"
    out = subprocess.run(
        ["bash", "-c", fn + '\ntop_ledger_session "$1"', "_", str(ledger)],
        capture_output=True, text=True,
    ).stdout.strip()
    return int(out) if out else None


def run_check(project: Path) -> tuple[int, str]:
    proc = subprocess.run(
        [sys.executable, str(CHECK), str(project)],
        capture_output=True,
        text=True,
    )
    return proc.returncode, proc.stderr


def write_project(tmp: Path, ledger: str, archive: str) -> Path:
    project = tmp / "work" / "fixture"
    project.mkdir(parents=True, exist_ok=True)
    (project / "handoff.md").write_text(ledger, encoding="utf-8")
    (project / "handoff-archive.md").write_text(archive, encoding="utf-8")
    return project


def main() -> int:
    passed = 0
    total = len(MUTATIONS) + 2 + len(HEADING_FIXTURES)

    with tempfile.TemporaryDirectory() as td:
        tmp = Path(td)

        # Baseline: the check must be quiet on a well-formed ledger, or every
        # failure below is meaningless.
        code, _ = run_check(write_project(tmp, CLEAN_LEDGER, CLEAN_ARCHIVE))
        if code == 0:
            print("  baseline: clean ledger passes                        OK")
            passed += 1
        else:
            print(f"  baseline: clean ledger passes                        FALSE ALARM (exit {code})")

        # Second baseline: a declared lineage restart is legal.
        code, _ = run_check(write_project(tmp, CLEAN_LEDGER, RESTART_ARCHIVE))
        if code == 0:
            print("  baseline: marked lineage restart passes              OK")
            passed += 1
        else:
            print(f"  baseline: marked lineage restart passes              FALSE ALARM (exit {code})")

        for name, mutate, expect in MUTATIONS:
            ledger, archive = mutate(CLEAN_LEDGER, CLEAN_ARCHIVE)
            if (ledger, archive) == (CLEAN_LEDGER, CLEAN_ARCHIVE):
                print(f"  {name:52} MUTATION IS A NO-OP")
                continue
            code, stderr = run_check(write_project(tmp, ledger, archive))
            if code != 0 and (expect is None or expect in stderr):
                print(f"  {name:52} caught")
                passed += 1
            elif code != 0:
                print(f"  {name:52} MISSED (failed, but stderr lacks {expect!r})")
            else:
                print(f"  {name:52} MISSED")

        # One heading rule: both parsers read the same thing from every fixture.
        checker = load_checker()
        for name, heading, expect in HEADING_FIXTURES:
            got_c = checker_reads(tmp, checker, heading)
            got_l = launcher_reads(tmp, heading)
            label = f"heading agreement: {name}"
            if got_c != expect:
                print(f"  {label:52} CHECKER reads {got_c!r}, convention says {expect!r}")
            elif (got_c == REJECT and got_l is None) or got_c == got_l:
                print(f"  {label:52} agree")
                passed += 1
            else:
                print(f"  {label:52} DISAGREE (checker {got_c!r}, launcher {got_l!r})")

    print(f"\n{passed}/{total} ledger checks passed")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
