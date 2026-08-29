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

import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
CHECK = ROOT / "scripts" / "check-ledger.py"

PURPOSE = """<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Convention: docs/work-directory-conventions.md.
-->
"""

# A clean ledger exercising every accepted title convention (current, sNNN,
# hash-number, date-only), plus an archive in the legacy convention — all are
# live history and all must parse; the mixed date-only/dateless blocks also
# prove ordering skips a missing key without breaking the chain.
CLEAN_LEDGER = PURPOSE + """
# Session Handoff — 76 (2026-08-22): the newest thing that happened

Body prose.

## A sub-heading inside the block

More body.

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
    (
        "broken live ledger must not hide archive defects",
        mutate_broken_live_hides_archive,
        "handoff-archive.md",
    ),
]


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
    total = len(MUTATIONS) + 1

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

    print(f"\n{passed}/{total} ledger mutations caught")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
