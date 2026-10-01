# 15 — Plans docs and skill wording from the dogfood

**What to build:** Wording fixes in `docs/plans.md` and `skills/plans/SKILL.md`: the cwd a `check` runs in; sizing (≈60K harness baseline, one standard seam node per session); `--blocked-by` takes full ids (example); `done` then `sync`, and why; closing a plan is a hand edit of `status: closed` as the last write; reconcile step 3 no-op when the node's output is already a Tier-2 note; when the next frontier is `hitl`, the launcher prose carries the question and how to answer it; "Create a plan from tickets" puts a `hitl` node in front of any ticket needing a person, key, spend or machine; the reconcile step flips the ticket a node's `Ticket:` line names to `resolved`; re-read `git log -1` and target files right before rewriting another item's launcher; the L48 recipe ("Create a plan before a spec exists"). Source: the dogfood findings and the L48 note in `decisions.md`.

**Blocked by:** 14

**Status:** done (2026-09-30, s19)

**Spec:** findings only

- [x] Each listed point present (grep-checkable phrase per point)
- [x] `test-doc-consistency.sh` green
