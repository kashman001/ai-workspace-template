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

# A clean two-block ledger in the current title convention, plus an archive in
# the legacy convention — both forms are live history and both must parse.
CLEAN_LEDGER = PURPOSE + """
# Session Handoff — 76 (2026-08-22): the newest thing that happened

Body prose.

## A sub-heading inside the block

More body.

# Session Handoff — 75 (2026-08-21): the older thing that happened

Body prose.
"""

CLEAN_ARCHIVE = """# Session Handoff — 2026-08-20 (session 74, bg: an archived block)

Body prose.

# Session Handoff — 2026-08-19 (session 73, bg: an older archived block)

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
    return ledger, archive.replace("session 74", "session 77")


MUTATIONS = [
    ("purpose comment never closes, heading swallowed", mutate_unclosed_comment),
    ("a block is filed below an older one", mutate_out_of_order),
    ("a heading matches neither title convention", mutate_malformed_heading),
    ("body content stranded above the first block", mutate_orphan_subheading),
    ("dates contradict the session numbers", mutate_date_regression),
    ("archive holds a newer block than the ledger", mutate_archive_interleave),
]


def run_check(project: Path) -> int:
    return subprocess.run(
        [sys.executable, str(CHECK), str(project)],
        capture_output=True,
        text=True,
    ).returncode


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
        code = run_check(write_project(tmp, CLEAN_LEDGER, CLEAN_ARCHIVE))
        if code == 0:
            print("  baseline: clean ledger passes                        OK")
            passed += 1
        else:
            print(f"  baseline: clean ledger passes                        FALSE ALARM (exit {code})")

        for name, mutate in MUTATIONS:
            ledger, archive = mutate(CLEAN_LEDGER, CLEAN_ARCHIVE)
            if (ledger, archive) == (CLEAN_LEDGER, CLEAN_ARCHIVE):
                print(f"  {name:52} MUTATION IS A NO-OP")
                continue
            code = run_check(write_project(tmp, ledger, archive))
            if code != 0:
                print(f"  {name:52} caught")
                passed += 1
            else:
                print(f"  {name:52} MISSED")

    print(f"\n{passed}/{total} ledger mutations caught")
    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
