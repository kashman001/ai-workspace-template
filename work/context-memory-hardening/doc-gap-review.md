# Documentation gap review (session 4)

Review only — nothing below is fixed. Scope: first the gaps left by this
work item's changes (`a753c1b..64f8908`), then other gaps met on the way.
Ranked most useful first.

## A. Gaps left by this work item

1. **`check`/`record` output line is out of date.**
   Where: `docs/context-budget.md:70` says the output is
   `runtime= method= tokens= threshold= warn= pct= status= artifact=`.
   Since L50 the script prints `cache=` before `artifact=`
   (`scripts/context-budget.sh:19`, `:524`).
   Fix: add `cache=` to that line and point to the Ledger section (`:821`)
   that explains it.

2. **Downloaders are not told the template changed.**
   Where: `TEMPLATE_VERSION` still reads `2026-09-30`; the repo keeps no
   changelog. This item changed `CONTEXT.md` (trim, new rules), the
   context-budget output and ledger rows, and the checkpoint skill.
   Fix: bump `TEMPLATE_VERSION` at the next release. That's the
   maintainer's call (`docs/template-usage.md` §6), so this item needs
   a decision, not an automatic fix.

3. **The "what CONTEXT.md should contain" guidance lacks the new rules.**
   Where: `docs/workspace-structure.md` → "What `CONTEXT.md` Should Contain"
   (`:163`). It says "keep it concise" but has no size budget (the trim
   aimed at the Z0 budget) and no "no dates, status or counters, because
   they break prompt caching" rule. Today those rules are only in
   `CONTEXT.md` itself and `docs/context-budget.md` → "Cache the prefix,
   vary the tail". Someone adapting the template reads this section first.
   Fix: add one bullet pointing to "Cache the prefix, vary the tail".

4. **Pointer to a "lean-loading model" that no longer lives in CONTEXT.md.**
   Where: `docs/workspace-structure.md:234` calls `.claude/agents/` "part of
   the lean-loading model in `CONTEXT.md` → 'Tool & Context Loading'". The
   L51 trim cut that section to one paragraph. The three layers (CLI-first,
   core vs. fragments, parent/child toolsets) are now explained in
   `docs/mcp-setup.md` and `mcp-fragments/README.md`.
   Fix: point to `docs/mcp-setup.md`. Smaller cases of the same thing:
   `docs/mcp-setup.md:26` sends readers to `CONTEXT.md` for the
   "rationale", but that section is now a two-line summary. Other
   `CONTEXT.md → <section>` pointers were checked and all still resolve.

5. **The work-directory guide doesn't mention classifying or retiring
   decision notes.**
   Where: `docs/work-directory-conventions.md:159` (the `decisions.md` row)
   and `docs/for-non-engineers.md:36`. The decision-log skill now sorts
   each note into ADD / UPDATE / SUPERSEDE / NOOP, and a replaced note gets
   a `**Retired:**` line. Readers of those two docs won't know a note can be
   retired, and might quote a retired one.
   Fix: one clause in each ("a replaced note is marked `**Retired:**`, so
   skip it").

6. **Postmortems README doesn't say gotchas need a `Last confirmed` date.**
   Where: `docs/postmortems/README.md:7` says to "copy that gotcha into
   `operational-knowledge.md`" without the new rule. The rule is in that
   file's header (`:13`), so anyone who opens it will see it. Low.
   Fix: optional; add "with a `Last confirmed` line".

Checked and fine: `Last confirmed` / 6-month review / ADD-UPDATE-SUPERSEDE-
NOOP are consistent across `operational-knowledge.md`, `checkpoint`,
`decision-log`, `session-rollover` and ADR-0013. ADR-0013 is in the ADR
index. `docs/zoom-model.md` does not describe retrieval, so it doesn't need
the "scan headings" rule. `docs/template-usage.md` makes no claim that
conflicts with the changes.

## B. Other documentation gaps

7. **Gotcha entry names a script that no longer exists.**
   Where: `docs/operational-knowledge.md:304` cites `scripts/rollover-prep.sh`,
   removed in `d4fb3b6`. The lesson still holds, but a reader can't find
   the script. This is exactly what the new 6-month review should catch.
   Fix: add "(script since removed; its job moved to …)", or reword.

8. **ADR-0009 cites a file that was never committed.**
   Where: `docs/adr/0009-clear-based-rollover-relaunch.md:127` cites
   `docs/session-chain-scenarios.md`, which has no git history. Its
   `scripts/hooks/rollover-clear-seed.sh` (`:59`) was removed in `5330f86`.
   That's expected: ADR-0009 is amended by ADR-0010, and ADRs record
   history. Only the never-committed file is a real gap.
   Fix: name where scenario B3 now lives, or drop the path.

9. **The doc consistency test only covers plans.**
   Where: `scripts/tests/test-doc-consistency.sh` (17/17 pass) checks paths
   for `docs/plans.md` and the plans skill only. The dead paths in 7–8 were
   found by hand.
   Fix: run its "every path named exists" check over all of `docs/` and
   `skills/`. It would need an allow-list for upstream paths (vendored
   provenance lines), generated files (`docs/agents/domain.md`,
   `triage-labels.md`, written by `setup-matt-pocock-skills`) and paths
   relative to a skill's own folder (`scripts/rlm_repl.py`,
   `scripts/hitl-loop.template.sh`).

Checked and fine: `docs/README.md` indexes every file and folder in `docs/`.
The other "dead" paths found by the sweep were false alarms of the kinds
listed in 9.
