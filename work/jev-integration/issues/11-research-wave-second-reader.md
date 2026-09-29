# 11 — research-wave second reader: `scripts/jev-verdicts.sh` + offline test + skill step

**What to build:** A thin script over the one CLI. `scripts/jev-verdicts.sh <fact-check.md>…` parses each fact-check table's claim rows (claim | verdict | what the source actually says | correction), sends one Choice per row through `scripts/jev.sh` (`state` = `{claim, source_says}` per row, criteria = CONFIRMED / OVERSTATED / WRONG / UNVERIFIABLE with one-line descriptions from `references/fact-check-brief.md`), and prints one line per **flagged** row: Jev's confidence ≥ 0.5 **and** verdict ≠ the fact-checker's, with file, row, both verdicts, confidence. Exit 0 with flags, 0 with none (one summary line to stderr), 3 with no key (propagated from the CLI, one stderr line), 2 on a row it cannot parse (before any request), 4 on a server error (propagated). Python only for the table parsing; the network is the CLI's alone. Test-first: `scripts/tests/test-jev-verdicts.sh` (stub server, fixture table, canned answers: request shape, flag rule at the boundary, exit 3 keyless, exit 2 on a malformed row). Skill: one gated step in `skills/research-wave/SKILL.md` Phase 3 ("with a key run …; `--check` exit 3 → skip") plus one sentence that nothing in the ruling depends on it. Then run it once for real on this item's `research/` fact-check(s) and record the disagreement rate and cost in the node Log (S30); `research/` is not edited.

**Read first:** `skills/research-wave/SKILL.md` (Phase 3), `skills/research-wave/references/fact-check-brief.md` (verdict table format), `skills/jev/SKILL.md`, `decisions.md` (fourth note: CLI contract), `scripts/tests/test-jev.sh` (grep `stub` for the server pattern), `docs/service-access.md`.

**Blocked by:** 08 (the flag rule uses the confirmed threshold).

**Status:** open

**Spec:** S26, S27, S30

- [ ] `scripts/jev-verdicts.sh` parses a fact-check table and sends one Choice per row through `scripts/jev.sh`; flagged rows printed as specified; exit codes 0/2/3/4 as specified; never prints the key
- [ ] `scripts/tests/test-jev-verdicts.sh` passes offline: request shape, flag rule (≥ 0.5 and differs; 0.49 not flagged; agree at 1.0 not flagged), keyless exit 3 with nothing sent, malformed row exit 2 before any request
- [ ] `skills/research-wave/SKILL.md` Phase 3 carries the gated one-line step and the "flags only, nothing depends on it" sentence
- [ ] One live run on this item's `research/` fact-check table: disagreement rate and cost in the node Log; `research/` untouched
- [ ] `docs/service-access.md` Jev entry names the second caller in one clause

**Check:** `bash "$WORKSPACE_ROOT/scripts/tests/test-jev-verdicts.sh" >/dev/null && test -x "$WORKSPACE_ROOT/scripts/jev-verdicts.sh" && grep -q 'jev-verdicts' "$WORKSPACE_ROOT/skills/research-wave/SKILL.md"`
