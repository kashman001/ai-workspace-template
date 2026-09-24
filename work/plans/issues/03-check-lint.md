# 03 — `plan.sh check` — the plan lint

**What to build:** `check` reads every node file and `plan.md` and exits non-zero with one line per violation: a wave without exactly one reconcile node, a reconcile node not last in its wave, a check on a hitl node, a dangling or cross-plan blocked_by, a doing node with no session listed, a wave past its size limit (limit in plan frontmatter, workspace default), malformed frontmatter. Exit 0 and silence on a clean plan.

**Blocked by:** 01

**Status:** done

**Spec:** S15

- [x] One test per rule, each with a fixture variant that trips exactly that rule
- [x] Clean fixture passes; `--json` lists violations as objects
- [x] Rule list documented in `docs/plans.md`
