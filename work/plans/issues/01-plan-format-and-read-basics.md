# 01 — Plan directory format, node parser, and `plan.sh new / show / status`

**What to build:** From a work item, `plan.sh new <slug>` creates `plans/NN-<slug>/` with a `plan.md` skeleton (frontmatter + hand-written sections + empty board markers); node files with flat YAML frontmatter and Goal / Acceptance / Log sections are parsed; `show <id>` and `status` answer in text and `--json` with the documented exit codes; project and plan resolution follow the settled order and refuse when ambiguous. Bash + jq only, tests under `scripts/tests/` with a fixture plan; `docs/plans.md` started with the format section.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

**Spec:** S1, S2, S3, S5, S9, S10, S11, S12, S14, S17, S22, S23, S24

- [ ] `plan.sh new` numbers the next plan and refuses when one is already open in the item
- [ ] `status` prints plan, open/closed, wave n of m, counts by status, sessions used; `--json` mirrors it
- [ ] Malformed frontmatter or an unknown status/kind/tier value is refused with exit 1 and a line naming the file
- [ ] Resolution: flag → registry binding → TF_SESSION_PROJECT → cwd → refuse; plan: flag → chain.plan → single open → refuse (read verbs fall back to latest)
- [ ] Fixture plan under `scripts/tests/fixtures/` mirrors the worked example in `concept.md`; test script passes
