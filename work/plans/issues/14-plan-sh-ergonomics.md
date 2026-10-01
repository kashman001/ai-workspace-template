# 14 — plan.sh ergonomics from the dogfood

**What to build:** (a) `add --leaf <label>` implies `tier: auto` unless `--tier` is given. (b) Accept `--project=<item>` and `--plan=<id>`; on `unknown option --project x` name the fix. (c) `plan.sh check` flags a `check:` that starts with a relative path (`scripts/`, `./`) — checks run with cwd = the item directory. (d) `done` prints the check's output only on failure (tail), not the full stream. Source: findings s15 (leaf tier, cwd), s7/s8/s17 (project flag), s11 (relative check, output).

**Blocked by:** 13

**Status:** ready-for-agent

**Spec:** findings only

- [ ] One failing test per item (a)–(d), then passing
- [ ] `test-plan.sh` green; `docs/plans.md` updated for (a)–(c)
