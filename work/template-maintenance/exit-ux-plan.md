# Exit-UX plan — session-end handling (approved design, ready to implement)

User approved (2026-08-31) building three changes + tests. Full scenario
analysis happened in-conversation; this file is the write-ahead so a fresh
session can implement without re-deriving. TDD: red first, per slice.

## Approved changes

### 1. Lineage-gate diagnosis + auto-heal — `scripts/launch-next-session.sh`

Gate lives at lines ~295-318 (die at ~311-314). Today ANY counter/ledger
mismatch dies. New behavior — split on `LAST_SEQ == TOP_N + 1` (one-ahead =
"session N was launched but never wrote its ledger block"):

- **No evidence of work → auto-heal**: `note` a reclaim message
  ("left no trace … reclaiming its number"), `[ "$DRY" -eq 0 ] && printf
  '%s\n' "$TOP_N" > "$SEQF"`, set `LAST_SEQ="$TOP_N"`, continue the launch.
  Successor then reuses N (bump at :490 rewrites N — net effect: number
  reclaimed, ledger-consistent).
- **Evidence exists → refuse (exit 3)** with a diagnosis: what the session
  left behind, instruction to reconstruct its ledger block (git log, record
  labels, write-ahead files), and the seq-sync rewind as the alternative fix
  (`seq-sync --project $PROJECT --session $TOP_N`).
- **Any other mismatch** (delta ≠ +1): today's die, verbatim, unchanged.

Evidence sources (all best-effort; anchor = **mtime of `$SEQF`** — the
launcher's bump at :490 IS the staging timestamp of session N):

- `staged_epoch`: `stat -f %m` (macOS) `|| stat -c %Y` (GNU); ISO via
  `date -u -r "$e" +%FT%TZ || date -u -d "@$e" +%FT%TZ`.
- (a) work-unit records: `$WORKSPACE_ROOT/.context-budget/context-ledger.jsonl`
  entries with `.ts > $staged_iso` (jq, lexicographic ISO compare, guard
  `command -v jq`). Entries have NO project field — workspace-wide check;
  false positive → refuse (conservative direction, acceptable). Show last 5
  labels in the message.
- (b) commits: `git -C "$WORKSPACE_ROOT" log --oneline --since="$staged_iso"
  | head -5` (non-repo → empty, fine).
- (c) dirty work item: `git status --porcelain -- "work/$PROJECT" | head -5`.
  (`.session-seq`, provenance, context-ledger all gitignored — verified —
  so they never self-trigger.)

Verified facts: seq-sync CAN lower ("lowered" action, context-budget.sh
~1068). Only `cmd_record` appends measurement entries (register does NOT —
so a do-nothing session leaves zero entries; heal fires). `note()` at :67,
`DRY` parsed at :75, counter bump at :488-490 AFTER the gate, mode=off exits
at ~668 AFTER the bump (so a no-dry-run off/manual run makes counter effects
observable in tests).

### 2. Notify-on-quit — `scripts/session-loop.sh`

Quit branch (~line 302: `say "no sentinel and the counter did not move —
deliberate quit; ending the chain"`). KEEP that say line verbatim (tests
L2b/C4f assert "deliberate quit"; L3c asserts halt path lacks it). After it,
add a `notify` (existing fn ~:79, routes to SESSION_LOOP_NOTIFY) with a
ledger-aware message:

- top block number == seq_before → "chain ended: session #N quit after
  writing its ledger block"
- top block number != seq_before → "chain ended: session #N quit WITHOUT a
  rollover or checkpoint — no ledger block for it (top block is session M)"
- no/unnumbered ledger → generic "chain ended: session #N quit"

Needs a small `top_ledger_seq()` helper mirroring the launcher's extraction
grammar (strip ISO dates → `session[[:space:]]+#?[0-9]+` or `— s?N` after
heading dash; see launch-next-session.sh:304-311; canonical grammar is
check-ledger.py — say so in a comment). Reads `$S/handoff.md` then
`$S/session_handoff.md`. Exit 0 stays.

### 3. Docs — "two doors" contract

- `docs/work-directory-conventions.md`: new short section — sessions end via
  session-rollover (continue) or checkpoint (stop); a plain exit is
  recoverable: next launch auto-reclaims a no-trace session's number, or
  refuses with a reconstruction brief when work was left unrecorded.
- `CONTEXT.md` (edit CONTEXT.md itself, NEVER the CLAUDE.md symlink): one
  sentence in Context Budget section pointing at the new doc section.
- `docs/context-budget.md`: document gate diagnosis/auto-heal + loop
  notify-on-quit in the relevant sections.
- Backlog: add card to `docs/template-workspace-backlog.html` per its
  "Maintaining this backlog" section (grep the ID conventions; targeted
  edits only, never whole-file reads). Deliverable = resolved card with
  Fixed: note (archive file: docs/template-workspace-backlog-archive.html).

NOT building (deliberately): statusline "unrecorded" indicator (optional in
proposal), SessionEnd-time warnings, forced rollover.

## Test plan

### `scripts/tests/test-launch-next-session.sh` (harness: TMP workspace,
non-git; helpers ok/bad/assert_eq/assert_contains; run_lns clears env)

- **Rework T23e-j** (counter=10, top=9, currently expects die): fixture now
  needs evidence to stay exit-3 — backdate the counter
  (`touch -t 202001010100 .session-seq`) then append a record entry with
  current ts to `$TMP/.context-budget/context-ledger.jsonl`
  (`jq -cn '{ts:(now|todate), label:"t23-work"}'` or printf a literal with a
  2099 date — simpler: printf `{"ts":"2099-01-01T00:00:00Z","label":"x"}`
  NO — future date breaks nothing but honesty; use current date via
  `date -u +%FT%TZ`). Keep assertions T23f-i (gate named, values, seq-sync
  remediation) + add assert evidence text shown. Clean up the ledger file
  after the block (later tests must not inherit evidence!).
- **New T24 series** (insert after T23t, before "C:" block at ~348):
  - T24a-c heal, dry-run: top=9, counter=10 (fresh mtime, no ledger file,
    no git) → exit 0, "reclaiming its number", "rollover session #10",
    counter file still 10 (dry-run untouched).
  - T24d-e heal, real run (`ROLLOVER_RELAUNCH=off`, no --dry-run): exit 0,
    post-run counter = 10 (9 healed + bump to 10 = number reused).
  - T24f evidence via record entry → exit 3 (covered in reworked T23e too;
    keep one explicit here for the message contract: labels listed,
    "Reconstruct" guidance present).
  - T24g git evidence: ISOLATED mini-workspace (mktemp EV, copy launcher,
    git init, commit AFTER backdated... simpler: init repo, backdate seqf,
    then `git commit` now → commit is after staged mtime → refuse). Also
    covers dirty-tree variant if cheap. Do NOT git-init the main $TMP
    (C/W-series tests after T23 depend on non-repo TMP).
  - Cleanup: rm ledger jsonl + HF + seqf so C-series inherits nothing.

### `scripts/tests/test-session-loop.sh` (harness: MAIN git workspace, stub
sessions via STUB_BEHAVIOUR; reset() seeds counter=8)

- New N-series at file end (check PASS/FAIL summary lines at bottom first):
  - N1: STUB_BEHAVIOUR=quit, no handoff.md → notify generic; assert output
    contains "chain ended" and exit 0. SESSION_LOOP_NOTIFY= a stub script
    appending "$1" to a file; assert file got the message (proves the
    external notify path, not just say).
  - N2: handoff.md top block "# Session Handoff — 8 (2026-08-31): x" (==
    seq_before=8) → message says quit after writing its ledger block.
  - N3: top block session 7 (≠ 8) → message says WITHOUT a rollover.
  - Existing L2/C4 must stay green (they tolerate extra output).

### Suites to run when done
`bash scripts/tests/test-launch-next-session.sh` (was 207/0 → grows),
`bash scripts/tests/test-session-loop.sh` (was 68/68 → grows). Also
`scripts/check-workspace-structure.sh` after doc edits.

## Gotchas
- zsh: `echo ===` breaks (`== not found`) — quote it in Bash tool calls.
- Edit CONTEXT.md directly, never CLAUDE.md/AGENTS.md symlinks.
- ISO compare needs same-second tiebreak — always backdate the seqf mtime in
  tests, never rely on write ordering within a second.
- Existing T23o/T23m rely on the non-one-ahead die path — verify unchanged.
- Commit style: `Fix <card-id>: …` + Decision trailer; update backlog per
  CLAUDE.md "Template Backlog" section.
