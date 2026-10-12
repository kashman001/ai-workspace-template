# Runbook — split `docs/adr/` into project ADRs and template TADRs

**When:** a template sync brings in `docs/template-adr/` and your workspace's
`docs/adr/` still holds the template's records (`ADR-0001` … `ADR-0014`), possibly
mixed with your own. Until this runs, "ADR-0010" can name two documents.

**End state:** the template's records live in `docs/template-adr/` as `TADR-NNNN`,
exactly as the template ships them; `docs/adr/` holds only your project's records,
with their numbers unchanged; `docs/adr/README.md` indexes only those.

## Steps

1. **Inventory.** List `docs/adr/` and sort each file into one of two sets:
   - *template* — the file also exists under the same name in the template's
     `docs/template-adr/` (compare names, then `diff` the bodies modulo the
     `ADR-`/`TADR-` label: a local edit to a template record is a divergence to
     resolve, not a project record);
   - *project* — everything else, `0000-template.md` and `README.md` aside.
   A *project* file whose number a *template* file also uses is the collision
   this runbook removes; it keeps its number.
2. **Take the template's records.** Copy `docs/template-adr/` from the template
   verbatim (the sync usually already did), then `git rm` the *template* set
   from `docs/adr/`. Never renumber or relabel the *project* set.
3. **Re-link the workspace's own files.** Template-owned files arrive already
   relabelled. In files only your workspace has, find citations of the template's
   records — `git grep -nE 'ADR-00(0[1-9]|1[0-4])|docs/adr/00'` outside `work/`
   — and change each that means a *template* record to `TADR-NNNN` /
   `docs/template-adr/…`. Read each hit: one that means a project ADR of the
   same number stays. Ledgers and archives under `work/` are history; leave them.
4. **Indexes.** Rebuild `docs/adr/README.md` from the template's version, with
   your *project* records in its Index. Leave `docs/template-adr/README.md` as
   the template ships it.
5. **Pending promotions.** A Tier-2 note marked `Promote?: yes` for a decision
   about the workspace machinery becomes `Promote?: upstream`: propose it to the
   template rather than numbering it locally (`skills/decision-log/SKILL.md`).

## Verify

- `ls docs/adr/` shows only `0000-template.md`, `README.md` and project records.
- `git grep -nP '(?<!T)ADR-00(0[1-9]|1[0-4])' -- ':!work/'` returns only
  citations of project ADRs (read each), and nothing cites
  `docs/adr/<template-record>` any more.
- `bash scripts/check-drift.sh` reports no dead `docs/` path.
