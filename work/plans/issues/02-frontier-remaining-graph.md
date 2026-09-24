# 02 — `plan.sh frontier`, `remaining`, `graph`

**What to build:** The three derived read verbs: `frontier` lists todo nodes whose blockers are all done or dropped, restricted to the lowest wave with unfinished nodes, each with kind and tier; `remaining` lists everything not done or dropped; `graph` prints the graph as text (DOT behind a flag is optional). Waiting-on-edges is computed, never stored.

**Blocked by:** 01

**Status:** done (2026-09-23, session 4)

**Spec:** S13, S14, S16

- [x] Frontier honours mixed done/dropped blockers and wave order (a later wave's unblocked node is not on the frontier)
- [x] An empty frontier with unfinished nodes exits 1 and says why (all blocked, or only later waves)
- [x] `--json` on all three; tests cover each rule against the fixture
