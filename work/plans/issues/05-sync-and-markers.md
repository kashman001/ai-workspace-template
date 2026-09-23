# 05 — `plan.sh sync` and the marker convention

**What to build:** `sync` re-renders the waves board into `plan.md` and a Position/Frontier block into the item's launcher, each strictly between `<!-- plan:begin <name> -->` and `<!-- plan:end <name> -->`, idempotently; missing markers are reported, never invented. The convention is written up once in `docs/work-directory-conventions.md`.

**Blocked by:** 02

**Status:** ready-for-agent

**Spec:** S2, S21

- [ ] Running sync twice leaves the files byte-identical; text outside markers is untouched (test diffs the outside)
- [ ] Launcher without markers → exit 1 naming the file and the marker to add
- [ ] Board columns: wave, node, kind, tier, status; footer line with frontier, remaining, sessions used
