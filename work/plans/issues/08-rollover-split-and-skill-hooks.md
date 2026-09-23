# 08 — Node split at rollover; conditional sync step in rollover, checkpoint, and the launcher template

**What to build:** `session-rollover` gains: if a plan is open, run sync first, and if the current node is unfinished at WARN, split it into a done part and a remainder node (same wave and edges, sessions carried) via `plan.sh add`/`done`; `checkpoint` and the `create-work-item` launcher template gain the one-line conditional sync step and the launcher markers.

**Blocked by:** 05, 07

**Status:** ready-for-agent

**Spec:** S29, S34

- [ ] Split procedure exercised once on the fixture and described with its exact verbs in the skill
- [ ] Launcher template scaffolds the Position/Frontier markers only when asked (plans stay opt-in)
- [ ] Both skills readable by any runtime; no Claude-only instruction
