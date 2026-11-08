<!--
PURPOSE: This is the LEDGER (provenance log). Append-only, newest block on TOP.
Each "# Session Handoff" block records what happened in one session. Read the
TOP block only; older blocks are in handoff-archive.md. Forward "what to do
next" belongs in next-session.md, NOT here.
Convention: docs/work-directory-conventions.md.
-->

# Session Handoff — 27 (2026-11-07): vendored skills refreshed from all four upstreams; 3 pstack skills added

**Summary.** `83adec7` refreshed every vendored upstream (Matt Pocock `4ae2317`, Addy Osmani `353ae84`, pstack `c742dd6`, TypeSafe `302eea6` v0.6.2 by hand). `a95b1fe` vendored three user-invoked pstack skills: `create-formal-verification-skill` (patched: no `statechart`, output at `skills/formal-verify-<area>/`), `maintain-formal-verification-skill`, `sharpen`. Not pushed: main is 2 ahead of origin.

**Decisions.** Keep `skills/code-review/workspace.patch`: mattpocock/skills#1242 closed *not planned*, so the sync's "may have landed" note is a false alarm. Five other new upstream skills left: `skill-packs-analysis.md` → "Refresh evaluation (2026-11-07)".

**Verification.** `run-checks.sh` 46/46 after each commit; two re-syncs idempotent; a broken patch makes the sync fail by name. Always-loaded cost +291 B (slash-command descriptions); model-invoked budget unchanged at 7078/7500.

**Open questions.** None new. Still open from s26: L85, L86.

**Suggested skills.** `checkpoint` if nothing is queued.

Learnings:
- The sync's `rsync --delete` wipes any non-patch file in a vendored skill dir (a `.bak` vanished mid-test); back up outside the dir.
- Patches fail at `-F0` on pure line shifts; regenerate by applying with fuzz in a scratch copy and re-diffing.
- Clones now at `~/Developer/references/{mattpocock-skills,addyosmani-agent-skills,cursor-plugins (sparse pstack/)}`.

# Session Handoff — 26 (2026-10-12): plan.sh `plans` verb; origin refresh; pushed

**Summary.** The queued mission is done. Backlog 2/142/5/0/6 (open: L85, L86). A concurrent session fixed L87 (`0ae0eb1`).

**What got done (on main, pushed at `84401dd`):**
- Merged origin: PR #65 (`482ec7b`, stray files in `nodes/` no longer break `plan.sh`). It had no backlog card, so this session filed **L88** as resolved.
- **L89**: `scripts/plan.sh plans` prints `status` for every work item's plans, one line each; `--json` too. It resolves no project (`--project` narrows to one item). A plan that fails to load gets an error row, then exit 1. Tests T22a–i went red (9) before the verb existed. Documented in `docs/plans.md` and the usage header.

**Verified:** test-plan 279/0; `run-checks.sh` 44/0/0. The push went `f0304c1..84401dd`. TEMPLATE_VERSION was already 2026-10-12, so no bump.

**Decision:** a new verb instead of `status --all`, because `status` reads one plan and has no item column (commit trailer).
